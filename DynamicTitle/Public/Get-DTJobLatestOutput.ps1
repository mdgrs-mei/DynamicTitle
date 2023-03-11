<#
.SYNOPSIS
Returns the latest output of a job in a thread-safe way.

.DESCRIPTION
Returns the latest output of a job in a thread-safe way.
It returns immediately without waiting for the job output. It returns $null if the job has never returned an output.

.PARAMETER InputObject
Job object to get the output.

.INPUTS
PSCustomObject that represents a job object.

.OUTPUTS
Objects returned by the job's ScriptBlock.

.EXAMPLE
$job = Start-DTJobBackgroundThreadTimer -ScriptBlock {Invoke-RestMethod https://wttr.in/?format="%c%t\n"} -IntervalMilliseconds 60000
$weather = Get-DTJobLatestOutput $job

#>
function Get-DTJobLatestOutput
{
    param
    (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [PSCustomObject]$InputObject
    )

    process
    {
        $InputObject.Sync.output
    }
}