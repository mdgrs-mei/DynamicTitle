function StartThread([ScriptBlock]$scriptBlock, $arguments)
{
    $runspace = [RunSpaceFactory]::CreateRunspace()
    $runspace.Open()

    $powershell = [PowerShell]::Create()
    $powershell.Runspace = $runspace
    $powershell.AddScript($scriptBlock.ToString())
    $powershell.AddArgument($arguments)

    $asyncHandle = $powershell.BeginInvoke()

    $thread = [PSCustomObject]@{
        Runspace = $runspace
        Powershell = $powershell
        AsyncHandle = $asyncHandle
    }
    $thread
}

function StopThread($thread)
{
    $thread.Runspace.Dispose()
    $thread.Powershell.Dispose()
}
