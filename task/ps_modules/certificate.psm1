function New-TemporaryFolder
{
    [CmdletBinding()]
    param
    (
        [System.Management.Automation.Runspaces.PSSession]$Session
    )
    BEGIN { }
    PROCESS
    {
        $createTempFolder = {
            $parent = [System.IO.Path]::GetTempPath()
            $name = [System.IO.Path]::GetRandomFileName()

            $dirPath = Join-Path $parent $name
            $folder =  New-Item -ItemType Directory -Path $dirPath

            return $folder.FullName
        }

        if ($Session)
        {
            $tempFolder = Invoke-Command -ScriptBlock $createTempFolder -Session $Session
        }
        else
        {
            $tempFolder = Invoke-Command -ScriptBlock $createTempFolder
        }

        return $tempFolder
    }
    END { }
}

function Test-PfxCertificate
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)][string]$Thumbprint,        
        [System.Management.Automation.Runspaces.PSSession]$Session
    )
    BEGIN { }
    PROCESS
    {
        $checkCertExsists = {
            param
            (
                [string]$Thumbprint
            )
    
            $certs = Get-ChildItem -Path cert: -Recurse
    
            foreach ($cer in $certs)
            {
                if ($cer.Thumbprint -eq $Thumbprint)
                {
                    return $true
                    
                }
            }
    
            return $false
        }    

        if ($Session)
        {
            $tempFolder = Invoke-Command -Session $session -ScriptBlock $checkCertExsists -ArgumentList $Thumbprint
        }
        else
        {
            $tempFolder = Invoke-Command -ScriptBlock $checkCertExsists -ArgumentList $Thumbprint
        }

        return $tempFolder
    }
    END { }
}

function Get-CertificateStorePath {
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('CurrentUser', 'LocalMachine')]
        [System.String]
        $Location,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Store
    )

    return 'Cert:' |
        Join-Path -ChildPath $Location |
        Join-Path -ChildPath $Store
}

function Install-RemotePfxCertificate
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)][string]$FilePath,
        [SecureString]$Password,
        [Parameter(Mandatory = $true)][string]$Store,
        [bool]$Exportable,
        [switch]$CleanUp,
        [System.Management.Automation.Runspaces.PSSession]$Session
    )
    BEGIN { }
    PROCESS
    {
        $installPfx = {
            param
            (
                [string]$FilePath,
                [SecureString]$Password,
                [string]$Store,               
                [bool]$Exportable,
                [switch]$CleanUp
            )
    
            $certificateStore = Get-CertificateStorePath -Location "LocalMachine" -Store $Store

            Import-PfxCertificate -FilePath $FilePath -CertStoreLocation $certificateStore -Password $Password -Exportable:$Exportable

            if ($CleanUp)
            {
                Remove-Item -LiteralPath $FilePath -Force
            }
        }    

        if ($Session)
        {
            $tempFolder = Invoke-Command -Session $Session -ScriptBlock $installPfx -ArgumentList @($FilePath, $Password, $Store, $Exportable, $CleanUp)
        }
        else
        {
            $tempFolder = Invoke-Command -ScriptBlock $installPfx -ArgumentList @($FilePath, $Password, $Store, $Exportable, $CleanUp)
        }

        return $tempFolder
    }
    END { }
}