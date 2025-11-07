


Out-Host -InputObject "# START: Generic section"
Out-Host -InputObject "StrictHostKeyChecking no"
Out-Host -InputObject "UserKnownHostsFile=/dev/null"
Out-Host -InputObject "# END: Generic section"

ForEach ($target in $bastion_session_list) {

    $_targetHost = $target.Targethost
    $_targetPort = $target.TargetPort
    $_targetUser = $target.TargetUser

    Out-Host -InputObject "BEGIN: Host <n>"
    Out-Host -InputObject "Host <hostname>"
    Out-Host -InputObject "  Hostname ${_targetHost}"
    Out-Host -InputObject "  User ${_targetUser}"
    Out-Host -InputObject "  Port ${_targetPort}"
    Out-Host -InputObject "END: Host <n>"

}

>>

ForEach ($target in $bastion_session_list) {
    $_targetHost = ${target.TargetHost}
    $_targetPort = "${target.TargetPort}" 

    Write-Output "X: ${_targetHost} - ${_targetPort}"
    Write-Output "-"
}
