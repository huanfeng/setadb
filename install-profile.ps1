<#
.SYNOPSIS
    Install a 'setadb' function into your PowerShell $PROFILE.

.DESCRIPTION
    In PowerShell, typing 'setadb' would resolve to setadb.bat, because
    PATHEXT ranks .BAT above .PS1. That runs the script in a throw-away
    cmd.exe, so ANDROID_SERIAL would be set in a process that dies right
    away - the change looks like it worked but silently does nothing.

    A function outranks every external command in PowerShell's lookup
    order, so defining one is what makes plain 'setadb' behave correctly.

.PARAMETER Uninstall
    Remove a previously installed block instead of adding one.

.EXAMPLE
    .\install-profile.ps1
.EXAMPLE
    .\install-profile.ps1 -Uninstall
#>
[CmdletBinding()]
param(
    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$target = Join-Path $scriptDir 'setadb.ps1'

if (-not (Test-Path $target)) {
    Write-Host "[setadb] Error: setadb.ps1 not found next to this script ($target)."
    exit 1
}

$beginMark = '# >>> setadb >>>'
$endMark = '# <<< setadb <<<'
$block = @"
$beginMark
function setadb { & "$target" @args }
$endMark
"@

$profilePath = $PROFILE.CurrentUserAllHosts
$profileDir = Split-Path -Parent $profilePath
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}
if (-not (Test-Path $profilePath)) {
    New-Item -ItemType File -Path $profilePath | Out-Null
}

$content = Get-Content -Path $profilePath -Raw
if ($null -eq $content) { $content = '' }

# Drop any previously installed block so this stays idempotent.
$pattern = [regex]::Escape($beginMark) + '.*?' + [regex]::Escape($endMark)
$stripped = [regex]::Replace($content, $pattern, '', 'Singleline')
$stripped = $stripped.TrimEnd()

if ($Uninstall) {
    if ($stripped -eq $content.TrimEnd()) {
        Write-Host "[setadb] Nothing to remove in $profilePath"
    }
    else {
        Set-Content -Path $profilePath -Value $stripped -Encoding UTF8
        Write-Host "[setadb] Removed the setadb function from $profilePath"
        Write-Host '[setadb] Restart PowerShell for it to take effect.'
    }
    return
}

$new = if ([string]::IsNullOrWhiteSpace($stripped)) { $block } else { "$stripped`r`n`r`n$block" }
Set-Content -Path $profilePath -Value $new -Encoding UTF8

Write-Host "[setadb] Installed the setadb function into:"
Write-Host "         $profilePath"
Write-Host "[setadb] It calls: $target"
Write-Host ''
Write-Host '[setadb] Activate it now with:'
Write-Host "             . `$PROFILE.CurrentUserAllHosts"
Write-Host '         or just open a new PowerShell window. Then run: setadb'
