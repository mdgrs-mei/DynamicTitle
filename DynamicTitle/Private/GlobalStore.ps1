class GlobalStore
{
    $originalTitle = $null
    $originalPrompt = $null
    $isPromptReplaced = $false
    $originalPSConsoleHostReadLine = $null
    $isReadLineReplaced = $false
    $isInLegacyApplicationMode = $false
    $titleUpdateThread = $null
    $backgroundThreadTimerJobs = @()
    $promptCallbacks = @()
    $commandPreExecutionCallbacks = @()

    [void] Clear()
    {
        if ($this.isInLegacyApplicationMode)
        {
            $this.ExitLegacyApplicationMode()
        }

        $this.ClearTitleUpdateThread()

        foreach ($timerJob in $this.backgroundThreadTimerJobs)
        {
            StopThread $timerJob.Thread
        }
        $this.backgroundThreadTimerJobs = @()

        $this.RestorePrompt()
        $this.RestorePSConsoleHostReadLine()
    }

    [void] ClearTitleUpdateThread()
    {
        if ($this.titleUpdateThread)
        {
            StopThread $this.titleUpdateThread
            $this.titleUpdateThread = $null
        }

        if ($null -ne $this.originalTitle)
        {
            (Get-Host).UI.RawUI.WindowTitle = $this.originalTitle
            $this.originalTitle = $null
        }
    }

    [void] EnterLegacyApplicationMode()
    {
        if ($this.isInLegacyApplicationMode)
        {
            Write-Error -Message 'Already in Legacy Application Mode.' -Category InvalidOperation
            return
        }
        (Get-Host).NotifyBeginApplication()
        $this.isInLegacyApplicationMode = $true
    }

    [void] ExitLegacyApplicationMode()
    {
        if (-not $this.isInLegacyApplicationMode)
        {
            Write-Error -Message 'Not in Legacy Application Mode.' -Category InvalidOperation
            return
        }
        (Get-Host).NotifyEndApplication()
        $this.isInLegacyApplicationMode = $false
    }

    [void] SetTitleUpdateThread($thread, [string]$originalTitle)
    {
        $this.titleUpdateThread = $thread
        $this.originalTitle = $originalTitle
    }

    [void] AddBackgroundThreadTimerJob($job)
    {
        $this.backgroundThreadTimerJobs += $job
    }

    [void] ReplacePrompt()
    {
        if ($this.isPromptReplaced)
        {
            return
        }

        $this.isPromptReplaced = $true
        $this.originalPrompt = $function:global:Prompt
        $function:global:Prompt = {
            $script:globalStore.InvokePrompt()
        }
    }

    [void] RestorePrompt()
    {
        if (-not $this.isPromptReplaced)
        {
            return
        }

        $function:global:Prompt = $this.originalPrompt
        $this.isPromptReplaced = $false

        $this.promptCallbacks = @()
    }

    [void] AddPromptCallback([ScriptBlock]$scriptBlock, $arguments)
    {
        $this.promptCallbacks += ,@($scriptBlock, $arguments)
    }

    [string] InvokePrompt()
    {
        foreach ($private:callback in $this.promptCallbacks)
        {
            $private:scriptBlock = $callback[0]
            $private:arguments = $callback[1]
            try
            {
                $scriptBlock.Invoke($arguments)
            }
            catch
            {
                $_ | Out-Default
            }
        }
        return $this.originalPrompt.Invoke()
    }

    [void] ReplacePSConsoleHostReadLine()
    {
        if ($this.isReadLineReplaced)
        {
            return
        }

        $this.isReadLineReplaced = $true
        $this.originalPSConsoleHostReadLine = $function:global:PSConsoleHostReadLine
        $function:global:PSConsoleHostReadLine = {
            $script:globalStore.InvokePSConsoleHostReadLine()
        }
    }

    [void] RestorePSConsoleHostReadLine()
    {
        if (-not $this.isReadLineReplaced)
        {
            return
        }

        $function:global:PSConsoleHostReadLine = $this.originalPSConsoleHostReadLine
        $this.isReadLineReplaced = $false

        $this.commandPreExecutionCallbacks = @()
    }

    [void] AddCommandPreExecutionCallback([ScriptBlock]$scriptBlock, $arguments)
    {
        $this.commandPreExecutionCallbacks += ,@($scriptBlock, $arguments)
    }

    [Object] InvokePSConsoleHostReadLine()
    {
        $private:command = $this.originalPSConsoleHostReadLine.Invoke()
        foreach ($private:callback in $this.commandPreExecutionCallbacks)
        {
            $private:scriptBlock = $callback[0]
            $private:arguments = $callback[1]
            $arguments.command = $command
            try
            {
                $scriptBlock.Invoke($arguments)
            }
            catch
            {
                $_ | Out-Default
            }
        }
        return $command
    }
}

$script:globalStore = [GlobalStore]::new()
