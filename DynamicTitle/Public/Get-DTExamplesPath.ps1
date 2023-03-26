<#
.SYNOPSIS
Returns the path of the Examples directory.

.DESCRIPTION
Returns the path of the Examples directory.

.INPUTS
None.

.OUTPUTS
String.

.EXAMPLE
$examples = Get-DTExamplesPath
Get-ChildItem -Path $examples

#>
function Get-DTExamplesPath
{
    process
    {
        Join-Path (Split-Path $PSScriptRoot -Parent) 'Examples'
    }
}