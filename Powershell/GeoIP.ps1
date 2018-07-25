#requires -Version 3

$choice = Read-Host -Prompt "Do you want to lookup a list of IP addresses, or a single IP? (list|single)"

if ($choice -eq "list") {
	$IPAddress = Get-Content "ipaddresses.txt"
	}
elseif ($choice -eq "single") {
	$IPAddress = Read-Host -Prompt "Enter the IP you wish to lookup"
	}
else {
	Write-Host "Please enter either list or single. Exiting."
	}
	
$results = @()

foreach ($ip in $IPAddress) {
    $request = Invoke-RestMethod -Method Get -Uri "http://geoip.nekudo.com/api/$ip"
 
	[PSCustomObject]@{
					IP        = $request.IP
					City      = $request.City
					Country   = $request.Country.Name
					Code      = $request.Country.Code
				}

	$results += $request
	$results | Export-CSV -Path 'GeoIP-Results.csv' -NoTypeInformation -Append
} 


