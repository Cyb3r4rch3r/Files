#Get current PC Info
#Import-Module grouppolicy

<# Functions in this script do the following:
Funtion Name		Description
GetInfo				Gathers information about the target device - OS Version, Physical/Logical Disks, Mapped Drives, Current User and Active Remote Sessions
Winlog				Checks for AutoLogin configuration
Printers			Checks for all installed printers both system wide and for the current logged in user
get-localadmins	        	Gets the full list of local admins on the target device
Hotfix				Gets all installed Hotfixes/Patches on the target system
RSOP				Gets Resultant Set of Policy on the currently logged in user
Redo				Restarts the script to check all functions against another target
#>

$compName = Read-Host -Prompt "Enter PC Name or IP Address"
$disks = Get-WmiObject -query "select * from Win32_LogicalDisk where DriveType='3'" -ComputerName $compName

function Redo{
		#Check another PC?
		function AllFunction{
			GetInfo
			Winlog
			Printers
			Hotfix
			Redo
			}
		$redo = Read-Host -Prompt "Would you like to lookup another computer? (Y/N)"
		if ($redo -eq "Y" -or $redo -eq "y"){
			do{
				$compName = Read-Host -Prompt "Enter PC Name or IP Address"
				AllFunction}
			until($redo -eq "N" -or $redo -eq "n")	
			}
		else{
			Exit}
		}

#Function to get Autologin information of specified PC
function Winlog{
	#Ask to check for autologin configuration
	$autolog = Read-Host -Prompt "Would you like to check for Autologon configuration? (Y/N)"
	if ($autolog -eq "Y" -or $autolog -eq "y"){
		$Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $compName)
		$RegKey= $Reg.OpenSubKey("SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon")
		$enabled = $RegKey.GetValue("AutoAdminLogon")
		$name = $RegKey.GetValue("DefaultUserName")
		$pass = $RegKey.GetValue("DefaultPassword")
		$domain = $RegKey.GetValue("DefaultDomainName")
		##Check to see if Autologon is enabled
		if ($enabled -eq "1"){
				$ans = "Yes"}
		else{
				$ans = "No"}

		write-host "Autologin Enabled: $ans" 
		##Get information
		if ($ans -eq "Yes"){
				write-host "Login Name: $name" 
				write-host "Login Password: $pass" 
				write-host "Login Domain: $domain"}
		else{
				write-host "$compName is not configured for Autologin."}
		}
	}
	
function Printers{	
		#Get List of Installed Printers
		$printers = read-host -prompt "Would you like to see installed printers? (Y/N)"
		if ($printers -eq "Y" -or $printers -eq "y"){
			Get-WMIObject Win32_Printer -ComputerName $compName | select name
			NetPrint}
	}

Function NetPrint{
	$currentusersid = Get-WmiObject -ComputerName $compName -Class win32_computersystem |
	Select-Object -ExpandProperty Username |
	ForEach-Object { ([System.Security.Principal.NTAccount]$_).Translate([System.Security.Principal.SecurityIdentifier]).Value }
	$netPrint = REG QUERY "\\$compName\HKU\$currentusersid\Printers\Connections"
	$np = $netPrint | Out-String
	$pos = $np.IndexOf(",,")
	$NPrinters = $np.Substring($pos+1)
	Write-Host "Installed Network Printers `r`n"
	ForEach ($print in $NPrinters){
	Write-Host "$print"}
	}
	
