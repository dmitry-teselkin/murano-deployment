trap {
    Log "Exception trapped:"
    Log ($_ -as 'string')
    $CanGo=0;
    exit
}

$CanGo=1;
$srcDir = $env:systemdrive + "\Murano";
$srcPacksPath = $srcDir + "\Files";
$srcScriptsPath = $srcDir + "\Scripts";
$agentDir = $srcDir + "\Agent";
$modulesDir = $srcDir + "\Modules";
$sysIntDir = ${env:ProgramFiles(x86)} + "\Sysinternals Suite";
#Logging levels: 0 - no output, 1 - screen only, 2 - screen and logfile
$LogLevel=2;
$logHorSeparator="---------------------------------------------------------------";
#$scriptLogFile = GetLogPath($MyInvocation);
$scriptLogFile = $srcScriptsPath + "\log.txt";


# Functions must be declared before their execution like in bash.
#
Function Show-Variable {
    param (
        [String[]] $Name
    )
    
    Log $logHorSeparator
    foreach ($VarName in $Name) {
        try {
            $Var = Get-Variable -Name $VarName
            $VarType = $Var.Value.GetType() -as 'string'
            $Value = $Var.Value -as 'string'
        }
        catch {
            $VarType = ''
            $Value = '<NOT FOUND>'
        }
        Log ('[{0}] {1} = {2}' -f $VarType, $VarName, $Value)
    }
    Log $logHorSeparator
}


# MSI Installer
function installmsi()
{
    param(
        $installPkgPath
    )
    try
    {
        Log "Installing $installPkgPath ...";
        Start-Process -FilePath msiexec -ArgumentList /i, $installPkgPath, /qn -Wait
    }
    catch
    {
        $except= $_ | fl * -Force;
        Log "Installation of  $installPkgPath FAILS with $except";
    }
}

# Unzip
function unzip()
{
    param(
    $srcPath, $dstPath
    )
        $shellApplication = New-Object -com shell.application;
        $zipPackage = $shellApplication.NameSpace($srcPath);
        $destinationFolder = $shellApplication.NameSpace($dstPath);
        try
        {
            Log "Extracting $srcPath to $dstPath ..."; 
            $destinationFolder.CopyHere($zipPackage.Items(),0x14);
            # 0x14 - force overwrite 
        }
        catch
        {
             $except= $_ | fl * -Force;
             Log "Extraction of $srcPath to $dstPath FAILS with $except";
        }
}

# Unzip on core
function un-zip()
{
    param(
    $srcPath, $dstPath
    )
    try
    {
        Log "Unzipping $srcPath to $dstPath  ...";
		#$unzipper=$srcScriptsPath+"\unzip.exe";
		$unzipper="$srcPacksPath\unzip.exe";
        Start-Process -FilePath $unzipper -ArgumentList "-e `"$srcPath`" -d `"$dstPath`"" -Wait
    }
    catch
    {
        $except= $_ | fl * -Force;
        Log "Extraction of $srcPath to $dstPath FAILS with $except";
    }

}
# try run exe install
function runexeinstaller()
{
    param(
        $installer, $argList
    )
    try
    {
        Log "Running $installer ...";
        #Start-Process -FilePath $installer -ArgumentList /verysilent,/bash_context=1,/autocrlf=0,"/SetupType=custom /Components=icons,ext,ext\cheetah,assoc,assoc_sh" -Wait
		Start-Process -FilePath $installer -ArgumentList "$argList" -Wait
    }
    catch
    {
        $except= $_ | fl * -Force;
        Log "Installation of  $installer FAILS with $except";
    }
}

# Create dirs
function CreateDir()
{
    param(
        $path
    )
    Log "Creating $path";
    if(Test-Path $path)
    {
        Log "$path already exists, nothing todo";
    }
    else
    {
        New-Item -Path $path -ItemType Container| Out-Null;
        if(!(Test-Path $path))
        {
            Log "Can not create $path, exiting...";
            exit;
        }
    }     
}

