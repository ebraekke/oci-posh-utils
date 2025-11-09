

$IsProd = $false
$HostBaseName = "db"
$TargetUser = "ubuntu"

$cnt = 0
ForEach ($target in $bastion_session_list) {

    $cnt++

    $_targetHost = $target.Targethost
    $_targetPort = $target.LocalPort
    $_targetUser = $TargetUser

    Out-Host -InputObject "#"
    Out-Host -InputObject "# ${HostBaseName} number ${cnt} - target ${_targetHost}"
    Out-Host -InputObject "Host ${HostBaseName}${cnt}"
    Out-Host -InputObject "  Hostname localhost"
    Out-Host -InputObject "  User ${_targetUser}"
    Out-Host -InputObject "  Port ${_targetPort}"
    Out-Host -InputObject "  ServerAliveInterval 120"
    Out-Host -InputObject "  ServerAliveCountMax 90"

    if ($false -eq $IsProd) {
        Out-Host -InputObject "  StrictHostKeyChecking no"
        if ($false -eq $IsWindows) {
            Out-Host -InputObject "  UserKnownHostsFile=/dev/null"
        }
        else {
            Out-Host -InputObject "  UserKnowHostFile=\\.\NUL"
        }
    }
}

# Save in file:
New-Item -Path <path of file> -Value (output-from-cmd) -ErrorAction Stop | Out-Null
