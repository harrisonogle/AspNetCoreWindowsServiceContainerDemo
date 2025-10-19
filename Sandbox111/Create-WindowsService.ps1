<#
.SYNOPSIS
  Creates and configures Windows Service in a Windows container.

.DESCRIPTION
  The script creates a new Windows user and configures the user account to be associated
  with an ASP.NET Core application running as a Windows Service.

.PARAMETER Name
  The name of the service. This will also be the name of the Windows User.

.PARAMETER Path
  The path to the service executable.

.EXAMPLE
  .\Create-WindowsService.ps1 -Name "RUALSv2"
  Creates and configures a Windows user account with the given service name.

.INPUTS
  None

.OUTPUTS
  None
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Name,

    [Parameter(Mandatory=$true)]
    [string]$Path
)

$ErrorActionPreference = "Stop"

Write-Host "Name: '$Name'"
Write-Host "Path: '$Path'"

if ([string]::IsNullOrEmpty($Name))
{
    Write-Host "Null or empty 'Name' parameter."
    exit 1
}

$serviceNameRegex = [regex]"^[A-Za-z][A-Za-z0-9_]*$"

if ($serviceNameRegex.IsMatch($Name) -eq $false)
{
    Write-Host "Invalid 'Name' parameter."
    exit 1
}

if ([string]::IsNullOrEmpty($Path))
{
    Write-Host "Null or empty 'Path' parameter."
    exit 1
}

if ([System.IO.File]::Exists($Path) -ne $true)
{
    Write-Host "Service not found at: '$Path'"
    exit 1
}

$serviceDirectory = [System.IO.Path]::GetDirectoryName($Path)

if ([System.IO.Directory]::Exists($serviceDirectory) -ne $true)
{
    Write-Host "Service directory not found at: '$serviceDirectory'"
    exit 1
}

# Create the Windows user.
Write-Host "Creating Windows user with name: '$Name'"
$password = ConvertTo-SecureString -String (-join ((33..126) | Get-Random -Count 32 | % {[char]$_})) -AsPlainText -Force
$user = New-LocalUser -Name "$Name" -Password $password -AccountNeverExpires -FullName "$Name" -Description "$Name"
Write-Host "Created new user: $user"

Write-Host "Searching for user '$Name'."
$found = net user "$Name"

if ($LASTEXITCODE -ne 0)
{
    $exitCode = $LASTEXITCODE # formatting purposes
    Write-Host "Error finding user with name '$Name'. (exit code: $exitCode)"
    exit 1
}
else
{
    Write-Host "Found user with name '$Name'."
    [System.String]::Join("`n", $found) | Write-Host
}

# Give the user "logon as a service" permissions so it can do network stuff.
Write-Host "Adding `"logon as a service`" permission to user '$Name'."
& ".\Add-ServiceLogonRight.ps1" "$Name"
Write-Host "Added `"logon as a service`" permission to user '$Name'."

# ACL the service executable to the file system.
Write-Host "ACL'ing the service executable to the file system."
$acl = Get-Acl "$Path"
$aclRuleArgs = "$Name", "Read,Write,ReadAndExecute", "None", "None", "Allow"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($aclRuleArgs)
$acl.SetAccessRule($accessRule)
$acl | Set-Acl "$Path"
Write-Host "ACL'ed the service executable to the file system."

# Create the Windows service.
Write-Host "Creating Windows service."
$serviceCredential = [System.Management.Automation.PSCredential]::new(".\$Name", $password)
New-Service -Name "$Name" -BinaryPathName "$Path --contentRoot $serviceDirectory" -Credential $serviceCredential -Description "$Name" -DisplayName "$Name" -StartupType Manual
Write-Host "Created Windows service."