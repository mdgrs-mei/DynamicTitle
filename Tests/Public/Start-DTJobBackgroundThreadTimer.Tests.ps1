Describe 'Start-DTJobBackgroundThreadTimer' {
    BeforeEach {
        Import-Module $PSScriptRoot\..\..\DynamicTitle -Force
    }

    It 'should run a script' {
        $job = Start-DTJobBackgroundThreadTimer -ScriptBlock {'hello'}
        Start-Sleep -Milliseconds 100
        $job | Get-DTJobLatestOutput | Should -Be 'hello'
    }

    It 'should pass an ArgumentList' {
        $job = Start-DTJobBackgroundThreadTimer -ScriptBlock {$args[0] + $args[1]} -ArgumentList 1, 2
        Start-Sleep -Milliseconds 500
        $job | Get-DTJobLatestOutput | Should -Be 3
    }

    It 'should run an InitializationScript' {
        $job = Start-DTJobBackgroundThreadTimer -ScriptBlock {$var} -InitializationScript {$var = 5}
        Start-Sleep -Milliseconds 500
        $job | Get-DTJobLatestOutput | Should -Be 5
    }

    It 'should pass an InitializationArgumentList' {
        $argumentList = 'hello, hello'
        $job = Start-DTJobBackgroundThreadTimer -ScriptBlock {$var} -InitializationScript {$var = $args[0]} -InitializationArgumentList $argumentList
        Start-Sleep -Milliseconds 500
        $job | Get-DTJobLatestOutput | Should -Be $argumentList
    }

    It 'should reflect IntarvalMilliseconds' {
        $job = Start-DTJobBackgroundThreadTimer -ScriptBlock {$script:count++;$script:count} -InitializationScript {$count = 0} -IntervalMilliseconds 300
        Start-Sleep -Milliseconds 400
        $job | Get-DTJobLatestOutput | Should -Be 2
    }

    AfterEach {
        Remove-Module DynamicTitle -Force
    }
}
