@Echo off
CLS
MD C:\Media
SET SCRIPTFOLDER=%~dp0%
robocopy %SCRIPTFOLDER%Media C:\media *.* /e /s
CD C:\Media
rem .\starthere.cmd
