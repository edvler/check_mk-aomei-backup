# https://github.com/edvler/check_mk-aomei-backup
# Matthias Maderer


$oneWeek = 604800 # sekunden
$oneDay = 86400 # sekunden

#Set Job limits
#default is used when Job Name is specified
$job_limit_age = @{
    "default" = $oneWeek #default is one month
}

#Open Aomei XML-Log
$aomei_logfile = "C:\ProgramData\AomeiBR\brlog.xml"
if (-not (Test-Path -Path $aomei_logfile)) {
    exit
}
[xml]$cn = Get-Content $aomei_logfile


#Filter jobs by time and status
$jobs = @{}
foreach ($logentry in $cn.BRLog.Log) {
    $t= $logentry.Task

    #Always add first entry of one job to the jobs array (also failed possible)
    if (-not ($t -in $jobs.Keys)) {
        $jobs[$t] = @{}
        $jobs[$t]["time"] = $logentry.Time
        $jobs[$t]["rc"] = $logentry.ResultCode
        $jobs[$t]["detail"] = $logentry.Detail
    }

    #Only add, if the job was successfull (return 0) and time is gerater as first log entry
    if ($jobs[$t]["time"] -lt $logentry.Time -and $jobs[$t]["rc"] -eq "0") {
        $jobs[$t]["time"] = $logentry.Time
        $jobs[$t]["rc"] = $logentry.ResultCode
        $jobs[$t]["detail"] = $logentry.Detail
    }  
}

#For each job found in log
foreach ($j in $jobs.Keys){
        #Get time limit from config array
        $age = $job_limit_age["default"]
        if ($j -in $job_limit_age.Keys) {
            $age = $job_limit_age[$j]
        }

        #Calcualte difference between now and backup-time-stamp
        $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
        $bkptime = $origin.AddSeconds($jobs[$j]["time"])

        $now = (Get-Date)
        $diff = New-TimeSpan -Start $bkptime -End $now 
        $t = [Math]::Round($diff.TotalSeconds,0)

        #if return code ne zero, set abnormal high difference
        if ($jobs[$j]["rc"] -ne 0) {
            $t = 9999999999999999999
        }

        $s = -join ('P "AOMEI_JOB_', $j, '" age=', $t , ";;", $age, " ", $jobs[$j]["detail"], "; ", $bkptime.ToString("dd/MM/yyyy HH:mm:ss"), "; Return Code: ", $jobs[$j]["rc"])
        Write-Output $s
        #P "My 1st dynamic service" count=40;30;50 Result is computed from two threshold values
        #P "My 2nd dynamic service" - Result is computed with no values
}
