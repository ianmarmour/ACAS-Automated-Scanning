# ACAS-Automated-Scanning
This tool was created to fufill the requirements of,

**DISA STIG H40220-V-14569-(U//FOUO)** The account used for vulnerability scanning on the ePO server must meet creation and deletion requirements.

This particular STIG is relating to the McAfee HBSS platform and specifically this tool is created to work with McAfee ePolicy Orchestrator 5.3.1 running on Windows Server 2012 R2. This script alone should be sufficient to comply with H40220-V-14569 as long as implementation is done correctly. The credentials are randomly generated and never left on the server so it shouldn't conflict with any other DISA STIGS.

This script automates the following,

1. Creation of a local administrative account with a temporary random 13 character password.
2. Updating of a credential stored on a remote ACAS (Teneable Security Center) to match with the temporary local admin account.
3. Initiation of a scan on the remote ACAS (Teneable Security Center) of the HBSS ePO 5.3.1 Server.
4. Deletion of the temporary local administrative account.

Simply follow the below integration guide to deploy the script on your network. This script works best on fresh installs of the pre-configured DISA HBSS image but should work on any system that has Powershell V4 and Windows Server 2012 R2.

## Configuration Guide

1.Modify the following line #32 and add whatever local adminstrative account name you would like between the ''.

```powershell
$Username = '{your username goes here}'
```
2.Modify the following line #96 by adding whatever your credential number is (to get a credential number create a new credential by clicking on scans, credentials, add, and the click on your credential and it will be the 7 digit number at the end of the url when viewing the new credential)

```$resp = Connect "PATCH" "/credential/{your credential number goes here}" $Data```

3.Modify the following line #118 by adding the IP address of your Security Center into the URL.

```$base = "https://{your security centers ip goes here}/rest"```

4.Modify the following line #124 by modifying the line to includ your security center manager account's user credentials.

```$data = @{"username" = "{your username goes here}"; "password" = "{your password goes here}"}```

5.Modify the following line #136 by adding your scan ID into the POST request (Create a new scan with a credential being defined as the credential that you created earlier, after this scan is created click on it and look at the URL for the scan ID number)

```$StartScan = Connect "POST" "/scan/{your scan id number goes here}/launch"```

6.Modify the following lines #152/#153, the username you want to add here is the one that you gave to your LOCAL Admin account on the HBSS ePO Server not on the ACAS Security Center.

```$Username = '{Your username goes here}'``` 

```$ASDIComp.Delete('User','{Your username goes here}'```


## Installation Guide

If you're on a STIGGED system please make the below modification to local group policy,

> ```Computer Configuration -> Windows Settings -> Security Settings -> Local Policies -> User Rights Assignments -> Log on as a batch job -> and add the local administrator that you will run this script as to this group policy```


Go to Windows Task Scheduler -> Create Task -> Set the following options


### General
Name = Whatever

Description = Whatever


Security Options

When running the task use the following user account = Your local administrator account.

Run whether user is logged on or not = true

Run with highest privileges = true


### Triggers

Click new then set the following settings,


Begin the task = On a schedule


Settings


Monthly = true


Start = Autofill

Months = Select all months


Days = Pick a day


Enabled = True


Click on the OK.

### Actions

Click new then set the following options,


Action = Start a program


Program/script = `powershell -file C:\{Your script location here}\ACAS-MonthlyScanTool.ps1`

### Settings

Allow task to be run on demand = true

Run task as soon as possible after a scheduled start is missed = true

Stop the task if it runs longer then = 2 hours.
