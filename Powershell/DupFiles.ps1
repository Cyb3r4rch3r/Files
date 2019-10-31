# I didn't write this orginally, but I've modified it slightly. Also, I can't remember where I got it from. 
# If someone finds it, please let me know so I can credit the author appropriately
function get-md5hash {[System.BitConverter]::ToString((new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider).ComputeHash([System.IO.File]::ReadAllBytes($args)))}


$searchpath = Read-Host -Prompt "Enter the path/directories to search"

$savepath = Read-Host -Prompt "Enter the directory to save the report to"

$saveFile = "\DupFiles.csv"

Get-ChildItem $searchpath -Recurse|`

?{!$_.psiscontainer}|`

Select-Object Name,Fullname,CreationTime,LastWriteTime,Length,@{Name="MD5";Expression={Get-md5hash $_.fullname}}|`

group MD5|?{$_.Count -gt 1}|%{$_.Group}|sort MD5|`

Export-Csv $savepath$saveFile -NoTypeInformation -Encoding "Unicode"
