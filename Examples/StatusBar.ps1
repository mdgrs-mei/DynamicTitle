Import-Module $PSScriptRoot\..\DynamicTitle

function StartDTStatusBar
{
    $modulePath = "$PSScriptRoot\..\DynamicTitle"

    $weatherJob = Start-DTJobBackgroundThreadTimer -ScriptBlock {
        $weather = Invoke-RestMethod https://wttr.in/?format="%c%t\n"
        $weather
    } -IntervalMilliseconds 60000

    $systemInfoJob = Start-DTJobBackgroundThreadTimer -ScriptBlock {
        $cpuUsage = (Get-Counter -Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
        $netInterface = (Get-CimInstance -class Win32_PerfFormattedData_Tcpip_NetworkInterface)[0]
        $cpuUsage, ($netInterface.BytesReceivedPersec * 8), ($netInterface.BytesSentPersec * 8)
    } -IntervalMilliseconds 1000

    $initializationScript = {
        param ($modulePath)
        Import-Module $modulePath
    }

    $scriptBlock = {
        param($weatherJob, $systemInfoJob)

        $weather = Get-DTJobLatestOutput $weatherJob
        $cpuUsage, $bpsReceived, $bpsSent = Get-DTJobLatestOutput $systemInfoJob
        $date = Get-Date -Format 'MMM dd HH:mm:ss'

        '📆 {0} {1}  --- 🔥CPU:{2:f1}% 🔼{3}Mbps 🔽{4}Mbps' -f $date, $weather, [double]$cpuUsage, [Int]($bpsSent/1MB), [Int]($bpsReceived/1MB)
    }
    
    $params = @{
        ScriptBlock = $scriptBlock
        ArgumentList = $weatherJob, $systemInfoJob
        InitializationScript = $initializationScript
        InitializationArgumentList = $modulePath
    }

    Start-DTTitle @params
}

StartDTStatusBar

