#
#

$compName = Read-Host -Prompt "Enter DHCP Sever name or address"

#This command dumps all DHCP Scopes, their options and leases
Export-DhcpServer -ComputerName $compName -File "dhcp_scopes.xml" -Leases

#This function reads in the created XML file, parses it, and outputs to csv
function ParseXML {
	[xml]$scopes = Get-Content "dhcp_scopes.xml"
	write-host $scopes.dhcpserver.ipv4.Scopes.Scope | format-table -autosize -property scopeid, optionvalue, lease
	}
	
ParseXML
