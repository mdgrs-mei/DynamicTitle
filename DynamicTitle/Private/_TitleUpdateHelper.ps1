. $PSScriptRoot\Pacemaker.ps1

$arguments = $null
$pacemaker = $null
$lineIndex = 0
$verticalScrollFrameCount = 0
$horizontalScrollIndex = 0
$horizontalScrollFrameCount = 0

function Init($arguments)
{
    $script:arguments = $arguments
    $script:pacemaker = [Pacemaker]::new($arguments.intervalMilliseconds)
}

function Tick()
{
    $script:pacemaker.Tick()
    $true
}

function GetTitle($lines)
{
    $script:lineIndex = $script:lineIndex % $lines.Count
    $line = $lines[$script:lineIndex]

    $title, $isHorizontalScrollEnd = HorizontalScroll $line

    VerticalScroll $isHorizontalScrollEnd

    $title
}

function HorizontalScroll($line)
{
    $isScrollEnd = $false
    if ($script:arguments.horizontalScrollFrameWidth -gt 0)
    {
        $stringInfo = [System.Globalization.StringInfo]::new($line)
        if ($stringInfo.LengthInTextElements -gt $script:arguments.horizontalScrollFrameWidth)
        {
            $script:horizontalScrollFrameCount++
            if ($script:horizontalScrollIndex -eq 0)
            {
                # start wait
                $wait = $script:arguments.horizontalScrollWaitFrame + $script:arguments.horizontalScrollFrame
                if ($script:horizontalScrollFrameCount -gt $wait)
                {
                    $script:horizontalScrollFrameCount = 0
                    $script:horizontalScrollIndex++
                }
            }
            elseif (($stringInfo.LengthInTextElements - $script:horizontalScrollIndex) -gt $script:arguments.horizontalScrollFrameWidth)
            {
                # scrolling
                if ($script:horizontalScrollFrameCount -ge $script:arguments.horizontalScrollFrame)
                {
                    $script:horizontalScrollFrameCount = 0
                    $script:horizontalScrollIndex++
                }
            }
            else
            {
                # end wait
                $script:horizontalScrollIndex = [Math]::Min($script:horizontalScrollIndex, $stringInfo.LengthInTextElements-1)
                $wait = $script:arguments.horizontalScrollWaitFrame + $script:arguments.horizontalScrollFrame
                if ($script:horizontalScrollFrameCount -ge $wait)
                {
                    $script:horizontalScrollFrameCount = 0
                    $isScrollEnd = $true
                }
            }

            $line = $stringInfo.SubstringByTextElements($script:horizontalScrollIndex, $script:arguments.horizontalScrollFrameWidth)

            if ($isScrollEnd)
            {
                $script:horizontalScrollIndex = 0
            }
        }
        else
        {
            # no need to scroll
            $script:horizontalScrollFrameCount = 0
            $script:horizontalScrollIndex = 0
            $isScrollEnd = $true
        }
    }
    else
    {
        $isScrollEnd = $true
    }

    $line, $isScrollEnd
}

function VerticalScroll($isHorizontalScrollEnd)
{
    $script:verticalScrollFrameCount++
    if ($isHorizontalScrollEnd -and ($script:verticalScrollFrameCount -ge $script:arguments.verticalScrollFrame))
    {
        $script:verticalScrollFrameCount = 0
        $script:lineIndex++
    }
}