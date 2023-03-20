<#
.SYNOPSIS
Calls $host.NotifyBeginApplication() so that the host doesn't reset the title when executing legacy command line applications.

.DESCRIPTION
Calls $host.NotifyBeginApplication() so that the host doesn't reset the title when executing legacy command line applications.

When command line applications are executed on the main thread, the host saves the title string before calling the application and resets it when the application returns. This behavior sometimes causes a blink on the title as you are changing the title on a background thread.
Enter-DTLegacyApplicationMode calls $host.NotifyBeginApplication() to notify the host that the subsequent commands are all legacy command line applications, and therefore the title reset behavior on every command call is suppressed.
Note that this workaround stops all the state restore from the command line applications which may cause some other issues.

.INPUTS
None.

.OUTPUTS
None.

.EXAMPLE
Enter-DTLegacyApplicationMode
Start-DTTitle {Get-Date}

#>
function Enter-DTLegacyApplicationMode
{
    process
    {
        $script:globalStore.EnterLegacyApplicationMode()
    }
}
