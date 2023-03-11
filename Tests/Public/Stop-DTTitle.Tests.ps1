Describe 'Stop-DTTitle' {
    BeforeEach {
        Import-Module $PSScriptRoot\..\..\DynamicTitle -Force
    }

    It 'should reset the title' {
        $originalTitle = $host.UI.RawUI.WindowTitle
        Start-DTTitle {'hello'}
        Start-Sleep -Milliseconds 500
        Stop-DTTitle
        $host.UI.RawUI.WindowTitle | Should -Be $originalTitle
    }

    AfterEach {
        Remove-Module DynamicTitle -Force
    }
}
