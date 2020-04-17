<#
v0.1.2 Changed to start and stop times rather than loop counting which was inaccurate
v0.1.1 Changed to Military time
v0.1 Intial release: change $Computers and $ComputersScope to the same entries as needed.

#>
#Variables
#How long to run in minutes
$Duration = 600
#List of systems to ping
$Computers = "192.168.0.2","192.168.0.12","8.8.8.8","www.microsoft.com","127.0.0.1","192.168.0.9","192.168.0.67","192.168.0.77","192.168.0.97","192.168.0.60"

#Debugging
#$DebugPreference = "Continue"
#Logging feature
#$ErrorActionPreference="SilentlyContinue"
try { Stop-Transcript | out-null } catch { }

#start a transcript file
try { Start-Transcript -path $scriptLog } catch { }

#current script directory
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
#current script name
$path = Get-Location
$scriptName = $MyInvocation.MyCommand.Name
$scriptLog = "$scriptPath\log\$scriptName.log"

#Setup time period
$TimeStart = Get-Date
$TimeEnd = $timeStart.addminutes($Duration)
Write-Host "Start Time: $TimeStart"
write-host "End Time:   $TimeEnd"

workflow PingTest{
	Param (
        $Computers
    )
    foreach -parallel ($Computer in $Computers){
#		Write-Host pinging $Computer
#        $Time = Get-Date -format "yyyy-MM-dd HH:mm:ss"
#        $TestResult = Test-Connection -ComputerName $Computer -Count 1 -ErrorAction SilentlyContinue
        inlinescript{
			Write-Host pinging $Computer
			$Time = Get-Date -format "yyyy-MM-dd HH:mm:ss"
			$TestResult = Test-Connection -ComputerName $Computer -Count 1 -ErrorAction SilentlyContinue
            if ($using:TestResult.ResponseTime -eq $null){
                $ResponseTime = -1
            } else {
                $ResponseTime = $using:TestResult.ResponseTime
            }
            $ResultObject = New-Object PSObject -Property @{Time = $using:Time; Computer = $using:Computer; ResponseTime = $ResponseTime}
            Export-Csv -InputObject $ResultObject "C:\scripts\mhping\ping$using:Computer.csv" -Append
        }
    }
}
#Clear-Host
#$i = 0
#$ComputersScope = "192.168.0.2","192.168.0.12","8.8.8.8","www.microsoft.com","127.0.0.1","192.168.0.9","192.168.0.67","192.168.0.77","192.168.0.97","192.168.0.60"
Do { 
    $TimeNow = Get-Date
    if ($TimeNow -ge $TimeEnd) {
		Write-host "Exiting..."
	} else {
		PingTest($Computers)
		Write-Host "Sleeping..."
	}
	Start-Sleep 1
}
Until ($TimeNow -ge $TimeEnd)
foreach ($ComputerScope in $ComputersScope){
    $Time = Get-Date -format "yyyy-MM-dd-HH-mm-ss"
    Write-Host $Time
    $newfilename = "C:\scripts\mhping\" + $Time + "ping$ComputerScope.csv"
    Write-Host $newfilename
    Rename-Item -NewName $newfilename -Path "C:\scripts\mhping\ping$ComputerScope.csv"
}
try { Stop-Transcript | out-null } catch { }