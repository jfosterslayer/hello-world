# This script will throttle the number of concurrent jobs based on $maxjobs
$maxjobs = 8
$threads = 16

# Set $src to a directory with lots of sub-directories
$src = "S:\"

# Set $dest to a local folder or share you want to back up the data to
$dest = "G:\Data"

# Set $log to a local folder to store logfiles
$log = "C:\RoboCopyLogs\"

$tstart = get-date

if (!(Test-Path $log)) { mkdir $log }

$files = Get-ChildItem $src
$files | ForEach-Object {
    $ScriptBlock = {
        param($name, $src, $dest, $log, $threads)
        $srcpath = Join-Path $src $name
        $destpath = Join-Path $dest $name
        $log += "\$name-$(get-date -f yyyy-MM-dd-mm-ss).log"
        robocopy $srcpath $destpath /COPYALL /MIR /ZB /R:0 /W:0 /MT:$threads > $log
        Write-Host $srcpath " completed"
    }
    $j = Get-Job -State "Running"
    while ($j.count -ge $maxjobs) 
    {
        Start-Sleep -Milliseconds 500
        $j = Get-Job -State "Running"
    }
    Get-job -State "Completed" | Receive-job
    Remove-job -State "Completed"
    Start-Job $ScriptBlock -ArgumentList $_, $src, $dest, $log, $threads
}
#
# No more jobs to process. Wait for all of them to complete
#

While (Get-Job -State "Running") { Start-Sleep 2 }
Remove-Job -State "Completed" 
Get-Job | Write-host

$tend = get-date

new-timespan -start $tstart -end $tend