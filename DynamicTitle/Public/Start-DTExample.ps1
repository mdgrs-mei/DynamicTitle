<#
.SYNOPSIS
Starts an example DynamicTitle script.

.DESCRIPTION
Starts an example DynamicTitle script.

.PARAMETER Name
Filename of the example script. The tab completion helps you pick one of the examples.

.INPUTS
None.

.OUTPUTS
None.

.EXAMPLE
Start-DTExample -Name GitStatus

#>
function Start-DTExample
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param
    (
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            $_ -in (Get-ChildItem (Get-DTExamplesPath)).BaseName
        })]
        [ArgumentCompleter({
            $wordToComplete = $args[2]
            $names = (Get-ChildItem (Get-DTExamplesPath)).BaseName
            $names -like "$wordToComplete*"
        })]
        [String]$Name
    )

    process
    {
        Stop-DTTitle
        $private:examplesPath = Get-DTExamplesPath
        $private:scriptFile = Join-Path $examplesPath "$Name.ps1"
        . $scriptFile
    }
}