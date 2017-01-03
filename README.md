# ACAS-Automated-Scanning
This tool was created to fufill the requirements of,

**DISA STIG H40220-V-14569-(U//FOUO)** The account used for vulnerability scanning on the ePO server must meet creation and deletion requirements.

This particular STIG is relating to the McAfee HBSS platform and specifically this tool is created to work with McAfee ePolicy Orchestrator 5.3.1 running on Windows Server 2012 R2.

This script automates the following,

1. Creation of a local administrative account with a temporary random 13 character password.
2. Updating of a credential stored on a remote ACAS (Teneable Security Center) to match with the temporary local admin account.
3. Initiation of a scan on the remote ACAS (Teneable Security Center) of the HBSS ePO 5.3.1 Server.
4. Deletion of the temporary local administrative account.

Simply follow the below integration guide to deploy the script on your network. This script works best on fresh installs of the pre-configured DISA HBSS image but should work on any system that has Powershell V4 and Windows Server 2012 R2.

## Configuration Guide

1.Modify the following line #32 and add whatever local adminstrative account name you would like between the ''.

```powershell
$Username = 'ACASScanner'
```
2.Modify the following line #96 by adding whatever your credential number is (to get a credential number create a new credential by clicking on scans, credentials, add, and the click on your credential and it will be the 7 digit number at the end of the url when viewing the new credential)

```
