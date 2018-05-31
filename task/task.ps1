[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation
try 
{
    Import-Module -Name $PSScriptRoot\ps_modules\certificate.psm1

    $importSource = Get-VstsInput -Name importSource -Require
    $pfxPassword = Get-VstsInput -Name pfxPassword
    $store = Get-VstsInput -Name store -Require
    $exportable = Get-VstsInput -Name exportable -AsBool
    $useSsl = Get-VstsInput -Name useSsl -AsBool    
    $testCertificate = Get-VstsInput -Name TestCertificate -AsBool

    if ($importSource -eq "secureFile")
    {
        $secFileId = Get-VstsInput -Name secureFile -Require
        $secTicket = Get-VstsSecureFileTicket -Id $secFileId
        $secName = Get-VstsSecureFileName -Id $secFileId
        $tempDirectory = Get-VstsTaskVariable -Name "Agent.TempDirectory" -Require
        $collectionUrl = Get-VstsTaskVariable -Name "System.TeamFoundationCollectionUri" -Require
        $project = Get-VstsTaskVariable -Name "System.TeamProject" -Require

        $filePath = Join-Path $tempDirectory $secName
        $fileName = $secName

        Invoke-RestMethod -Uri "$collectionUrl/$project/_apis/distributedtask/securefiles/$($secFileId)?ticket=$($secTicket)&download=true" -UseDefaultCredentials -OutFile $filePath
    }
    else
    {
        $filePath = Get-VstsInput -Name certificatePath -Require
        $fileName = Split-Path -Path $filePath -Resolve -leaf
    }

    $cerArgs = ,$filePath
    
    if ($pfxPassword)
    {
        $cerArgs += $pfxPassword
    }

    $certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList $cerArgs

    $items = $machine -split ":"
            
    if ($items.Count -gt 1)
    {
        $machineName = $items[0]
        $machinePort = $items[1]
    }
    else
    {
        $machineName = $items[0]
        $machinePort = 5985
    
        if ($useSsl)
        {
            $machinePort = 5986
        }
    }

    if ($useSsl -and $testCertificate)
    {
        $SessionOptions = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck
        $session = New-PSSession -ComputerName $fqdn -Credential $credential -UseSSL:$useSsl -Port $port -SessionOption $SessionOptions
    }
    else
    {
        $session = New-PSSession -ComputerName $fqdn -Credential $credential -UseSSL:$useSsl -Port $port
    }

    $certInstalled = Test-PfxCertificate -Thumbprint $certificate.Thumbprint -Session $session

    if ($certInstalled)
    {
        Write-Output "Certificate with thumbprint $($certificate.Thumbprint) already present on $machineName."
    }
    else
    {
        $tempFolder = New-TemporaryFolder -Session $session

        Copy-Item -Path $filePath -Destination $tempFolder -Force -ToSession $session -Verbose:$verbose

        $remoteFile = Join-Path $tempFolder $fileName
        $securePassword = ConvertTo-SecureString -String $pfxPassword -asPlainText -Force

        Install-RemotePfxCertificate -FilePath $remoteFile -Password $securePassword -Store $store -Exportable:$exportable -CleanUp
    }
}
finally
{
    if ($session -ne $null)
    { 
        $deleteRemoteCert = { param($file) if (Test-Path $folder -PathType Leaf) { Remove-Item $folder -Force } }
        
        Invoke-Command -ScriptBlock $deleteRemoteCert -ArgumentList $remoteFile -Session $session -Verbose:$verbose

        $session | Disconnect-PSSession | Remove-PSSession
    }

    Trace-VstsLeavingInvocation $MyInvocation
}
