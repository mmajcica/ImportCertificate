[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation
try 
{
    Write-Output "Post"
}
finally
{
    Trace-VstsLeavingInvocation $MyInvocation
}
