#Requires -Modules DynamicTitle

$modulePath = Join-Path (Get-Module DynamicTitle).ModuleBase 'DynamicTitle.psd1'

function StartDTCommandExecutionTime
{
    $commandStartJob = Start-DTJobCommandPreExecutionCallback -ScriptBlock {
        param($command)
        (Get-Date), $command
    }
    
    $commandEndJob = Start-DTJobPromptCallback -ScriptBlock {
        Get-Date
    }

    $initializationScript = {
        param ($modulePath)
        Import-Module $modulePath
        $psVersion = 'PS ' + $PSVersionTable.PSVersion.ToString()
    }
    $scriptBlock = {
        param($commandStartJob, $commandEndJob)
        $commandStartDate, $command = Get-DTJobLatestOutput $commandStartJob
        $commandEndDate = Get-DTJobLatestOutput $commandEndJob
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

        $status = '🟢'
        if ($commandDuration)
        {
            if ($commandDuration.TotalSeconds -gt 1)
            {
                $commandSegment = '[{0}]-⌚{1}' -f $command, $commandDuration.ToString('mm\:ss')
                if ($isCommandRunning)
                {
                    $status = '🟠'
                }
            }
        }
        
        '{0} {1} {2}' -f $status, $psVersion, $commandSegment
    }
    
    $params = @{
        ScriptBlock = $scriptBlock
        ArgumentList = $commandStartJob, $commandEndJob
        InitializationScript = $initializationScript
        InitializationArgumentList = "$PSScriptRoot\..\DynamicTitle"
    }

    Start-DTTitle @params
}

StartDTCommandExecutionTime

