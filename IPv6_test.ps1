#Get IPv6 Enabled Status

$compName = Read-Host -Prompt "Enter Computer Name: "

function GetIPv6 {
	$IPV6 = $false
	$arrInterfaces = (Get-WmiObject -class Win32_NetworkAdapterConfiguration -ComputerName $compName -filter "ipenabled = TRUE").IPAddress

	foreach ($i in $arrInterfaces) {$IPV6 = $IPV6 -or $i.contains(":")}

	write-host $IPV6
	}
	
if (test-Connection -Cn $compName -quiet) {
	GetIPv6
	}

else {
	Write-host "$compName is not online."
	}
