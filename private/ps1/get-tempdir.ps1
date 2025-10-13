function Get-TempDir {
    ## Windows and Linux only for now() 
    if ($IsWindows) {
        return $env:TEMP
    } 
    elseif ($IsLinux) {
        return "/tmp"
    } 
    else {
        throw "Get-TempDir: Currently no support for Mac"
    }
}
