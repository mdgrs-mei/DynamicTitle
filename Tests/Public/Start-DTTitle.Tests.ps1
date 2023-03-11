Describe 'Start-DTTitle' {
    BeforeEach {
        Import-Module $PSScriptRoot\..\..\DynamicTitle -Force
    }

    It 'should set a title' {
        Start-DTTitle {'hello'}
        Start-Sleep -Milliseconds 500
        $host.UI.RawUI.WindowTitle | Should -Be 'hello'
    }

    It 'should pass an ArgumentList' {
        $title1 = 'hello '
        $title2 = 'world'
        Start-DTTitle -ScriptBlock {$args[0] + $args[1]} -ArgumentList $title1, $title2
        Start-Sleep -Milliseconds 500
        $host.UI.RawUI.WindowTitle | Should -Be ($title1 + $title2)
    }

    It 'should run an InitializationScript' {
        Start-DTTitle -ScriptBlock {$title} -InitializationScript {$title = 'hi, hi'}
        Start-Sleep -Milliseconds 500
        $host.UI.RawUI.WindowTitle | Should -Be 'hi, hi'
    }

    It 'should pass an InitializationArgumentList' {
        $title = 'hello, hello'
        Start-DTTitle -ScriptBlock {$title} -InitializationScript {$title = $args[0]} -InitializationArgumentList $title
        Start-Sleep -Milliseconds 500
        $host.UI.RawUI.WindowTitle | Should -Be $title
    }

    It 'should reflect UpdateIntervalMilliseconds' {
        Start-DTTitle -ScriptBlock {$script:count++;$script:count} -InitializationScript {$count = 0} -UpdateIntervalMilliseconds 1000
        Start-Sleep -Milliseconds 500
        [Int]($host.UI.RawUI.WindowTitle) | Should -Be 1
    }

    It 'should reflect VerticalScrollIntervalMilliseconds' {
        Start-DTTitle -ScriptBlock {'line1', 'line2'} -VerticalScrollIntervalMilliseconds 400
        Start-Sleep -Milliseconds 500
        $host.UI.RawUI.WindowTitle | Should -Be 'line2'
    }

    It 'should reflect HorizontalScrollFrameWidth' {
        Start-DTTitle -ScriptBlock {'123456789'} -HorizontalScrollFrameWidth 5
        Start-Sleep -Milliseconds 200
        $host.UI.RawUI.WindowTitle.Length | Should -Be 5
    }

    It 'should reflect HorizontalScroll interval and wait' {
        Start-DTTitle -ScriptBlock {'123456789'} -HorizontalScrollFrameWidth 5 -HorizontalScrollIntervalMilliseconds 400 -HorizontalScrollWaitMilliseconds 0
        Start-Sleep -Milliseconds 500
        $host.UI.RawUI.WindowTitle[0] | Should -Be '2'
    }

    AfterEach {
        Remove-Module DynamicTitle -Force
    }
}
