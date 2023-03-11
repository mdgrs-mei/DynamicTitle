Describe 'Start-DTJobCommandPreExecutionCallback' {
    BeforeEach {
        Import-Module $PSScriptRoot\..\..\DynamicTitle -Force
    }

    It 'should return a job object' {
        $job = Start-DTJobCommandPreExecutionCallback -ScriptBlock {'hello'} -ArgumentList 1
        $job.Sync | Should -Not -Be $null
    }

    AfterEach {
        Remove-Module DynamicTitle -Force
    }
}
