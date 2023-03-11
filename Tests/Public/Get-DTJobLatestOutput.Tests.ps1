Describe 'Get-DTJobLatestOutput' {
    BeforeEach {
        Import-Module $PSScriptRoot\..\..\DynamicTitle -Force
    }

    It 'should return a job output' {
        $job = Start-DTJobBackgroundThreadTimer -ScriptBlock {'hello'} -IntervalMilliseconds 500
        Start-Sleep -Milliseconds 100
        $job | Get-DTJobLatestOutput | Should -Be 'hello'
    }

    AfterEach {
        Remove-Module DynamicTitle -Force
    }
}
