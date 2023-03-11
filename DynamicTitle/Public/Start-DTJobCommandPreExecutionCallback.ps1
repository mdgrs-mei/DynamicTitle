<#
.SYNOPSIS
Registers a callback function that is called before the commands entered on the console are executed.

.DESCRIPTION
Registers a callback function that is called before the commands entered on the console are executed.
The callback runs on the main thread. It can be used to get the command string or the command start time.
This function overwrites PSConsoleHostReadLine so if you define your original PSConsoleHostReadLine, this function needs to be called after those definitions.

.PARAMETER ScriptBlock
ScriptBlock that is called before the command entered on the console is executed. The command string is passed as $args[0].

.PARAMETER ArgumentList
The arguments passed to the ScriptBlock. The arguments are stored from $args[1].

.INPUTS
None.

.OUTPUTS
PSCustomObject that represents a Job object.

.EXAMPLE
$job = Start-DTJobCommandPreExecutionCallback -ScriptBlock {$args[0]}
$commandString = Get-DTJobLatestOutput $job

#>
function Start-DTJobCommandPreExecutionCallback
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ScriptBlock]$ScriptBlock,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Object[]]$ArgumentList
    )

    process
    {
        $sync = [System.Collections.Hashtable]::Synchronized(@{})

        $arguments = @{
            sync = $sync
            scriptBlock = $ScriptBlock
            argumentList = $ArgumentList
        }

        $callback = {
            if ($args.argumentList)
            {
                $args.sync.output = $args.scriptBlock.Invoke(@($args.command) + @($args.argumentList))
            }
            else
            {
                $args.sync.output = $args.scriptBlock.Invoke($args.command)
            }
        }

        $script:globalStore.ReplacePSConsoleHostReadLine()
        $script:globalStore.AddCommandPreExecutionCallback($callback, $arguments)

        $job = [PSCustomObject]@{
            Sync = $sync
        }
        $job
    }
}