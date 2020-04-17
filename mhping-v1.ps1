<#
v2 Military time and fixed schtask script to execution bypass
Intial release: change $Computers and $ComputersScope to the same entries as needed.

#>

$LoopCount = 20000

workflow PingTest{
    $Computers = "192.168.0.2","192.168.0.12","8.8.8.8","www.microsoft.com","127.0.0.1","192.168.0.9","192.168.0.67","192.168.0.77","192.168.0.97","192.168.0.60","192.168.0.106"
    foreach -parallel ($Computer in $Computers){
        $Time = Get-Date -format "yyyy-MM-dd HH:mm:ss"
        $TestResult = Test-Connection -ComputerName $Computer -Count 1 -ErrorAction SilentlyContinue
        inlinescript{
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
Clear-Host
$i = 0
$ComputersScope = "192.168.0.2","192.168.0.12","8.8.8.8","www.microsoft.com","127.0.0.1","192.168.0.9","192.168.0.67","192.168.0.77","192.168.0.97","192.168.0.60","192.168.0.106"
while($i -lt $LoopCount ){
    $Now = Get-Date
    Write-Host $Now "Testing..." -NoNewline
    PingTest
    Write-Host "Sleeping..."
    Start-Sleep 1
$i++
}
foreach ($ComputerScope in $ComputersScope){
    $Time = Get-Date -format "yyyy-MM-dd-HH-mm-ss"
    Write-Host $Time
    $newfilename = "C:\scripts\mhping\" + $Time + "ping$ComputerScope.csv"
    Write-Host $newfilename
    Rename-Item -NewName $newfilename -Path "C:\scripts\mhping\ping$ComputerScope.csv"
}
