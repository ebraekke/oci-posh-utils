#Requires -Modules OCI.PSModules.Core
<#
.SYNOPSIS
    Launch an OCI compute node (Ubuntu 24.04) for the DB lab: control (ctl) or database (db) node.

.DESCRIPTION
    Battle-tested request assembly with the naming/input contract of Nov 15.
    Placement: single AD (az1), fault domain selectable 1..3 (set both in name and in the request).
    Boot source: SourceDetails (InstanceSourceViaImageDetails). The top-level imageId is deprecated —
    sending it alone yields 400 CannotParseRequest (proven by A/B test Nov 15).
    Metadata must be a real Dictionary[string,string]; user_data is base64 of UserDataFile content.
    Bastion plugin enabled at launch; InstanceOptions legacy-endpoint flags guard-set (tenancy
    requirement, Nov 13 finding). InstanceOptions naming drifted across SDK versions — hence reflection.

.PARAMETER Type
    Node role: 'ctl' or 'db'. Drives the name prefix.

.PARAMETER CompartmentId
    Compartment OCID (ocid1.compartment...).

.PARAMETER SubnetId
    Subnet OCID (ocid1.subnet...). Private subnet; bastion-only access.

.PARAMETER SshAuthorizedKey
    SSH public key MATERIAL (not a path).

.PARAMETER FaultDomain
    Fault domain 1..3. Default 3.

.PARAMETER AvailabilityDomain
    Fixed lab placement: single AD (surfaces as az1 in the name).

.PARAMETER Shape
    Default: VM.Standard.E5.Flex.

.PARAMETER Ocpus
    OCPUs for Flex shapes. Default 4.

.PARAMETER MemoryInGBs
    Memory (GB) for Flex shapes. Default 32.

.PARAMETER ImageId
    Pinned Ubuntu 24.04 image (2026-11-05 build, amd64, standard).
    Provenance: Get-OCIComputeImagesList -OperatingSystem Canonical -OperatingSystemVersion 24.04
    -SortBy TIMECREATED; newest non-Minimal non-aarch64 build.

.PARAMETER UserDataFile
    Optional cloud-init override. Defaults to the type-driven convention:
    userdata/<Type>.yml (relative to repo root). File must exist — fail fast, no bare nodes.

.PARAMETER OciProfile
    OCI config profile. Default 'DEFAULT'. (Renamed from $Profile to avoid shadowing $PROFILE.)

.PARAMETER ConfigFile
    OCI config file path. The PEM signing key lives there, never in repo.

