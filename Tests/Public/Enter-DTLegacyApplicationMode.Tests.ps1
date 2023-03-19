Describe 'Enter-DTLegacyApplicationMode' {
    BeforeEach {
        Import-Module $PSScriptRoot\..\..\DynamicTitle -Force
    }

    It 'should not throw an error' {
        Enter-DTLegacyApplicationMode
    }

    AfterEach {
        Remove-Module DynamicTitle -Force
    }
}
