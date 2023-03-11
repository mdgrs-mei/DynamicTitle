. $PSScriptRoot\Pacemaker.ps1

$pacemaker = $null

function Init($arguments)
{
    $script:pacemaker = [Pacemaker]::new($arguments.intervalMilliseconds)
}

function Tick()
{
    $script:pacemaker.Tick()
    $true
}
