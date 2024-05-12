$check_mk_folder = "C:\admin\backup_aomei\check_mk"

#Backup Disks
$backup_disks= @{
    BACKUP_DISK_01 = "X"
    BACKUP_DISK_02 = "Y"
}

#Status Files erzeugen
$status_files = @{
    bkp_status_lw_d = "d:#bkp\D"
    bkp_status_lw_b = "b:#bkp\B"
	bkp_status_desktop  = "C:\Users\Markus\Desktop#bkp\Desktop"
    bkp_status_dokumente  = "C:\Users\Markus\Documents#bkp\Documents"
    bkp_status_downloads = "C:\Users\Markus\downloads#bkp\downloads"
	bkp_status_music  = "C:\Users\Markus\Music#bkp\Music"
	bkp_status_pictures  = "C:\Users\Markus\Pictures#bkp\Pictures"
}


#Set current timestamp on source folders
foreach ($file in $status_files.Keys) {
    $p = $status_files[$file].Split("#")[0]
    #write-host $p
    echo $null > $p\$file
}

#Change Drive Letter for disks
foreach($v in Get-Volume) {

    #check if for each backup disk a check file exists on any volume
    foreach ($f in $backup_disks.Keys) {
        $dl=$v.DriveLetter
        $checkfile= -join($dl, ":\", $f)
        
        #if the check file is found on any volume ...
        if (Test-Path -Path $checkfile) {
           $correctdrive=$backup_disks[$f]
           #... check if te Drive-Letter of the volume is correct
           if ("$dl" -ne $correctdrive) {
               #Write-Host $checkfile
               Set-Partition -DriveLetter $dl -NewDriveLetter $correctdrive
           }
        }
    }
}

function Copy-FileWithTimestamp {
[cmdletbinding()]
param(
    [Parameter(Mandatory=$true,Position=0)][string]$Path,
    [Parameter(Mandatory=$true,Position=1)][string]$Destination
)

    $origLastWriteTime = ( Get-ChildItem $Path ).LastWriteTime
    Copy-Item -Path $Path -Destination $Destination
    (Get-ChildItem $Destination).LastWriteTime = $origLastWriteTime
}

# Status-Files von Backupfestplatte in Check_mk Ordner verschieben
foreach ($file in $status_files.Keys) {
    $p = $status_files[$file].Split("#")[1]

    foreach ($f in $backup_disks.Keys) {
        $l = $backup_disks[$f]
        $status_file_bkp = -join ($l, ":\", $p, "\", $file)
        #Write-Host  $status_file_bkp

        if (Test-Path -Path $status_file_bkp) {
            #Move-item -Path 'C:\Temp\bar2' -destination 'C:\Temp\bar' -force
            $dst = -join($check_mk_folder, "\", $file, "_disk_", $f)
           # Write-Host $dst
            Copy-FileWithTimestamp $status_file_bkp $dst
        }
        
    }
}