#Test connection to specified PC and get PC info.
if (test-Connection -Cn $compName -quiet) {
	function GetInfo {
		Get-WmiObject -Class Win32_ComputerSystem -ComputerName $compName
		
		#Get OS Version
		Get-WMIObject -Class Win32_OperatingSystem -ComputerName $compName | select Description
		Get-WMIObject -Class Win32_OperatingSystem -ComputerName $compName | select Caption
		Get-WMIObject -Class Win32_OperatingSystem -ComputerName $compName | select OSArchitecture
		Get-WMIObject -Class Win32_OperatingSystem -ComputerName $compName | select ServicePackMajorVersion
		$version = Reg Query "\\$compName\HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ReleaseId
		$verInfo = $version | out-string
		$pos = $verInfo | select-string -pattern '....'
		$verid = $pos -match '[0-9][0-9][0-9][0-9]'
		Write-Host "OS Version ID :" $matches[0]
		Write-Host " "
		
		
		#Get currently logged on user
        try{
		    $loggedinUser = Get-WmiObject -Class Win32_ComputerSystem -Property UserName -ComputerName $compName | select -ExpandProperty UserName
		    Write-Host "Username: $loggedinUser"
            Write-Host ""
       
            #Trim Domain from the returned username
            $loggedinUser = $loggedinUser.substring(3)
		
            #Query Active Directory for the Users Name property 
            $currentUser = get-aduser $loggedinuser | select -ExpandProperty name
            Write-Host "DisplayName: $($currentUser)"
            Write-Host ""
            Write-Host ""
            }
       catch {
            Write-Host "No Currently logged on user"
            Write-Host ""
            Write-Host ""
            }

        #Check for Remote Sessions
        Write-Host "Checking for Remote Sessions..."
        #Code in the try/catch below borrowed from https://gallery.technet.microsoft.com/scriptcenter/Get-LoggedOnUser-Gathers-7cbe93ea - All credit to Jaap Brasser
            try {
            quser /server:$compName 2>&1 | Select-Object -Skip 1 | ForEach-Object {
                $CurrentLine = $_.Trim() -Replace '\s+',' ' -Split '\s'
                $HashProps = @{
                    UserName = $CurrentLine[0]
                    ComputerName = $compName
                }

                # If session is disconnected different fields will be selected
                if ($CurrentLine[2] -eq 'Disc') {
                        $HashProps.SessionName = $null
                        $HashProps.Id = $CurrentLine[1]
                        $HashProps.State = $CurrentLine[2]
                        $HashProps.IdleTime = $CurrentLine[3]
                        $HashProps.LogonTime = $CurrentLine[4..6] -join ' '
                        $HashProps.LogonTime = $CurrentLine[4..($CurrentLine.GetUpperBound(0))] -join ' '
                } else {
                        $HashProps.SessionName = $CurrentLine[1]
                        $HashProps.Id = $CurrentLine[2]
                        $HashProps.State = $CurrentLine[3]
                        $HashProps.IdleTime = $CurrentLine[4]
                        $HashProps.LogonTime = $CurrentLine[5..($CurrentLine.GetUpperBound(0))] -join ' '
                }

                New-Object -TypeName PSCustomObject -Property $HashProps |
                Select-Object -Property UserName,ComputerName,SessionName,Id,State,IdleTime,LogonTime,Error
            }
        } catch {
            New-Object -TypeName PSCustomObject -Property @{
                ComputerName = $compName
                Error = $_.Exception.Message
            } | Select-Object -Property UserName,ComputerName,SessionName,Id,State,IdleTime,LogonTime,Error
        }


		$colItems = Get-WmiObject -class "Win32_NetworkAdapterConfiguration" -computername $compName | Where {$_.IPEnabled -Match "True"}
			foreach ($objItem in $colItems) {
				#Clear-Host
				Write-Host "MAC Address: " $objItem.MACAddress
				Write-Host "IPAddress: " $objItem.IPAddress
				Write-Host "IPEnabled: " $objItem.IPEnabled
				Write-Host "DNS Servers: " $objItem.DNSServerSearchOrder
				Write-Host "DNS Suffixes:" $objItem.DNSDomainSuffixSearchOrder
				Write-Host ""
			}
		#Get disk information
		foreach ($disk in $disks)
			{
			$diskname = $disk.caption
			"$compName $diskname drive has {0:#.0}GB free of {1:#.0}GB Total Disk Space " -f ($disk.FreeSpace/1GB),($disk.Size/1GB) | write-output 
			}
			#Get mapped drives and user they're mapped to
			function MappedDrive{
				gwmi win32_mappedlogicaldisk -ComputerName $compName | select SystemName,Name,ProviderName,SessionID | foreach { 
				$mapdisk = $_
				$user = gwmi Win32_LoggedOnUser -ComputerName $compName | where { ($_.Dependent.split("=")[-1] -replace '"') -eq $mapdisk.SessionID} | foreach {$_.Antecedent.split("=")[-1] -replace '"'}
				$mapdisk | select Name,ProviderName,@{n="MappedTo";e={$user} }
				}
			}

MappedDrive
			
	}
	
#Get List of Installed HotFixes for Machine
function Hotfix{
		$hfix = read-host -prompt "Would you like to check for installed Hotfixes? (Y/N)"
		if ($hfix -eq "Y" -or $hfix -eq "y"){
		Get-WmiObject -Class Win32_QuickFixEngineering -ComputerName $compName}
		}

function RSOP{
		$rsop = read-host -prompt "Would you like to run a Resultant Set of Policy for the loggedin user? (Y/N)"
		if ($rsop -eq "Y" -or $rsop -eq "y"){
		Get-GPResultantSetOfPolicy -ReportType Html -Path $psscriptroot\RSOP\$compName-rsop.html}
		}		
		
function get-localadmins{
  $localAdmin = Read-Host -Prompt "Would you like to see all local admins on the machine? (Y/N)"
  if ($localAdmin -eq "Y" -or $localAdmin -eq "y"){
	  $group = get-wmiobject win32_group -ComputerName $compName -Filter "LocalAccount=True AND SID='S-1-5-32-544'"
	  $query = "GroupComponent = `"Win32_Group.Domain='$($group.domain)'`,Name='$($group.name)'`""
	  $list = Get-WmiObject win32_groupuser -ComputerName $compName -Filter $query
	  $list | %{$_.PartComponent} | % {$_.substring($_.lastindexof("Domain=") + 7).replace("`",Name=`"","\")}
	}	
}

GetInfo
Winlog
Printers
get-localadmins
Hotfix
RSOP
Redo

}
else {
	Write-host "$compName is not online."
	Redo
}
