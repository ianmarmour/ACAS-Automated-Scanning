 #####################################
######## Certificate Ignore #########
#####################################

if ([System.Net.ServicePointManager]::CertificatePolicy.ToString() -ne 'IgnoreCerts')
{
    $Domain = [AppDomain]::CurrentDomain
    $DynAssembly = New-Object System.Reflection.AssemblyName('IgnoreCerts')
    $AssemblyBuilder = $Domain.DefineDynamicAssembly($DynAssembly, [System.Reflection.Emit.AssemblyBuilderAccess]::Run)
    $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule('IgnoreCerts', $false)
    $TypeBuilder = $ModuleBuilder.DefineType('IgnoreCerts', 'AutoLayout, AnsiClass, Class, Public, BeforeFieldInit', [System.Object], [System.Net.ICertificatePolicy])
    $TypeBuilder.DefineDefaultConstructor('PrivateScope, Public, HideBySig, SpecialName, RTSpecialName') | Out-Null
    $MethodInfo = [System.Net.ICertificatePolicy].GetMethod('CheckValidationResult')
    $MethodBuilder = $TypeBuilder.DefineMethod($MethodInfo.Name, 'PrivateScope, Public, Virtual, HideBySig, VtableLayoutMask', $MethodInfo.CallingConvention, $MethodInfo.ReturnType, ([Type[]] ($MethodInfo.GetParameters() | % {$_.ParameterType})))
    $ILGen = $MethodBuilder.GetILGenerator()
    $ILGen.Emit([Reflection.Emit.Opcodes]::Ldc_I4_1)
    $ILGen.Emit([Reflection.Emit.Opcodes]::Ret)
    $TypeBuilder.CreateType() | Out-Null

    # Disable SSL certificate validation
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object IgnoreCerts
}



#################################
########## Create User ##########
#################################

$Computername = $env:COMPUTERNAME
$ASDIComp = [ADSI]"WinNT://$Computername"
$Username = 'ACASScanner'

$NewUser = $ASDIComp.Create('User',$Username)

#Generate a random password with the system.web C# library
[Reflection.Assembly]::LoadWithPartialName("System.Web")
$Password = [System.Web.Security.Membership]::GeneratePassword(15,3)
write-host $Password

$SecurePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
$BSTR = [system.runtime.interopservices.marshal]::SecureStringToBSTR($SecurePassword)
$_password = [system.runtime.interopservices.marshal]::PtrToStringAuto($BSTR)

$NewUser.SetPassword(($_password))
$NewUser.SetInfo()

$NewUser.description = "Temporary account for acas scans."
$NewUser.SetInfo()

$group = [ADSI]"WinNT://$Computername/Administrators,group"
$group.Add("WinNT://$Computername/ACASScanner,user")


####################################
########### Run Scan ###############
####################################

#Main function that is used every time to connect to SC, requires a valid web session and security center token response from main code.
Function Connect ()
{
  param(
    [string] $method,
    [string] $resource,
    [hashtable] $data = @{}
  )
  #write-host $token

  $header = @{}
  $header.Add("X-SecurityCenter","$token")

  $url = $base + $resource
  
  if ($method -eq "Get"){
    $body = @{}
  } else {
    $body = ConvertTo-Json $data
  }
  
  $resp = Invoke-RestMethod -Uri $url -Method $method -Headers $header -Body $body -WebSession $myWebSession

  return $resp
}

#Updates the credential with a username of ACASScanners
Function CreateCredential()
{

  $Data = @{}
  $Data.Add("name","ACASScanners")
  $Data.Add("username", "$username")
  $Data.Add("type", "windows")
  $Data.Add("authType", "password")
  $Data.Add("password", "$Password")

  $resp = Connect "PATCH" "Your crendential URL is here" $Data

  $resp
}

#Starts a Scan
Function StartScan()
{
  $Data = @{}
  $resp = Connect "GET" "/scan" $Data
  return $resp
}

#Returns the current status of a scan.
Function ScanStatus($sid)
{
  write-host $s
  $resp = Connect "GET" "/scanResult/$sid"
  return $resp
}

#Base URL for your ACAS/SC
$base = "https://YOURACASSCIPORHOSTNAME/rest"
$token = ""

Write-Host "Login to ACAS"

#This section can be changed to whatever the login for ACAS to run the scans is
$data = @{"username" = "YOURACASSECURITYMANAGERACC"; "password" = "YOUACASUSERPASSWORD"}
$url = $base + "/token"
$body = ConvertTo-Json $data
$resp = Invoke-RestMethod -Uri $url -ContentType "application/json" -Method "POST" -Body $body -SessionVariable myWebSession
$token = $resp.response.token

#Creates a new credential or modifies the past one
Write-Host "Adding new Scan Credential"
$GetScans = CreateCredential

Write-Host "Starting ACAS Scan"
#undocumented api function to create scans
$StartScan = Connect "POST" "/scan/6/launch"
$idnumber = $StartScan.response.scanResult.id
$status = ScanStatus($idnumber)

#Waits for scan to complete checks every 30 seconds to see if the scan is in running/queued status.
do
{
   Start-Sleep -Seconds 30
   $status = ScanStatus($idnumber)
   write-host $status.reponse.status
}
while (($status.response.status -eq "Running") -or ($status.response.status -eq "Queued"))

#Remove Local admin user
$Computername = $env:COMPUTERNAME
$ASDIComp = [ADSI]"WinNT://$Computername"
$Username = 'ACASScanner'
$ASDIComp.Delete('User','ACASScanner')
