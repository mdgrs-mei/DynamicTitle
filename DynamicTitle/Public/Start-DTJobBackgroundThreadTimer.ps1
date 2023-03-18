<#
.SYNOPSIS
Starts a background thread and calls a function periodically on the thread.

.DESCRIPTION
Starts a background thread and calls a function periodically on the thread.
The specified ScriptBlock is called periodically at the specified interval on a background thread. It can be used to get the information that takes time to process.

.PARAMETER ScriptBlock
ScriptBlock that is called periodically.

.PARAMETER ArgumentList
The arguments passed to the ScriptBlock. The ScriptBlock runs on another thread (Runspace) so variables on the main thread need to be passed as this ArgumentList.

.PARAMETER InitializationScript
ScriptBlock that is called at the start of the new thread. It runs in the global scope of the thread.

.PARAMETER InitializationArgumentList
The arguments passed to the InitializationScript.

.PARAMETER IntervalMilliseconds
The ScriptBlock is called at this interval milliseconds.

.INPUTS
None.

.OUTPUTS
PSCustomObject that represents a job object.

.EXAMPLE
$job = Start-DTJobBackgroundThreadTimer -ScriptBlock {Invoke-RestMethod https://wttr.in/?format="%c%t\n"} -IntervalMilliseconds 60000
$weather = Get-DTJobLatestOutput $job

#>
function Start-DTJobBackgroundThreadTimer
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ScriptBlock]$ScriptBlock,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Object[]]$ArgumentList,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [ScriptBlock]$InitializationScript,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Object[]]$InitializationArgumentList,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Int]$IntervalMilliseconds = 500
    )

    process
    {
        $sync = [System.Collections.Hashtable]::Synchronized(@{})

        $arguments = @{
            host = $host
            sync = $sync
            scriptBlock = $ScriptBlock.Ast.GetScriptBlock()
            argumentList = $ArgumentList
            intervalMilliseconds = $IntervalMilliseconds
            scriptRoot = $PSScriptRoot
        }

        if ($InitializationScript)
        {
            $arguments.initializationScript = $InitializationScript.Ast.GetScriptBlock()
            $arguments.initializationArgumentList = $InitializationArgumentList
        }

        $threadFunc = {
            $private:dynamicTitleBackgroundThreadTimerJob = New-Module -ScriptBlock {
                . $args
            } -ArgumentList (Join-Path $args.scriptRoot '..\Private\_BackgroundJobHelper.ps1') -AsCustomObject
            $private:dynamicTitleBackgroundThreadTimerJob.Init($args)

            if ($args.initializationScript)
            {
                $private:dynamicTitleErrorVariable = $null
                Invoke-Command $args.initializationScript -NoNewScope -ArgumentList $args.initializationArgumentList -ErrorVariable dynamicTitleErrorVariable
                if ($dynamicTitleErrorVariable)
                {
                    $args.host.UI.WriteErrorLine($dynamicTitleErrorVariable)
                }
            }

            while ($dynamicTitleBackgroundThreadTimerJob.Tick())
            {
                $private:dynamicTitleErrorVariable = $null
                $args.sync.output = Invoke-Command $args.scriptBlock -ArgumentList $args.argumentList -ErrorVariable dynamicTitleErrorVariable
                if ($dynamicTitleErrorVariable)
                {
                    $args.host.UI.WriteErrorLine($dynamicTitleErrorVariable)
                }
            }
        }

        $thread = StartThread $threadFunc $arguments

        $job = [PSCustomObject]@{
            Sync = $sync
            Thread = $thread
        }
        $script:globalStore.AddBackgroundThreadTimerJob($job)

        $job
    }
}