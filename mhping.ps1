<#
Multi Host Ping
Place this script on the system and put it in a scheduled task that runs as the user (system tasks often don't have network access)
You can also run it manually by double clicking the file.
Make sure to set the duration and the computer variables below.
Script writes a csv for each ping location you can then compare them side by side to see where the link was dropped (ISP, Server, etc)
After the task completes, the file is renamed to match the start date
In the case of the file being aborted the file is given the end date and prepended "recovery"

v0.1.3 Fixed the workflow inline stuff, all the variables should work now. Rename incomplete runs prepending recovered.
v0.1.2 Changed to start and stop times rather than loop counting which was inaccurate
v0.1.1 Changed to Military time
v0.1 Intial release: change $Computers and $ComputersScope to the same entries as needed.

#>
#Variables
#How long to run in minutes, you can configure this to produce near perfect ping coverage (1440 for a full day coverage)
$Duration = 1
#List of systems to ping
$Computers = "192.168.98.1","192.168.98.253","8.8.8.8"


#Debugging
#$DebugPreference = "Continue"
#Logging feature
#$ErrorActionPreference="SilentlyContinue"
try { Stop-Transcript | out-null } catch { }

#current script directory
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
#current script name
$path = Get-Location
$scriptName = $MyInvocation.MyCommand.Name
$scriptLog = "$scriptPath\log\$scriptName.log"
write-host $path
write-host $scriptPath

#start a transcript file
try { Start-Transcript -path $scriptLog } catch { }
try { New-Item -ItemType Directory -Path $scriptPath\results -Force } catch { }

#Setup time period
$TimeStart = Get-Date
$TimeEnd = $timeStart.addminutes($Duration)
Write-Host "Start Time: $TimeStart"
write-host "End Time:   $TimeEnd"

Write-Host "Testing the following addresses: "
foreach ($Computer in $Computers){
	Write-Host $Computer
}

#rename aborted files
$renameDate = get-date -format yyyy-MM-ddTHH-mm-ss-ff
Get-ChildItem $scriptPath\results -Filter "ping*.csv"
Get-ChildItem $scriptPath\results -Filter "ping*.csv" | Rename-Item -NewName {"Recovered_"+ $renameDate + $_.name}


workflow PingTest{
	Param (
        $Computers,
		$outPath
    )
    foreach -parallel ($Computer in $Computers){
#		Write-Host pinging $Computer
#        $Time = Get-Date -format "yyyy-MM-dd HH:mm:ss"
#        $TestResult = Test-Connection -ComputerName $Computer -Count 1 -ErrorAction SilentlyContinue
        inlinescript{
			#Write-Host inline Path $using:outPath
			#Write-Host inline Pinging $using:Computer
			$Time = Get-Date -format "yyyy-MM-dd HH:mm:ss"
			$TestResult = Test-Connection -ComputerName $using:Computer -Count 1 -ErrorAction SilentlyContinue
            if ($using:TestResult.ResponseTime -eq $null){
                $ResponseTime = -1
            } else {
                $ResponseTime = $using:TestResult.ResponseTime
            }
            $ResultObject = New-Object PSObject -Property @{Time = $using:Time; Computer = $using:Computer; ResponseTime = $ResponseTime}
            Export-Csv -InputObject $ResultObject "$using:outPath\results\ping$using:Computer.csv" -Append
        }
    }
}


Do { 
    $TimeNow = Get-Date
    if ($TimeNow -ge $TimeEnd) {  
		Write-host "Exiting..."
	} else {
		Write-Host "scriptPath: $scriptPath"
		PingTest -Computers $Computers -outPath $scriptPath
		Write-Host "Sleeping..."
	}
	Start-Sleep 1
}
Until ($TimeNow -ge $TimeEnd)
foreach ($Computer in $Computers){
    $Time = get-date -format yyyy-MM-ddTHH-mm-ss-ff
    Write-Host $Time
    $newfilename = "$scriptPath\results" + $Time + "ping$Computer.csv"
    Write-Host $newfilename
    Rename-Item -NewName $newfilename -Path "C:\scripts\mhping\ping$ComputerScope.csv"
}
try { Stop-Transcript | out-null } catch { }