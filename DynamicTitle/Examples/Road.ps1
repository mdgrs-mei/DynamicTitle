#Requires -Modules DynamicTitle

# Suppress this for $initializationScript
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param()

$modulePath = Join-Path (Get-Module DynamicTitle).ModuleBase 'DynamicTitle.psd1'

$promptJob = Start-DTJobPromptCallback {
    if ($null -eq $script:roadPromptFrame) {
        $script:roadPromptFrame = 0
    }
    $script:roadPromptFrame++

    $isInError = $false
    if ($global:Error[0]) {
        $isInError = -not ($global:Error[0].Equals($script:roadLastError))
        $script:roadLastError = $global:Error[0]
    }
    $isInError, $script:roadPromptFrame
}

$initializationScript = {
    param ($modulePath)
    Import-Module $modulePath

    $mainTitle = '  PowerShell  '
    $characters = @(
        '🚴'
        '🚴‍♂️'
        '🚴‍♀️'
        '🚙'
        '🚓'
        '🐈'
        '🐩'
        '🚚'
        '🚎'
        '🚕'
        '🚌'
        '🚒'
        '🚛'
        '🚁'
        '🛸'
    )
    $caution = '❗'

    $streetParts = @(
        '_._._.'
        '_.-._'
    )
    $streetLength = 2

    function GetCharacter {
        $characters | Get-Random
    }
    function GetStreet {
        $street = ''
        foreach ($i in 1..$streetLength) {
            $street += $streetParts | Get-Random
        }
        $street
    }
    function GetWaitFrame {
        Get-Random -Minimum 0 -Maximum 100
    }

    $character = GetCharacter
    $streetL = GetStreet
    $streetR = GetStreet
    $waitFrame = GetWaitFrame
    $characterPos = 1
    $lastPromptFrame = 0
    $isCaution = $false
}

$scriptBlock = {
    param($promptJob)

    $isInError, $promptFrame = Get-DTJobLatestOutput $promptJob
    if ($isInError -and ($promptFrame -ne $script:lastPromptFrame)) {
        $script:isCaution = $true
    }
    if (-not $isInError) {
        $script:isCaution = $false
    }
    $script:lastPromptFrame = $promptFrame

    $title = $streetL + $mainTitle + $streetR
    if ($script:waitFrame -gt 0) {
        $script:waitFrame--
        $script:isCaution = $false
        $title
        return
    }

    $stringInfo = [System.Globalization.StringInfo]::new($title)
    $length = $stringInfo.LengthInTextElements
    $characterIndex = $length - 1 - $script:characterPos

    if ($script:isCaution) {
        if ($characterIndex -ge 1) {
            $characterIndex -= 1
            $character = $caution + $character
        } else {
            $character = $character + $caution
        }
        $title = $stringInfo.SubstringByTextElements(0, $characterIndex) + $character + $stringInfo.SubstringByTextElements($characterIndex + 2)
    } else {
        $title = $stringInfo.SubstringByTextElements(0, $characterIndex) + $character + $stringInfo.SubstringByTextElements($characterIndex + 1)
        $script:characterPos += 1
        if ($script:characterPos -ge $length) {
            $script:characterPos = 1
            $script:waitFrame = GetWaitFrame
            $script:character = GetCharacter
        }
    }
    $title
}

$params = @{
    ScriptBlock = $scriptBlock
    ArgumentList = $promptJob
    InitializationScript = $initializationScript
    InitializationArgumentList = $modulePath
}

Start-DTTitle @params