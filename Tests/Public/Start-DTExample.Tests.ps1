Describe 'Start-DTExample' {
    BeforeEach {
        Import-Module $PSScriptRoot\..\..\DynamicTitle -Force
    }

    It 'should not throw an error' {
        Start-DTExample -Name CommandExecutionTime
    }

    AfterEach {
        Remove-Module DynamicTitle -Force
    }
}
