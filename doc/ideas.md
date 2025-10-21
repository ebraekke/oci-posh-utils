
### Clone in OCI CloudShell 

```powershell
git clone --depth 1 git@github.com:ebraekke/oci-posh-utils.git
```

## Output from terraform 

```powershell
❯ terraform output -json ip_addresses
["10.0.1.249","10.0.1.197","10.0.1.171"]

## and 
$terraformOutputJson = terraform output -json  ip_addresses
$terraformList = $terraformOutputJson | ConvertFrom-Json

$terraformList
>>
10.0.1.249
10.0.1.197
10.0.1.171

foreach ($item in $terraformList) {
    Write-Host "Processing ${item}"
}
>>
Processing 10.0.1.249
Processing 10.0.1.197
Processing 10.0.1.171
```


## JSON input
```powershell
    # Script (MyScript.ps1)
    param (
        [string]$JsonData
    )

    $jsonObject = $JsonData | ConvertFrom-Json
    Write-Host "Name: $($jsonObject.Name)"
    Write-Host "Age: $($jsonObject.Age)"

```