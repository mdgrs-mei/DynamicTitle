Describe 'Exit-DTLegacyApplicationMode' {
    BeforeEach {
        Import-Module $PSScriptRoot\..\..\DynamicTitle -Force
    }

    It 'should not throw an error' {
        Enter-DTLegacyApplicationMode
        Exit-DTLegacyApplicationMode
    }

    AfterEach {
        Remove-Module DynamicTitle -Force
    }
}
