<#
.SYNOPSIS
Calls $host.NotifyEndApplication().

.DESCRIPTION
Calls $host.NotifyEndApplication(). See the help of Enter-DTLegacyApplicationMode.

.INPUTS
None.

.OUTPUTS
None.

.EXAMPLE
Exit-DTLegacyApplicationMode

#>
function Exit-DTLegacyApplicationMode
{
    process
    {
        $script:globalStore.ExitLegacyApplicationMode()
    }
}
