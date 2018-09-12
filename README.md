# SCCM-Deploy
This set of scripts will deploy System Center Current Branch as a Net New installation on a single server. 

You will need to check the Readme.txt in each appropriate subfolder and bring the contents in once.

Once done the scripts will launch the installation in the appropriate manner to do a completely unattended installation of Configuration Manager Current branch including installation of

Server Features
.Net Framework 2.0/3.5
Windows ADK
Microsoft MDT
SQL Server
Configuration Manager Current Branch

The script utilizes a utility written by Brian Wilhite to trap for any pending reboots before it starts to install.

Presently it will prompt for three questions

Three letter Site Code to assign to new Configuration Manager site
Site Description of a minimum of 10 characters
Credentials to be assigned to the SQL Server Service account (This account must already exist in Active Directory)

This script is meant to be a tool to assist installs *or* to spin up a Configuration Manager lab environment.  In a Lab scenario it should be possible to place this on a Domain Controller.  In a Production scenario this is *not* a Recommended configuration.

This has only been tested on Server 2016 with a Server 2016 DC and is not intended as a Production solution.  It is intended to give you all the automation pieces in PowerShell to allow you to automate what you NEED out of an SCCM install.
