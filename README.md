<div align="center">

# DynamicTitle

[![GitHub license](https://img.shields.io/github/license/mdgrs-mei/DynamicTitle)](https://github.com/mdgrs-mei/DynamicTitle/blob/main/LICENSE)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/p/DynamicTitle)](https://www.powershellgallery.com/packages/DynamicTitle)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/DynamicTitle)](https://www.powershellgallery.com/packages/DynamicTitle)

[![Pester Test](https://github.com/mdgrs-mei/DynamicTitle/actions/workflows/pester-test.yml/badge.svg)](https://github.com/mdgrs-mei/DynamicTitle/actions/workflows/pester-test.yml)

*DynamicTitle* is a PowerShell module for advanced console title customizations.

https://user-images.githubusercontent.com/81177095/224492181-e6b60d00-438f-446e-90e9-3f8d6c3f8775.mp4

</div>

The module provides you with the ability to set the console title from a background thread. Unlike the prompt string, it can show information without blocking or being blocked by the main thread.

## Requirements

This module has been tested on:

- Windows 10, Windows 11 and Ubuntu 20.04
- Windows PowerShell 5.1 and PowerShell 7.3

## Installation

*DynamicTitle* is available on the PowerShell Gallery. You can install the module with the following command:

```powershell
Install-Module -Name DynamicTitle -Scope CurrentUser
```

## Basic Usage

This one-liner shows a live-updating clock on the title bar. The specified ScriptBlock is called periodically at a certain interval on a background thread. The module sets the console title to the string that is returned by the ScriptBlock.

```powershell
Start-DTTitle {Get-Date}
```

![dt_clock](https://user-images.githubusercontent.com/81177095/224546336-b7ecc18f-31b6-4a9b-9688-22e0da81d266.gif)

If an array is returned from the script block, they are shown with a vertical scrolling.

```powershell
Start-DTTitle {'🌷 Hello', '🌼 World'}
```

![dt_vertical_scroll](https://user-images.githubusercontent.com/81177095/224547384-37f69aaf-0089-49f6-9728-589679142206.gif)

If the title width is fixed by your terminal app or you want to limit the width, you can specify `HorizontalScrollFrameWidth` parameter. The title text Horizontally scrolls when its length is longer than the parameter.

```powershell
Start-DTTitle {
    '🍷 Showing a long text as a title 🍸'
} -HorizontalScrollFrameWidth 25
```

![dt_horizontal_scroll](https://user-images.githubusercontent.com/81177095/224547683-9c417aa6-689f-403f-809f-ea2c4e696b63.gif)

## Jobs

Although the ScriptBlock specified to `Start-DTTitle` runs on another thread to avoid blocking, sometimes you need to get information from the main thread such as Current Directory, or you might need another thread to get some information that takes long time to process. For this purpose, the module provides you with three types of job objects. In either case, you can get the job output in a thread-safe way like this:

```powershell
$output = Get-DTJobLatestOutput $job
```

### CommandPreExecutionCallback Job

With this job, you can register a ScriptBlock that is called right before the command entered on the console is executed. The command string is passed as `$args[0]`. This job is useful to get the command running on the main thread or the command start time.

```powershell
$job = Start-DTJobCommandPreExecutionCallback -ScriptBlock {
    param($command)
    $command, (Get-Date)
}

Start-DTTitle {
    param($job)
    $commandString, $commandStartDate = Get-DTJobLatestOutput $job
    # ...
} -ArgumentList $job
```

### PromptCallback Job

PromptCallback job registers a ScriptBlock that is called right before the Prompt function is called. This job can be used to get the current directory for example.

```powershell
$job = Start-DTJobPromptCallback -ScriptBlock {Get-Location}

Start-DTTitle {
    param($job)
    $currentDirectory = Get-DTJobLatestOutput $job
    # ...
} -ArgumentList $job
```

### BackgroundThreadTimer Job

BackgroundTimerJob starts a new thread and calls a ScriptBlock periodically at the specified interval on the thread. It is good for tasks that take long time to finish so as not to block the title update thread.

```powershell
$job = Start-DTJobBackgroundThreadTimer -ScriptBlock {
    # Get weather
    Invoke-RestMethod https://wttr.in/?format="%c%t\n"
} -IntervalMilliseconds 60000

Start-DTTitle {
    param($job)
    $weather = Get-DTJobLatestOutput $job
    # ...
} -ArgumentList $job
```

## Legacy Application Mode

When command line applications are executed on the main thread, the host saves the title string before calling the application and resets it when the application returns. This behavior sometimes causes a blink on the title as you are changing the title on a background thread.

`Enter-DTLegacyApplicationMode` calls `$host.NotifyBeginApplication()` to notify the host that the subsequent commands are all legacy command line applications, and therefore the title reset behavior on every command call is suppressed. Note that this workaround stops all the state restore from the command line applications which may cause some other issues.

```powershell
Start-DTTitle {Get-Date}
Enter-DTLegacyApplicationMode
# Calling command line applications here does not cause a blink on the title.
git status -s
# ...
Exit-DTLegacyApplicationMode
# This call causes a blink.
git status -s
```

## Terminal Settings Recommendations

- If you are using Windows Terminal, there is a setting called `Tab width mode`. Setting it to `Title length` or `Compact` should be better for longer titles.

- [Hyper](https://github.com/vercel/hyper) terminal allows you to change the appearance of the title by css, such as font and size. It's a good fit for this module if you want the title to stand out or want to use special emojis.

## Help and more Examples

`Get-Command` can list all the available functions in the module:

```powershell
Get-Command -Module DynamicTitle
```

To get the detailed help of a function, please try:

```powershell
Get-Help Start-DTTitle -Full
```

For more code examples, please see the scripts under [Examples](./Examples) folder.
