<div align="center">

# DynamicTitle

[![GitHub license](https://img.shields.io/github/license/mdgrs-mei/DynamicTitle)](https://github.com/mdgrs-mei/DynamicTitle/blob/main/LICENSE)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/p/DynamicTitle)](https://www.powershellgallery.com/packages/DynamicTitle)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/DynamicTitle)](https://www.powershellgallery.com/packages/DynamicTitle)

[![Pester Test](https://github.com/mdgrs-mei/DynamicTitle/actions/workflows/pester-test.yml/badge.svg)](https://github.com/mdgrs-mei/DynamicTitle/actions/workflows/pester-test.yml)
    
[![Hashnode](https://img.shields.io/badge/Hashnode-2962FF?style=for-the-badge&logo=hashnode&logoColor=white)](https://mdgrs.hashnode.dev/building-your-own-terminal-status-bar-in-powershell)

*DynamicTitle* is a PowerShell module for advanced console title customizations.

![DynamicTitle](https://github.com/mdgrs-mei/DynamicTitle/assets/81177095/e606e65b-6a42-4e0c-987a-4df3e2f412f3)

</div>

The module provides you with the ability to set the console title from a background thread. Unlike the prompt string, it can show information without blocking or being blocked by the main thread.

## Requirements

This module has been tested on:

- Windows 10, Windows 11, Ubuntu 20.04 and macOS
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
![LiveClock](https://github.com/mdgrs-mei/DynamicTitle/assets/81177095/048aa512-a654-40e9-8187-2d2018eff9b9)

If an array is returned from the script block, they are shown with a vertical scrolling.

```powershell
Start-DTTitle {'🌷 Hello', '🌼 World'}
```

![VerticalScroll](https://github.com/mdgrs-mei/DynamicTitle/assets/81177095/d48edd3a-5063-48e4-a231-5a1d80ea5489)

If the title width is fixed by your terminal app or you want to limit the width, you can specify `HorizontalScrollFrameWidth` parameter. The title text Horizontally scrolls when its length is longer than the parameter.

```powershell
Start-DTTitle {
    '🍷 Showing a long text as a title 🍸'
} -HorizontalScrollFrameWidth 25
```

![HorizontalScroll](https://github.com/mdgrs-mei/DynamicTitle/assets/81177095/375bf799-6db3-4fd6-a2a0-4313335a9fe7)

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

## Examples

Examples are included in the module. You can play an example DynamicTitle with `Start-DTExample` function. The tab completion for the `Name` parameter helps you find available examples.

```powershell
Start-DTExample -Name CommandExecutionTime
```

`Get-DTExamplesPath` returns the path where the example scripts are stored.

```powershell
PS D:\> Get-ChildItem (Get-DTExamplesPath)

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a---           3/26/2023  1:56 PM           4095 AllInOne.ps1
-a---           3/26/2023  1:56 PM           1810 CommandExecutionTime.ps1
-a---           3/26/2023  1:56 PM           1956 GitStatus.ps1
-a---           3/26/2023  1:56 PM           1512 StatusBar.ps1
```

## Get-Help

`Get-Command` can list all the available functions in the module:

```powershell
Get-Command -Module DynamicTitle
```

To get the detailed help of a function, try:

```powershell
Get-Help Start-DTTitle -Full
```

## Changelog

Changelog is available [here](https://github.com/mdgrs-mei/DynamicTitle/blob/main/CHANGELOG.md).
