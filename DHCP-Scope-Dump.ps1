#
#

$compName = Read-Host -Prompt "Enter DHCP Sever name or address"

#This command dumps all DHCP Scopes, their options and leases
Export-DhcpServer -ComputerName $compName -File "dhcp_scopes.xml" -Leases
