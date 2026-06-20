function Get-TempDir {
    if ($IsWindows) {
        return $env:TEMP
    } 
    elseif ($IsLinux) {
        return "/tmp"
    }     
    elseif ($IsMacOS) {
        return $env:TMPDIR
    } 
    else {
        ## This should *NOT* happen!
        throw "Get-TempDir: Unknown OS"
    }
}
