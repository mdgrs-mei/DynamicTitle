<#
.SYNOPSIS
Starts a thread to set the console title.

.DESCRIPTION
Starts a thread to set the console title. The specified ScriptBlock is called periodically at the specified interval on a background thread.
The string returned by the ScriptBlock is set as the console title.

.PARAMETER ScriptBlock
ScriptBlock that is called periodically. It should return a string or an array of strings. If an array is returned, the strings are shown in order with a vertical scroll.

.PARAMETER ArgumentList
The arguments passed to the ScriptBlock. The ScriptBlock runs on another thread (Runspace) so variables on the main thread need to be passed as this ArgumentList.

.PARAMETER InitializationScript
ScriptBlock that is called at the start of the new thread. It runs in the global scope of the thread.

.PARAMETER InitializationArgumentList
The arguments passed to the InitializationScript.

.PARAMETER UpdateIntervalMilliseconds
The ScriptBlock is called at this interval milliseconds.

.PARAMETER VerticalScrollIntervalMilliseconds
If an array of strings is returned from the ScriptBlock, each element is set as the title in order at this interval milliseconds.

.PARAMETER HorizontalScrollFrameWidth
The title scrolls horizontally if the number of characters is higher than this number.

.PARAMETER HorizontalScrollIntervalMilliseconds
The title scrolls 1 character at this interval milliseconds.

.PARAMETER HorizontalScrollWaitMilliseconds
The horizontal scroll stops for this milliseconds at the start and the end of the scroll.

.INPUTS
None.

.OUTPUTS
None.

.EXAMPLE
Start-DTTitle -ScriptBlock {Get-Date} -UpdateIntervalMilliseconds 1000

#>
function Start-DTTitle
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
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
        [Int]$UpdateIntervalMilliseconds = 200,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Int]$VerticalScrollIntervalMilliseconds = 5000,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Int]$HorizontalScrollFrameWidth = 0,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Int]$HorizontalScrollIntervalMilliseconds = 400,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Int]$HorizontalScrollWaitMilliseconds = 2000
    )

    process
    {
        $script:globalStore.ClearTitleUpdateThread()

        $verticalScrollFrame = [Math]::Max([Int]($VerticalScrollIntervalMilliseconds / $UpdateIntervalMilliseconds), 1)
        $horizontalScrollFrame = [Math]::Max([Int]($HorizontalScrollIntervalMilliseconds / $UpdateIntervalMilliseconds), 1)
        $horizontalScrollWaitFrame = [Int]($HorizontalScrollWaitMilliseconds / $UpdateIntervalMilliseconds)

        $arguments = @{
            scriptBlock = $ScriptBlock.Ast.GetScriptBlock()
            argumentList = $ArgumentList
            intervalMilliseconds = $UpdateIntervalMilliseconds
            scriptRoot = $PSScriptRoot
            verticalScrollFrame = $verticalScrollFrame
            horizontalScrollFrameWidth = $HorizontalScrollFrameWidth
            horizontalScrollFrame = $horizontalScrollFrame
            horizontalScrollWaitFrame = $horizontalScrollWaitFrame
        }

        if ($InitializationScript)
        {
            $arguments.initializationScript = $InitializationScript.Ast.GetScriptBlock()
            $arguments.initializationArgumentList = $InitializationArgumentList
        }

        $threadFunc = {
            $private:dynamicTitleUpdateMain = New-Module -ScriptBlock {
                . $args
            } -ArgumentList (Join-Path $args.scriptRoot '..\Private\_TitleUpdateHelper.ps1') -AsCustomObject
            $private:dynamicTitleUpdateMain.Init($args)

            if ($args.initializationScript)
            {
                Invoke-Command $args.initializationScript -NoNewScope -ArgumentList $args.initializationArgumentList
            }

            while ($dynamicTitleUpdateMain.Tick())
            {
                $private:titleLines = [string[]]@($args.scriptBlock.Invoke($args.argumentList))
                $host.UI.RawUI.WindowTitle = $dynamicTitleUpdateMain.GetTitle($titleLines)
            }
        }

        $originalTitle = $host.UI.RawUI.WindowTitle
        $thread = StartThread $threadFunc $arguments $host
        $script:globalStore.SetTitleUpdateThread($thread, $originalTitle)
    }
}