# Log function
function Log()
{
    param(
        $msg
    )
    $datestamp = Get-Date -Format yyyyMMdd-HHmmss;
    $logString = "$datestamp`t$msg";
    if($LogLevel -ge 1)
    { 
        Write-Host "LOG:> $logString";
    }
    if($LogLevel -eq 2)
    {
        Add-Content $scriptLogFile "`n$logString" -ErrorAction 'SilentlyContinue'
    }
}

# Updating registry
function AddToEnvPath()
{
	param (
		$addString
	)
    $oldPath=(Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path
    if ($oldPath | Select-String -SimpleMatch "$addString")
    { 
        Log "$addString already within PATH=`"$oldPath`"";
    }
    else
    {
	    $newPath=$oldPath+';'+$addString;
        Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH –Value $newPath
		Log "$addString was add to system PATH";
    }
}

# Determining log file path
function GetLogPath()
{
    param (
        $Invocation
    )
    $fullPathIncFileName = $Invocation.MyCommand.Definition;
    $currentScriptName = $Invocation.MyCommand.Name;
    $retVal = $fullPathIncFileName.Replace($currentScriptName, "log.txt");
    return $retVal;
}

Show-Variable srcDir, srcPacksPath, srcScriptsPath, agentDir, modulesDir, sysIntDir, scriptLogFile, LogLevel

#Main sequence
Log "Creating directories...";
CreateDir $agentDir;
CreateDir $modulesDir;
CreateDir $sysIntDir;
CreateDir $sysIntDir;
Log $logHorSeparator;
Log "Installing packages...";
# Installing packages from Files directory
$srcFiles = Get-ChildItem -Path $srcPacksPath;
foreach($file in $srcFiles)
{
    if($file.Attributes -ne "Directory")
    {
        switch($file.Extension)
        {
            ".msi"
            {
                installmsi $file.FullName;
            }
            ".zip"
            {
                switch($file.Name)
                {
                    "MuranoAgent.zip"
                    {
                        un-zip $file.FullName $agentDir;
						Start-Sleep -s 5;
						& "$agentDir\WindowsAgent.exe" /install
                    }
                    "CoreFunctions.zip"
                    {
                        un-zip $file.FullName $modulesDir;
						Start-Sleep -s 5
                        Import-Module "$modulesDir\CoreFunctions\CoreFunctions.psm1" -ArgumentList register;
                    }
                    "SysinternalsSuite.zip"
                    {
                        un-zip $file.FullName $sysIntDir
                    }
                }
            }
            ".exe"
            {
                switch($file.Name)
                {
                    "msysgit-1.8.3.exe"
                    {
                        $gitInstDir="$ENV:ProgramData\git";
			runexeinstaller $file.FullName "/verysilent /setuptype=custom /components=icons,ext,ext\cheetah,assoc,assoc_sh /bash_context=1 /autocrlf=0 /dir=$gitInstDir";
			Start-Sleep -s 5;
			AddToEnvPath "$gitInstDir\cmd";
                    }
                }
            }
        }     
    }    
}
Log $logHorSeparator;

Log "Updating userdata.py for cloudcabe-init";
& "xcopy.exe" "$srcPacksPath\userdata.py" "C:\Program Files (x86)\CLoudbase Solutions\Cloudbase-Init\Python27\Lib\site-packages\cloudbase_init-0.9.0-py2.7.egg\cloudbaseinit\plugins\windows\" /y
Log $logHorSeparator;

#Run sysprep and Co.
if($CanGo -eq 1)
{
    Log "Changing LowRiskFileTypes list"
    & reg ADD "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\Associations" /f /v "LowRiskFileTypes" /t REG_SZ /d ".exe;.bat;.reg;.vbs;.ps1;"

#    Log "Enabling RDP access ..."
#    & reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /f /v "fDenyTSConnections" /t REG_DWORD /d 0
#    & reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /f /v "UserAuthentication" /t REG_DWORD /d 0
#    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

	Log "Starting of Sysprep processes ...";	
	Start-Process -FilePath powershell -ArgumentList "-File $srcScriptsPath\ws-2012-std\Start-Sysprep.ps1 -BatchExecution"; 
}

