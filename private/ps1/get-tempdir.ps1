function Get-TempDir {
    ## Windows and Linux only for now() 
    if ($IsWindows) {
        return $env:TEMP
    } 
    elseif ($IsLinux) {
        return "/tmp"
    }     
    elseif ($IsMacOS) {
        throw "Get-TempDir: Currently no support for MacOS"
    } 
    else {
        ## This should *NOT* happen!
        throw "Get-TempDir: Unknown OS"
    }
}
