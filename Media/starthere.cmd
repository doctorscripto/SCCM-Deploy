@Echo off
cls
Echo Ok then let's release the Kraken!
SET SCRIPTFOLDER=%~dp0%
powershell.exe -executionpolicy Bypass -file %SCRIPTFOLDER%ConfigMan-Deploy.ps1
