function Get-TempDir {
    ## Windows and Linux only for now() 
    if ($IsWindows) {
        return $env:TEMP
    } 
    elseif ($IsLinux) {
        return "/tmp"
    }     
    elseif ($IsMacOS) {
        return "${Env:TMPDIR}"
    } 
    else {
        ## This should *NOT* happen!
        throw "Get-TempDir: Unknown OS"
    }
}
