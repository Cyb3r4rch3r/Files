<# This script runs a series of queries against all AD Objects in the environment and returns a format suitable for most NIST Assessment Standards.
   Exports information to CSV file for further data manipulation.
   Author: Cyb3r4rch3r
   Revision Date: 8/11/2020
   
   DISCLAIMER: I'm no Guru. Yes, I know it's basic and I don't care. It satisfied my needs and can help others.
#>


#Get all AD Users
Write-Host ""
Write-Host "Gathering users in AD. This will take a while..."
Write-Host "Go grab a coffee :)"
Write-Host ""

#Gather the commonly requested data
$Users = Get-aduser -filter * -pr givenname, surname, samaccountname, name, enabled, lockedout, accountExpires, accountexpirationdate, lastlogondate, passwordlastset, passwordexpired, passwordneverexpires, modified

#Get count of Users in the environment to use for progress bar
$count = $users.count

Write-Host "$($count) users in Active Directory. Processing the results..."

#Script variables
$filename = "AD-User_Report-Detailed_$(get-date -f yyy-MM-dd).csv"
$i=0

#Do the things...
while ($i -le $count) {

#Process the magic for each user
foreach ($user in $users){

    
#Define the items we want to gather
    $first = $user.givenname
    $last = $user.surname
    $account = $user.samaccountname
    $name = $user.name
    $enabled = $user.enabled
    $lockedout = $user.LockedOut
    $accountNeverExpires = $user.accountExpires
    $accountExpired = $user.accountexpirationdate
    $lastLogon = $user.lastlogondate
    $passwordExpiration = ($user.passwordlastset).AddDays(90)
    $passwordIsExpired = $user.passwordexpired
    $passwordNeverExpires = $user.passwordneverexpires
    $lastModified = $user.modified

#Create Password Status based on data returned from query
    $passwordStatus = $null

    if ($passwordNeverExpires -eq $true){
        $passwordStatus = "Password Never Expires"
        }
    elseif ($passwordIsExpired -eq $true){
        $passwordStatus = "Password is Expired"
        }
    else {
        $passwordStatus = "Password Expires on $($passwordExpiration)"
        }

#Create Account Expiration Status based on data returned from query
    $expirationStatus = $null

    $date = Get-date

    if ($accountNeverExpires -eq 9223372036854775807) {
        $expirationStatus = "Account never expires"
        }
    elseif (($accountNeverExpires -ne 9223372036854775807) -and ($accountExpired -lt $date)){
        $expirationStatus = "Account expired on $($accountExpired)"
        }
    else {
        $expirationStatus = "Account expires on $($accountExpired)"
        }

#Put everything into a nicely designed collection 
    $result = New-Object psobject
    $result | Add-Member -MemberType NoteProperty -name Name -Value $name -ErrorAction SilentlyContinue
    $result | Add-Member -MemberType NoteProperty -name Username -Value $account -ErrorAction SilentlyContinue
    $result | Add-Member -MemberType NoteProperty -name FirstName -Value $first -ErrorAction SilentlyContinue
    $result | Add-Member -MemberType NoteProperty -name LastName -Value $last -ErrorAction SilentlyContinue
    $result | Add-Member -MemberType NoteProperty -name EnabledStatus -Value $enabled -ErrorAction SilentlyContinue
    $result | Add-Member -MemberType NoteProperty -name ExpirationStatus -Value $expirationStatus -ErrorAction SilentlyContinue
    $result | Add-Member -MemberType NoteProperty -name LockedOut -Value $lockedout -ErrorAction SilentlyContinue
    $result | Add-Member -MemberType NoteProperty -name LastLogonDate -Value $lastlogon -ErrorAction SilentlyContinue
    $result | Add-Member -MemberType NoteProperty -name PasswordExpired -Value $passwordIsExpired -ErrorAction SilentlyContinue
    $result | Add-Member -MemberType NoteProperty -name PasswordStatus -Value $passwordStatus -ErrorAction SilentlyContinue
    $result | Add-Member -MemberType NoteProperty -name LastModifiedDate -Value $lastModified -ErrorAction SilentlyContinue

#Save data to CSV
    $result | Export-Csv $filename -NoTypeInformation -Append

#Increment counter and make a progress bar
    $i++
    Write-Progress -Activity "Processing Users" -Status "Now Processing User $i of $($count)" -PercentComplete ($i/$count*100)
        }
    }

#Return path of exported file
    Write-Host ""
    Write-Host "Report exported to $($PSSCriptRoot)\$($filename)"
    Write-Host ""
