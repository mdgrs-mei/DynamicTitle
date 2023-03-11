<#
.SYNOPSIS
Registers a callback function that is called before the Prompt function.

.DESCRIPTION
Registers a callback function that is called before the Prompt function. The callback runs on the main thread so it can be used to get the current directly for example.
If you define your Prompt function, this function needs to be called after those definitions because the callback is achieved by overwriting the Prompt function.

.PARAMETER ScriptBlock
ScriptBlock that is called before the Prompt function.

.PARAMETER ArgumentList
The arguments passed to the ScriptBlock.

.INPUTS
None.

.OUTPUTS
PSCustomObject that represents a Job object.

.EXAMPLE
$job = Start-DTJobPromptCallback -ScriptBlock {Get-Location}
$currentDirectory = Get-DTJobLatestOutput $job

#>
function Start-DTJobPromptCallback
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
            $args.sync.output = $args.scriptBlock.Invoke($args.argumentList)
        }

        $script:globalStore.ReplacePrompt()
        $script:globalStore.AddPromptCallback($callback, $arguments)

        $job = [PSCustomObject]@{
            Sync = $sync
        }
        $job
    }
}