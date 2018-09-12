[cmdletbinding()]
param(
[parameter(Position=0,Mandatory=$True)]
[ValidateNotNullOrEmpty()]
[validateLength(3,3)]
[System.String]$SiteCode=(READ-HOST 'Please Enter New Site Code       '),

[parameter(Position=1,Mandatory=$True)]
[ValidateNotNullOrEmpty()]
[ValidateScript({$_.Length -gt 5})]
[System.String]$SiteDescription=(READ-HOST 'Please Enter New Site Description'),
    
[parameter(Position=2,Mandatory=$True)]
[ValidateNotNullOrEmpty()]
[System.Management.Automation.PSCredential]$Credential=(Get-Credential -Message 'Please Enter ID and Password for SQL Service Account'),

[parameter(Position=3,Mandatory=$False)]
[ValidateNotNullOrEmpty()]
[System.String]$ProductKeySCCM='EVAL'
)

. $PSScriptRoot\PendingReboot\Get-PendingReboot.ps1
$Status=Get-PendingReboot

if (($Status.RebootPending) -eq $True)
{
Write-Output 'Server has a reboot pending.   Please restart operating system and re-run deployment script from "StartHere.cmd".'
}
Else
{

Clear-Host
Write-Output 'Adding required features to Server'

Install-WindowsFeature -name Net-Framework-Features -source "$PSScriptRoot\DotNet3.5\sxs\"
Install-WindowsFeature -Name 'BITS'
Install-WindowsFeature -Name 'BITS-IIS-Ext'
Install-WindowsFeature -Name 'BITS-Compact-Server'
Install-WindowsFeature -Name 'RDC'
Install-WindowsFeature -Name 'Net-Framework-Features'
Install-WindowsFeature -Name 'WAS-Process-Model'
Install-WindowsFeature -Name 'WAS-Config-APIs'
Install-WindowsFeature -Name 'WAS-Net-Environment'
Install-WindowsFeature -Name 'Web-Server'
Install-WindowsFeature -Name 'Web-ISAPI-Filter'
Install-WindowsFeature -Name 'Web-Net-Ext'
Install-WindowsFeature -Name 'Web-Net-Ext45'
Install-WindowsFeature -Name 'Web-ASP-Net'
Install-WindowsFeature -Name 'Web-ASP-Net45'
Install-WindowsFeature -Name 'Web-ASP'
Install-WindowsFeature -Name 'Web-Windows-Auth'
Install-WindowsFeature -Name 'Web-Basic-Auth'
Install-WindowsFeature -Name 'Web-URL-Auth'
Install-WindowsFeature -Name 'Web-IP-Security'
Install-WindowsFeature -Name 'Web-Scripting-Tools'
Install-WindowsFeature -Name 'Web-Mgmt-Service'
Install-WindowsFeature -Name 'Web-Stat-Compression'
Install-WindowsFeature -Name 'Web-Dyn-Compression'
Install-WindowsFeature -Name 'Web-Metabase'
Install-WindowsFeature -Name 'Web-WMI'
Install-WindowsFeature -Name 'Web-HTTP-Redirect'
Install-WindowsFeature -Name 'Web-Log-Libraries'
Install-WindowsFeature -Name 'Web-HTTP-Tracing'
Install-WindowsFeature -Name 'UpdateServices-RSAT'
Install-WindowsFeature -Name 'UpdateServices-API'
Install-WindowsFeature -Name 'UpdateServices-UI'

Write-Output 'Now Installing Microsoft Deployment Toolkit'
Start-Process -FilePath Msiexec.exe -ArgumentList "/i $PSScriptRoot\mdt\MicrosoftDeploymentToolkit_x64.msi /q/n" -wait -WindowStyle Hidden

Write-Output 'Now Installing the Windows Automation Deployment Kit'
Start-Process -FilePath "$PSScriptRoot\ADK\adksetup.exe" -ArgumentList '/ceip off /norestart /features Optionid.DeploymentTools OptionId.WindowsPreinstallationEnvironment OptionID.UserStateMigrationTool /q' -wait -WindowStyle Hidden

Write-Output 'Now Installing Microsoft SQL Server - Wait about 30 minutes for install to complete'
Start-Process -FilePath "$PSScriptRoot\SQL\setup.exe" -ArgumentList "/configurationfile=$PSScriptRoot\SQL\ConfigurationFile.ini /IACCEPTSQLSERVERLICENSETERMS" -wait -WindowStyle Hidden

$UserName=$Credential.UserName
$Password=$Credential.getnetworkcredential().Password

$s=Get-CimInstance -ClassName win32_service -Filter 'Name="MSSQLSERVER"'
    
Write-Output 'Assigning Credentials to SQL Server Service'
Stop-Service -Force -NoWait -Name MSSQLSERVER

$s | Invoke-CimMethod -MethodName Change -Arguments @{StartName=$Username ;StartPassword=$Password}

Start-Sleep -Seconds 10

Start-Service -Name MSSQLSERVER

Remove-Variable Username
Remove-Variable Password

$FQDN=[system.net.dns]::GetHostByName("localhost").hostname

$ConfigMgrINI=@"
[Identification]
Action=InstallPrimarySite


[Options]
ProductID=$ConfigManProductKey
SiteCode=$SiteCode
SiteName=$SiteDescription
SMSInstallDir=C:\Program Files\Microsoft Configuration Manager
SDKServer=$FQDN
RoleCommunicationProtocol=HTTPorHTTPS
ClientsUsePKICertificate=0
PrerequisiteComp=1
PrerequisitePath=C:\Media\Downloads
ManagementPoint=$FQDN
ManagementPointProtocol=HTTP
DistributionPoint=$FQDN
DistributionPointProtocol=HTTP
DistributionPointInstallIIS=0
AdminConsole=1
JoinCEIP=0

[SABranchOptions]
SAActive=1
CurrentBranch=1

[SQLConfigOptions]
SQLServerName=$FQDN
DatabaseName=CM_$SiteCode
SQLSSBPort=4022

[CloudConnectorOptions]
CloudConnector=0
CloudConnectorServer=$FQDN
UseProxy=0
ProxyName=
ProxyPort=

"@

New-Item -ItemType File -Path 'C:\Media\SCCM\ConfigMgr.ini' -Force
Add-Content -Value $ConfigMgrINI -Path 'C:\Media\SCCM\ConfigMgr.ini'

Write-Output 'Now Installing System Center Configuration Manager Current Branch - Please wait approximately two hours for Install to complete'

# Change Service Account Credentials
Start-Process -FilePath C:\Media\SCCM\SMSSETUP\BIN\X64\setup.exe -ArgumentList '/script C:\Media\SCCM\ConfigMgr.ini' -wait -WindowStyle Hidden

Write-Output 'System Center Configuration Manager Current Branch is now installed'
Write-Output 'Please arrange for Post installation Configuration for the site'
}
