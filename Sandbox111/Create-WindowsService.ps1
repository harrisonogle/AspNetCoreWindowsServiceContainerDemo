<#
.SYNOPSIS
  Creates and configures Windows Service in a Windows container.

.DESCRIPTION
  The script creates a new Windows user and configures the user account to be associated
  with an ASP.NET Core application running as a Windows Service.

.PARAMETER ServiceName
  The name of the service. This will also be the name of the Windows User.

.PARAMETER ServicePath
  The path to the service executable.

.EXAMPLE
  .\Create-WindowsService.ps1 -ServiceName "RUALSv2"
  Creates and configures a Windows user account with the given service name.

.INPUTS
  None

.OUTPUTS
  None
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ServiceName,

    [Parameter(Mandatory=$true)]
    [string]$ServicePath
)

$ErrorActionPreference = "Stop"

Write-Host "ServiceName: '$ServiceName'"
Write-Host "ServicePath: '$ServicePath'"

if ([string]::IsNullOrEmpty($ServiceName))
{
    Write-Host "Null or empty 'ServiceName' parameter."
    exit 1
}

$serviceNameRegex = [regex]"^[A-Za-z][A-Za-z0-9_]*$"

if ($serviceNameRegex.IsMatch($ServiceName) -eq $false)
{
    Write-Host "Invalid 'ServiceName' parameter."
    exit 1
}

if ([string]::IsNullOrEmpty($ServicePath))
{
    Write-Host "Null or empty 'ServicePath' parameter."
    exit 1
}

if ([System.IO.File]::Exists($ServicePath) -ne $true)
{
    Write-Host "Service not found at: '$ServicePath'"
    exit 1
}

$serviceDirectory = [System.IO.Path]::GetDirectoryName($ServicePath)

if ([System.IO.Directory]::Exists($serviceDirectory) -ne $true)
{
    Write-Host "Service directory not found at: '$serviceDirectory'"
    exit 1
}

# Create the Windows user.
Write-Host "Creating Windows user with name: '$ServiceName'"
$password = ConvertTo-SecureString -String (-join ((33..126) | Get-Random -Count 32 | % {[char]$_})) -AsPlainText -Force
$user = New-LocalUser -Name "$ServiceName" -Password $password -AccountNeverExpires -FullName "$ServiceName" -Description "$ServiceName"
Write-Host "Created new user: $user"

Write-Host "Searching for user '$ServiceName'."
$found = net user "$ServiceName"

if ($LASTEXITCODE -ne 0)
{
    $exitCode = $LASTEXITCODE # formatting purposes
    Write-Host "Error finding user with name '$ServiceName'. (exit code: $exitCode)"
    exit 1
}
else
{
    Write-Host "Found user with name '$ServiceName'."
    [System.String]::Join("`n", $found) | Write-Host
}

# Give the user "logon as a service" permissions so it can do network stuff.
Write-Host "Adding `"logon as a service`" permission to user '$ServiceName'."
& ".\Add-ServiceLogonRight.ps1" "$ServiceName"
Write-Host "Added `"logon as a service`" permission to user '$ServiceName'."

# ACL the service executable to the file system.
Write-Host "ACL'ing the service executable to the file system."
$acl = Get-Acl "$ServicePath"
# $aclRuleArgs = "$ServiceName", "Read,Write,ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow"
$aclRuleArgs = "$ServiceName", "Read,Write,ReadAndExecute", "None", "None", "Allow"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($aclRuleArgs)
do
{
    $attempt = 0
    $check = 'ok'
    try
    {
        $acl.SetAccessRule($accessRule)
    }
    catch [System.Management.Automation.RuntimeException]
    {
        $_.Exception.Message
        $check = 'error'
        Start-Sleep -Seconds 2
        $attempt = $attempt + 1

        if ($attempt -ge 5)
        {
            Write-Host "Error setting filesystem ACL."
            Write-Host $_
            exit 1
        }
    }
} until (
    $check -eq 'ok'
)
# $acl.SetAccessRule($accessRule)
$acl | Set-Acl "$ServicePath"
Write-Host "ACL'ed the service executable to the file system."

# Create the Windows service.
Write-Host "Creating Windows service."
$serviceCredential = [System.Management.Automation.PSCredential]::new(".\$ServiceName", $password)
New-Service -Name "$ServiceName" -BinaryPathName "$ServicePath --contentRoot $serviceDirectory" -Credential $serviceCredential -Description "$ServiceName" -DisplayName "$ServiceName" -StartupType Manual
# New-Service -Name "$ServiceName" -BinaryPathName "$ServicePath --contentRoot $serviceDirectory" -Credential "$ServiceName" -Description "$ServiceName" -DisplayName "$ServiceName" -StartupType Automatic
Write-Host "Created Windows service."