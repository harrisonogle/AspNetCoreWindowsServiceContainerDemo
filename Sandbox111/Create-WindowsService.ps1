<#
.SYNOPSIS
  Creates and configures Windows Service in a Windows container.

.DESCRIPTION
  The script creates a new Windows user and configures the user account to be associated
  with an ASP.NET Core application running as a Windows Service.

.PARAMETER ServiceName
  The name of the service. This will also be the name of the Windows User.

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
    [string]$ServiceName
)

$ErrorActionPreference = "Stop"

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

Write-Host "Creating Windows user with name: '$ServiceName'"
$user = New-LocalUser -Name "$ServiceName" -NoPassword -AccountNeverExpires -FullName "$ServiceName" -Description "$ServiceName"
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

Write-Host "Adding `"logon as a service`" permission to user '$ServiceName'."
& ".\Add-ServiceLogonRight.ps1" -User "$ServiceName"
Write-Host "Added `"logon as a service`" permission to user '$ServiceName'."

# TODO: ACL the service executable, then call `New-Service` to create the Windows service.