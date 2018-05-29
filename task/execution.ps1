[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation
try 
{
    $secFileId = Get-VstsInput -Name secureFile -Require

    Write-Output "Sec File Id: $secFileId"

    $secTicket = Get-VstsSecureFileTicket -Id $secFileId
    $secName = Get-VstsSecureFileName -Id $secFileId

    Write-Output $secName
    
    $dir = Get-VstsTaskVariable -Name BUILD_ARTIFACTSTAGINGDIRECTORY

    $fileName = Join-Path $dir $secName

    Write-Output "File is going to be saved in $dir"
    Write-Output "File path is $fileName"

    $collectionUrl = Get-VstsTaskVariable -Name System.TeamFoundationCollectionUri -Require
    $project = Get-VstsTaskVariable -Name System.TeamProject -Require

    $uri = "$collectionUrl/$project/_apis/distributedtask/securefiles/$($secFileId)?ticket=$($secTicket)&download=true"

    Invoke-RestMethod -Uri $uri -UseDefaultCredentials -OutFile $fileName
}
finally
{
    Trace-VstsLeavingInvocation $MyInvocation
}
