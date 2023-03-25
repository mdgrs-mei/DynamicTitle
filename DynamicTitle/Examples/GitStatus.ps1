#Requires -Modules DynamicTitle

$modulePath = Join-Path (Get-Module DynamicTitle).ModuleBase 'DynamicTitle.psd1'

$initializationScript = {
    param ($modulePath)
    Import-Module $modulePath
}

$promptJob = Start-DTJobPromptCallback -ScriptBlock {
    (Get-Location).Path
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
    
} -IntervalMilliseconds 1000 -ArgumentList $promptJob -InitializationScript $initializationScript -InitializationArgumentList $modulePath

$scriptBlock = {
    param($promptJob, $gitJob)

    $location = Get-DTJobLatestOutput $promptJob
    $gitStatus, $gitLocation = Get-DTJobLatestOutput $gitJob

    if ($location)
    {
        $folderName = Split-Path $location -Leaf
    }
    if ($gitLocation -ne $location)
    {
        $gitStatus = $null
    }
    
    '🗂️{0} {1}' -f $folderName, $gitStatus
}

$params = @{
    ScriptBlock = $scriptBlock
    ArgumentList = $promptJob, $gitJob
    InitializationScript = $initializationScript
    InitializationArgumentList = $modulePath
}

Start-DTTitle @params
