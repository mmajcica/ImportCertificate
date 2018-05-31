[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation
try 
{
    $importSource = Get-VstsInput -Name importSource -Require

    if ($importSource -eq "secureFile")
    {
        $secFileId = Get-VstsInput -Name secureFile
        $secName = Get-VstsSecureFileName -Id $secFileId
        $tempDirectory = Get-VstsTaskVariable -Name "Agent.TempDirectory"

        $filePath = Join-Path $tempDirectory $secName

        if (Test-Path $filePath -PathType Leaf)
        {
            Remove-Item -Path $filePath -Force

            Write-Output "Removed the certificate."
        }
    }
}
finally
{
    Trace-VstsLeavingInvocation $MyInvocation
}
