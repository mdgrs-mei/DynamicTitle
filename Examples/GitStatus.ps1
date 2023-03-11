Import-Module $PSScriptRoot\..\DynamicTitle

function StartDTGitStatus
{
    $modulePath = "$PSScriptRoot\..\DynamicTitle"

    $initializationScript = {
        param ($modulePath)
        Import-Module $modulePath
    }

    $promptJob = Start-DTJobPromptCallback -ScriptBlock {
        Get-Location
    }

    $gitJob = Start-DTJobBackgroundThreadTimer -ScriptBlock {
        param ($promptJob)
        $location = Get-DTJobLatestOutput $promptJob
        if (-not $location)
        {
            return
        }

        Set-Location $location
        $branch = git branch --show-current
        if ($LastExitCode -ne 0)
        {
            return
        }

        $statusLines = git status -s
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

        '🌿[{0}] ✏️{1}❔{2}' -f $branch, $modifiedCount, $unversionedCount
        
    } -IntervalMilliseconds 1000 -ArgumentList $promptJob -InitializationScript $initializationScript -InitializationArgumentList $modulePath

    $scriptBlock = {
        param($promptJob, $gitJob)

        $location = Get-DTJobLatestOutput $promptJob
        if ($location)
        {
            $location = Split-Path $location -Leaf
        }

        $gitStatus = Get-DTJobLatestOutput $gitJob
        
        '🗂️{0} {1}' -f $location, $gitStatus
    }
    
    $params = @{
        ScriptBlock = $scriptBlock
        ArgumentList = $promptJob, $gitJob
        InitializationScript = $initializationScript
        InitializationArgumentList = $modulePath
    }

    Start-DTTitle @params
}

StartDTGitStatus