.EXAMPLE
    ./Launch_Node.ps1 -Type db -CompartmentId ocid1.compartment... -SubnetId ocid1.subnet... `
        -SshAuthorizedKey (Get-Content ~/.ssh/lab.pub -Raw) -FaultDomain 3 -UserDataFile ./db-cloud-init.yml
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, HelpMessage = 'Node role: ctl or db')]
    [ValidateSet('ctl', 'db')]
    [string]$Type,

    [Parameter(Mandatory, HelpMessage = 'Compartment OCID')]
    [ValidatePattern('^ocid1\.compartment\.')]
    [string]$CompartmentId,

    [Parameter(Mandatory, HelpMessage = 'Subnet OCID (private, bastion-only access)')]
    [ValidatePattern('^ocid1\.subnet\.')]
    [string]$SubnetId,

    # SSH public key MATERIAL (not a path).
    [Parameter(Mandatory, HelpMessage = 'SSH public key material (not a path)')]
    [ValidateNotNullOrEmpty()]
    [string]$SshAuthorizedKey,

    [Parameter(HelpMessage = 'Fault domain 1..3 (3)')]
    [ValidateRange(1, 3)]
    [int]$FaultDomain = 3,

    [Parameter(HelpMessage = 'Fixed single AD, surfaces as az1 in the name')]
    [string]$AvailabilityDomain = 'wTjm:EU-FRANKFURT-1-AD-1',   # <-- keep your current value

    [Parameter(HelpMessage = 'Shape (VM.Standard.E5.Flex)')]
    [string]$Shape = 'VM.Standard.E5.Flex',
    [Parameter(HelpMessage = 'OCPUs (4)')]
    [double]$Ocpus = 4,
    [Parameter(HelpMessage = 'Memory in GB (32)')]
    [double]$MemoryInGBs = 32,

    [Parameter(HelpMessage = 'Pinned Ubuntu 24.04 image OCID')]
    [string]$ImageId = 'ocid1.image.oc1.eu-frankfurt-1.aaaaaaaaeekiht2vsggacys5dn4oejs2lhvmmlkbbnx5sn2jm3sbwzyjrkyq',

    [Parameter(HelpMessage = 'Cloud-init override; default userdata/<Type>.yml')]
    [string]$UserDataFile,

    [Parameter(HelpMessage = 'OCI config profile (DEFAULT)')]
    [string]$OciProfile = 'DEFAULT',
    [Parameter(HelpMessage = 'OCI config file path')]
    [string]$ConfigFile = "$HOME/.oci/config"
)

## Local guard: fail fast on wrong key material (same spirit as Test-OpuSshAvailable).
## Returns $true if the string looks like SSH PUBLIC key material.
function Test-SshPublicKeyMaterial {
    param (
        [Parameter(Mandatory = $true)]
        [string]$KeyMaterial
    )

    ## Private key content must never be passed here
    if ($KeyMaterial -match 'PRIVATE KEY') { return $false }

    ## Common public key types: ssh-rsa / ssh-ed25519 / ssh-dss / ecdsa-sha2-*
    if ($KeyMaterial -notmatch '^(ssh-(rsa|ed25519|dss)|ecdsa-sha2-\S+)\s') { return $false }

    ## All checks passed
    return $true
}

Write-Verbose "Launch_Node.ps1: begin"

try {
    ## START: generic section
    $UserErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Stop"

    Import-Module "${PSScriptRoot}/../oci-posh-utils.psd1"
    ## END: generic section

    ## Validate input before any work
    Test-OpuOcidString -OcidString $CompartmentId -IsOfType "compartment"
    Test-OpuOcidString -OcidString $SubnetId -IsOfType "subnet"
    if (-not (Test-SshPublicKeyMaterial -KeyMaterial $SshAuthorizedKey)) {
        throw "SshAuthorizedKey does not look like SSH PUBLIC key material (private key or wrong content)"
    }

    ## Resolve user data early — fail fast, before any assembly.
    ## Type-driven convention: userdata/<Type>.yml (repo root); -UserDataFile overrides.
    if (-not $UserDataFile) {
        $UserDataFile = "${PSScriptRoot}/../userdata/${Type}.yml"
    }
    $udPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($UserDataFile)
    if (-not (Test-Path -LiteralPath $udPath)) {
        throw "UserDataFile not found: $udPath (expected userdata/${Type}.yml by convention; add it or pass -UserDataFile)"
    }
    $udBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($udPath))

    ## --- Name: <type>-az1-fd<fd>-<yyyy-MM-dd-HHmmss>-<random 3-digit> ---
    $timestamp = Get-Date -Format 'yyyy-MM-dd-HHmmss'
    $suffix = Get-Random -Minimum 100 -Maximum 999
    $name = '{0}-az1-fd{1}-{2}-{3}' -f $Type, $FaultDomain, $timestamp, $suffix

    ## --- Request assembly (types from Oci.CoreService.Models) ---
    $vnic = New-Object -TypeName 'Oci.CoreService.Models.CreateVnicDetails'
    $vnic.SubnetId = $SubnetId
    $vnic.AssignPublicIp = $false          # bastion-only access, no public IP
    $vnic.AssignPrivateDnsRecord = $true   # private DNS record (part of Nov 13 proven recipe)

    ## Tenancy-level condition requires the legacy-endpoint flags (Nov 13 finding).
    ## Guard-set both: property naming drifted across SDK versions.
    $instanceOptions = New-Object -TypeName 'Oci.CoreService.Models.InstanceOptions'
    $instanceOptions.GetType().GetProperties() |
        Where-Object { $_.Name -like 'AreLegacy*' } |
        ForEach-Object { $instanceOptions."$($_.Name)" = $true }

    $shapeConfig = New-Object -TypeName 'Oci.CoreService.Models.LaunchInstanceShapeConfigDetails'
    $shapeConfig.Ocpus = $Ocpus
    $shapeConfig.MemoryInGBs = $MemoryInGBs

    ## Bastion plugin enabled at launch (proven working Nov 13).
    $pluginConfig = New-Object -TypeName 'Oci.CoreService.Models.InstanceAgentPluginConfigDetails'
    $pluginConfig.Name = 'Bastion'
    $pluginConfig.DesiredState = 'ENABLED'
    $agentConfig = New-Object -TypeName 'Oci.CoreService.Models.LaunchInstanceAgentConfigDetails'
    $agentConfig.IsMonitoringDisabled = $false
    $agentConfig.IsManagementDisabled = $false
    $agentConfig.PluginsConfig = @($pluginConfig)

    ## Metadata must be a REAL Dictionary[string,string] — a hashtable fails to coerce.
    $metadata = New-Object -TypeName 'System.Collections.Generic.Dictionary[string,string]'
    $metadata['ssh_authorized_keys'] = $SshAuthorizedKey
    $metadata['user_data'] = $udBase64

    ## Boot source: SourceDetails (InstanceSourceViaImageDetails), NOT the deprecated
    ## top-level ImageId — per OCI docs, deprecated imageId is only accepted when it
    ## matches sourceDetails; sending imageId alone can yield 400 CannotParseRequest.
    $source = New-Object -TypeName 'Oci.CoreService.Models.InstanceSourceViaImageDetails'
    $source.ImageId = $ImageId

    $launchDetails = New-Object -TypeName 'Oci.CoreService.Models.LaunchInstanceDetails'
    $launchDetails.AvailabilityDomain = $AvailabilityDomain
    $launchDetails.CompartmentId = $CompartmentId
    $launchDetails.DisplayName = $name
    $launchDetails.SourceDetails = $source
    $launchDetails.CreateVnicDetails = $vnic      # attach the VNIC — without this, subnetId is null
    $launchDetails.FaultDomain = "FAULT-DOMAIN-$FaultDomain"   # actual placement; name mirrors it
    $launchDetails.Shape = $Shape
    $launchDetails.ShapeConfig = $shapeConfig
    $launchDetails.Metadata = $metadata
    $launchDetails.AgentConfig = $agentConfig
    $launchDetails.InstanceOptions = $instanceOptions   # tenancy-required flags (Nov 13 recipe)

    ## Payload transparency (API-first: the JSON is the contract)
    Write-Verbose "Payload"
    Write-Verbose ($launchDetails | ConvertTo-Json -Depth 10)

    ## Launch
    Write-Host "Launching '${name}' (FAULT-DOMAIN-$FaultDomain, $Ocpus OCPU / $MemoryInGBs GB)..."
    try {
        $instance = New-OCIComputeInstance `
            -LaunchInstanceDetails $launchDetails `
            -Profile $OciProfile `
            -ConfigFile $ConfigFile
    }
    catch {
        throw "New-OCIComputeInstance: $_"
    }

    ## -WaitForStatus only binds to WorkRequest enums; -WaitForLifecycleState is unverified
    ## on Get-OCIComputeInstance (known to work on Get-OCIBastion) — poll for now.
    ## TODO: check (Get-Command Get-OCIComputeInstance).Parameters for waiter params
    $deadline = (Get-Date).AddMinutes(5)
    do {
        Start-Sleep -Seconds 5
        $instance = Get-OCIComputeInstance -InstanceId $instance.Id -Profile $OciProfile -ConfigFile $ConfigFile
        Write-Host "  $($instance.LifecycleState) ..."
    } while ($instance.LifecycleState -notin 'RUNNING', 'TERMINATING', 'TERMINATED' -and (Get-Date) -lt $deadline)

    if ($instance.LifecycleState -ne 'RUNNING') {
        throw "Launch did not reach RUNNING within 5 minutes (state: $($instance.LifecycleState))"
    }

    ## Done
    Write-Host "RUNNING: $name"
    $instance | Select-Object DisplayName, Id, LifecycleState, TimeCreated
    Write-Host "SSH user on Ubuntu nodes: ubuntu (via bastion)."
}
catch {
    ## What else can we do?
    throw "Launch_Node.ps1: $_"
}
finally {
    ## START: generic section

    ## To Maximize possible clean ups, continue on error
    $ErrorActionPreference = "Continue"

    ## Nothing persistent is created at script level — no temp files to remove here

    ## Done, restore settings
    $ErrorActionPreference = $UserErrorActionPreference
    ## END: generic section

    Write-Verbose "Launch_Node.ps1: end"
}