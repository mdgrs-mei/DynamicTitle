#Requires -Modules DynamicTitle

if (-not $IsWindows)
{
    Write-Error -Message 'Runs only on Windows.' -Category InvalidOperation
    return
}
$modulePath = Join-Path (Get-Module DynamicTitle).ModuleBase 'DynamicTitle.psd1'

$initializationScript = {
    param ($modulePath)
    Import-Module $modulePath
    $psVersion = 'PS ' + $PSVersionTable.PSVersion.ToString()
}

$netThroughputJob = Start-DTJobBackgroundThreadTimer -ScriptBlock {
    $netInterface = (Get-CimInstance -class Win32_PerfFormattedData_Tcpip_NetworkInterface)[0]
    [Int]($netInterface.BytesReceivedPersec * 8 / 1MB), [Int]($netInterface.BytesSentPersec * 8 / 1MB)
} -IntervalMilliseconds 1000

$commandStartJob = Start-DTJobCommandPreExecutionCallback -ScriptBlock {
    param($command)
    (Get-Date), $command
}

$promptJob = Start-DTJobPromptCallback -ScriptBlock {
    (Get-Date), (Get-Location).Path
}

$gitJob = Start-DTJobBackgroundThreadTimer -ScriptBlock {
    param ($promptJob)
    $date, $location = Get-DTJobLatestOutput $promptJob
    if (-not $location)
    {
        return
    }

    Set-Location $location
    $branch = git branch --show-current
    if ($LastExitCode -ne 0)
    {
        # not a git repository
        return
    }
    if (-not $branch)
    {
        $branch = '❔'
    }

    $statusLines = git --no-optional-locks status -s
    $modifiedCount = 0
    $unversionedCount = 0
    foreach ($line in $statusLines)
    {
        $type = $line.Substring(0, 2)
        if (($type -eq ' M') -or ($type -eq ' R'))
        {
            $modifiedCount++
        }
        elseif ($type -eq '??')
        {
            $unversionedCount++
        }
    }

    $gitStatus = '🌿[{0}] ✏️{1}❔{2}' -f $branch, $modifiedCount, $unversionedCount
    $gitStatus, $location
    
} -IntervalMilliseconds 2000 -ArgumentList $promptJob -InitializationScript $initializationScript -InitializationArgumentList $modulePath

$scriptBlock = {
    param($netThroughputJob, $commandStartJob, $promptJob, $gitJob)

    $mbpsReceived, $mbpsSent = Get-DTJobLatestOutput $netThroughputJob
    $commandStartDate, $command = Get-DTJobLatestOutput $commandStartJob
    $commandEndDate, $location = Get-DTJobLatestOutput $promptJob
    $gitStatus, $gitLocation = Get-DTJobLatestOutput $gitJob

    if ($mbpsReceived -or $mbpsSent)
    {
        $netThroughputSegment = ''
        if ($mbpsSent)
        {
            $netThroughputSegment += '🔼{0}Mbps ' -f $mbpsSent
        }
        if ($mbpsReceived)
        {
            $netThroughputSegment += '🔽{0}Mbps' -f $mbpsReceived
        }
    }

    if ($null -ne $commandStartDate)
    {
        if (($null -eq $commandEndDate) -or ($commandEndDate -lt $commandStartDate))
        {
            $commandDuration = (Get-Date) - $commandStartDate
            $isCommandRunning = $true
        }
        else
        {
            $commandDuration = $commandEndDate - $commandStartDate
        }
    }

    if ($command)
    {
        $command = $command.Split()[0]
    }

    $commandStatus = '🟢'
    if ($commandDuration)
    {
        if ($commandDuration.TotalSeconds -gt 1)
        {
            $commandSegment = '[{0}]-⌚{1}' -f $command, $commandDuration.ToString('mm\:ss')
            if ($isCommandRunning)
            {
                $commandStatus = '🟠'
            }
        }
    }

    if ($location)
    {
        $folderName = Split-Path $location -Leaf
    }
    if ($gitLocation -ne $location)
    {
        $gitStatus = $null
    }
    
    '{0} {1} {2} 🗂️{3} {4} {5}' -f $commandStatus, $psVersion, $commandSegment, $folderName, $gitStatus, $netThroughputSegment
}

$params = @{
    ScriptBlock = $scriptBlock
    ArgumentList = $netThroughputJob, $commandStartJob, $promptJob, $gitJob
    InitializationScript = $initializationScript
    InitializationArgumentList = $modulePath
}

Start-DTTitle @params
