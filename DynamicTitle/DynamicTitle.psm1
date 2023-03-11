
$private:privateScripts = @(Get-ChildItem $PSScriptRoot\Private\*.ps1 -Exclude _*)
$private:publicScripts = @(Get-ChildItem $PSScriptRoot\Public\*.ps1)
foreach ($private:script in ($privateScripts + $publicScripts))
{
    . $script.FullName
}

$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {Stop-DTTitle}

Export-ModuleMember -Function $publicScripts.BaseName
