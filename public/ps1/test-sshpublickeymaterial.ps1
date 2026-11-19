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
