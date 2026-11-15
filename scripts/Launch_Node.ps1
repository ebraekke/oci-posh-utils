#Requires -Modules OCI.PSModules.Core
<#
.SYNOPSIS
    Launch an OCI compute node (Ubuntu 24.04) for the DB lab: control (ctl) or database (db) node.
    Minimal, known-good baseline: battle-tested request assembly + new naming/input contract.

.EXAMPLE
    ./Launch_Node.ps1 -Type db -CompartmentId ocid1.compartment... -SubnetId ocid1.subnet... `
        -SshAuthorizedKey (Get-Content ~/.ssh/lab.pub -Raw) -FaultDomain 3 -UserDataFile ./db-cloud-init.yml
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('ctl', 'db')]
    [string]$Type,

    [Parameter(Mandatory)]
    [ValidatePattern('^ocid1\.compartment\.')]
    [string]$CompartmentId,

    [Parameter(Mandatory)]
    [ValidatePattern('^ocid1\.subnet\.')]
    [string]$SubnetId,

    # SSH public key MATERIAL (not a path).
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$SshAuthorizedKey,

    [ValidateRange(1, 3)]
    [int]$FaultDomain = 3,

    # Fixed lab placement: single AD (surfaces as az1 in the name).
    [string]$AvailabilityDomain = 'wTjm:EU-FRANKFURT-1-AD-1',   # <-- keep your current value

    # Unchanged defaults: shape / compute / image.
    [string]$Shape = 'VM.Standard.E4.Flex',
    [double]$Ocpus = 2,
    [double]$MemoryInGBs = 16,

    # Public Canonical Ubuntu 24.04 image, pinned 2026-11-05 build (amd64, standard).
    # Provenance: Get-OCIComputeImagesList -OperatingSystem Canonical -OperatingSystemVersion 24.04
    #   -SortBy TIMECREATED; newest non-Minimal non-aarch64 build.
    [string]$ImageId = 'ocid1.image.oc1.eu-frankfurt-1.aaaaaaaaeekiht2vsggacys5dn4oejs2lhvmmlkbbnx5sn2jm3sbwzyjrkyq',

    # Optional cloud-init file. If omitted, no user_data is set.
    [string]$UserDataFile,

    # OCI auth (PEM signing key lives in the config file referenced here, never in repo).
    [string]$OciProfile = 'DEFAULT',
    [string]$ConfigFile = "$HOME/.oci/config"
)

$ErrorActionPreference = 'Stop'

# --- Name: <type>-az1-fd<fd>-<yyyy-MM-dd-HHmmss>-<random 3-digit> ---
$timestamp = Get-Date -Format 'yyyy-MM-dd-HHmmss'
$suffix = Get-Random -Minimum 100 -Maximum 999
$name = '{0}-az1-fd{1}-{2}-{3}' -f $Type, $FaultDomain, $timestamp, $suffix

# --- Request assembly (types from Oci.CoreService.Models) ---
$vnic = [Oci.CoreService.Models.CreateVnicDetails]::new()
$vnic.SubnetId = $SubnetId
$vnic.AssignPublicIp = $false          # bastion-only access, no public IP
$vnic.AssignPrivateDnsRecord = $true   # private DNS record (part of Nov 13 proven recipe)

# Tenancy-level condition requires the legacy-endpoint flags (Nov 13 finding).
# Guard-set both: property naming drifted across SDK versions.
$instanceOptions = [Oci.CoreService.Models.InstanceOptions]::new()
$instanceOptions.GetType().GetProperties() |
    Where-Object { $_.Name -like 'AreLegacy*' } |
    ForEach-Object { $instanceOptions."$($_.Name)" = $true }

$shapeConfig = [Oci.CoreService.Models.LaunchInstanceShapeConfigDetails]::new()
$shapeConfig.Ocpus = $Ocpus
$shapeConfig.MemoryInGBs = $MemoryInGBs

# Bastion plugin enabled at launch (proven working Nov 13).
$pluginConfig = [Oci.CoreService.Models.InstanceAgentPluginConfigDetails]::new()
$pluginConfig.Name = 'Bastion'
$pluginConfig.DesiredState = 'ENABLED'
$agentConfig = [Oci.CoreService.Models.LaunchInstanceAgentConfigDetails]::new()
$agentConfig.IsMonitoringDisabled = $false
$agentConfig.IsManagementDisabled = $false
$agentConfig.PluginsConfig = @($pluginConfig)

# Metadata must be a REAL Dictionary[string,string] — a hashtable fails to coerce.
$metadata = [System.Collections.Generic.Dictionary[string, string]]::new()
$metadata['ssh_authorized_keys'] = $SshAuthorizedKey
if ($UserDataFile) {
    $udPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($UserDataFile)
    if (-not (Test-Path -LiteralPath $udPath)) { throw "UserDataFile not found: $udPath" }
    $metadata['user_data'] = [Convert]::ToBase64String([IO.File]::ReadAllBytes($udPath))
}

# Boot source: SourceDetails (InstanceSourceViaImageDetails), NOT the deprecated
# top-level ImageId — per OCI docs, deprecated imageId is only accepted when it
# matches sourceDetails; sending imageId alone can yield 400 CannotParseRequest.
$source = [Oci.CoreService.Models.InstanceSourceViaImageDetails]::new()
$source.ImageId = $ImageId

$details = [Oci.CoreService.Models.LaunchInstanceDetails]::new()
$details.AvailabilityDomain = $AvailabilityDomain
$details.CompartmentId = $CompartmentId
$details.DisplayName = $name
### $details.SourceDetails = $source
$details.CreateVnicDetails = $vnic      # attach the VNIC — without this, subnetId is null
$details.FaultDomain = "FAULT-DOMAIN-$FaultDomain"   # actual placement; name mirrors it
$details.Shape = $Shape
$details.ShapeConfig = $shapeConfig
$details.Metadata = $metadata
$details.AgentConfig = $agentConfig
$details.InstanceOptions = $instanceOptions   # tenancy-required flags (Nov 13 recipe)

Write-Host "Launching '$name' (FAULT-DOMAIN-$FaultDomain, $Ocpus OCPU / $MemoryInGBs GB)..."
$instance = New-OCIComputeInstance `
    -LaunchInstanceDetails $details `
    -Profile $OciProfile `
    -ConfigFile $ConfigFile

# -WaitForStatus only binds to WorkRequest enums — poll instead.
$deadline = (Get-Date).AddMinutes(5)
do {
    Start-Sleep -Seconds 5
    $instance = Get-OCIComputeInstance -InstanceId $instance.Id -Profile $OciProfile -ConfigFile $ConfigFile
    Write-Host "  $($instance.LifecycleState) ..."
} while ($instance.LifecycleState -notin 'RUNNING', 'TERMINATING', 'TERMINATED' -and (Get-Date) -lt $deadline)

if ($instance.LifecycleState -ne 'RUNNING') {
    throw "Launch did not reach RUNNING within 5 minutes (state: $($instance.LifecycleState))."
}

Write-Host "RUNNING: $name"
$instance | Select-Object DisplayName, Id, LifecycleState, TimeCreated
Write-Host "SSH user on Ubuntu nodes: ubuntu (via bastion)."