<#
.SYNOPSIS
  Adds "Log on as a service" right to an existing Windows user.

.DESCRIPTION
  Configures an existing Windows user to have service logon permission.
  The "Log on as a service" user right allows accounts to start network services
  or services that run continuously on a computer, even when no one is logged
  on to the console.
  It allows certain users to run Windows network services whether they are logged
  on locally or not.

.PARAMETER User
  The name of the Windows user.

.EXAMPLE
  .\Add-ServiceLogonRight.ps1 -User "RUALSv2"
  Configures the Windows user to have service logon permission.

.INPUTS
  None

.OUTPUTS
  None
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [String]
    $UserOrGroup
)

Write-Host "Adding service logon permission to user or group '$UserOrGroup'."

try
{
    # Check if the user account exists.
    $null = ([System.Security.Principal.NTAccount]::new($UserOrGroup)).Translate([System.Security.Principal.SecurityIdentifier]).Value
}
catch
{
    # Exit the script if the user account does not exist.
    "The account [$UserOrGroup] does not exist." | Out-Default
    return $null
}

$tempConfigFile = "$env:TEMP\tempCfg.ini"
$tempDatabaseFile = "$env:TEMP\tempSdb.sdb"
$null = $(secedit /export /cfg $tempConfigFile)
$null = $(secedit /import /cfg $tempDatabaseFile /db $tempDatabaseFile)
$configIni = Get-Content $tempConfigFile
$originalString = ($configIni | Select-String "SeServiceLogonRight").ToString()
$replacementString = $originalString + ',' + $UserOrGroup
$configIni = $configIni.Replace($originalString, $replacementString)
$configIni | Out-File $tempConfigFile
secedit /configure /db $tempDatabaseFile /cfg $tempConfigFile /areas USER_RIGHTS

# Clean up
if (Test-Path $tempConfigFile)
{
    Remove-Item -Path $tempConfigFile -Force -Confirm:$false
}
if (Test-Path $tempDatabaseFile)
{
    Remove-Item -Path $tempDatabaseFile -Force -Confirm:$false
}