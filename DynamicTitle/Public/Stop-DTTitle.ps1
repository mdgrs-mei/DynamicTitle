<#
.SYNOPSIS
Stops the DynamicTitle thread and restores the original title.

.DESCRIPTION
Stops the DynamicTitle thread and restores the original title. All the jobs are also stopped.

.INPUTS
None.

.OUTPUTS
None.

.EXAMPLE
Stop-DTTitle

#>
function Stop-DTTitle
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param()

    process
    {
        $script:globalStore.Clear()
    }
}
