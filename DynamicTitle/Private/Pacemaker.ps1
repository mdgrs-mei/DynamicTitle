class Pacemaker
{
    $stopwatch = $null
    $intervalMilliseconds = 0

    Pacemaker($intervalMilliseconds)
    {
        $this.stopwatch = [System.Diagnostics.Stopwatch]::new()
        $this.intervalMilliseconds = $intervalMilliseconds
    }

    [void] Tick()
    {
        if ($this.stopwatch.IsRunning)
        {
            $this.stopwatch.Stop()
            $waitMilliseconds = $this.intervalMilliseconds - $this.stopwatch.ElapsedMilliseconds
            $this.stopwatch.Reset()
            if ($waitMilliseconds -gt 0)
            {
                Start-Sleep -Milliseconds $waitMilliseconds
            }
        }
        $this.stopwatch.Start()
    }
}
