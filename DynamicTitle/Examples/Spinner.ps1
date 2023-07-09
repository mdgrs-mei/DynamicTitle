#Requires -Modules DynamicTitle

# Suppress this for $initializationScript
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param()

$modulePath = Join-Path (Get-Module DynamicTitle).ModuleBase 'DynamicTitle.psd1'

$commandStartJob = Start-DTJobCommandPreExecutionCallback -ScriptBlock {
    Get-Date
}

$commandEndJob = Start-DTJobPromptCallback -ScriptBlock {
    Get-Date
}

$initializationScript = {
    param ($modulePath)
    Import-Module $modulePath
    $spinnerSymbols = @('🌑', '🌒', '🌓', '🌔', '🌕', '🌖', '🌗', '🌘')
    $spinnerSymbolIndex = 0
}

$scriptBlock = {
    param($commandStartJob, $commandEndJob)
    $commandStartDate = Get-DTJobLatestOutput $commandStartJob
    $commandEndDate = Get-DTJobLatestOutput $commandEndJob
    if ($null -ne $commandStartDate)
    {
        if (($null -eq $commandEndDate) -or ($commandEndDate -lt $commandStartDate))
        {
            $commandDuration = (Get-Date) - $commandStartDate
        }
    }

    $spinner = $spinnerSymbols[0]
    if ($commandDuration)
    {
        if ($commandDuration.TotalSeconds -gt 1)
        {
            $script:spinnerSymbolIndex = ($script:spinnerSymbolIndex + 1) % $spinnerSymbols.Count
            $spinner = $spinnerSymbols[$script:spinnerSymbolIndex]
        }
    }
    else
    {
        $script:spinnerSymbolIndex = 0
    }

    '{0} PowerShell' -f $spinner
}

$params = @{
    ScriptBlock = $scriptBlock
    ArgumentList = $commandStartJob, $commandEndJob
    InitializationScript = $initializationScript
    InitializationArgumentList = $modulePath
}

Start-DTTitle @params
