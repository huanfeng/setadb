<#
.SYNOPSIS
    Select the ADB device for the current PowerShell session.

.DESCRIPTION
    Sets $env:ANDROID_SERIAL so that subsequent adb commands target one device.
    $env: writes go to the process environment block, so the change survives
    the script scope and stays visible for the rest of the session.

.EXAMPLE
    setadb            # show the menu and pick interactively
.EXAMPLE
    setadb 1          # pick menu entry 1 directly
.EXAMPLE
    setadb clear      # clear ANDROID_SERIAL (same as: setadb 0)
#>
# No param() block on purpose: with one declared, PowerShell's binder would
# treat '-h' / '-l' / '-s' as parameter names and fail. Scripts without
# declared parameters receive the command line verbatim in $args.
$Target = if ($args.Count -gt 0) { [string]$args[0] } else { '' }

$SetAdbVersion = '1.1.0'

function Show-SetAdbHelp {
    @"
setadb $SetAdbVersion - select the ADB device for the current session

Usage:
  setadb                 Show the device menu and select interactively
  setadb <index>         Select the device by menu index directly
  setadb 0               Same as 'setadb clear'
  setadb clear|-c        Clear ANDROID_SERIAL
  setadb <serial>        Set ANDROID_SERIAL to the given serial
  setadb list|-l         List devices without changing anything
  setadb -s              Show the current ANDROID_SERIAL
  setadb -h              Show this help

Notes:
  Only the current PowerShell session is affected. To call this as plain
  'setadb' in PowerShell, install a `$PROFILE function once:

      .\install-profile.ps1

  Without it, typing 'setadb' resolves to setadb.bat, which runs in a
  throw-away cmd.exe and has no effect. See the README for details.
"@
}

# Returns an ordered list of menu entries; index 0 is always the clear entry.
function Get-SetAdbDevices {
    $entries = @([pscustomobject]@{ Serial = ''; State = ''; Label = 'Clear' })

    $lines = & adb devices 2>$null
    foreach ($line in $lines) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        # Skip the header and the '* daemon not running *' chatter.
        if ($line -match '^List of devices') { continue }
        if ($line -match '^\*') { continue }

        $parts = $line -split '\s+', 2
        $serial = $parts[0].Trim()
        if ([string]::IsNullOrWhiteSpace($serial)) { continue }
        $state = if ($parts.Count -gt 1) { $parts[1].Trim() } else { '' }

        $entries += [pscustomobject]@{ Serial = $serial; State = $state; Label = $serial }
    }

    return , $entries
}

function Show-SetAdbMenu {
    param([array]$Entries)

    Write-Host 'ADB devices'
    Write-Host '-------------------'
    for ($i = 0; $i -lt $Entries.Count; $i++) {
        $e = $Entries[$i]
        $mark = if ($e.Serial -and $e.Serial -eq $env:ANDROID_SERIAL) { '*' } else { ' ' }
        $text = "$mark $i. [$($e.Label)]"
        if ($e.State) { $text += " $($e.State)" }
        Write-Host $text
    }
    Write-Host '-------------------'
}

function Set-SetAdbSerial {
    param([string]$Serial)

    if ([string]::IsNullOrEmpty($Serial)) {
        $env:ANDROID_SERIAL = $null
        Write-Host '[setadb] ANDROID_SERIAL cleared.'
    }
    else {
        $env:ANDROID_SERIAL = $Serial
        Write-Host "[setadb] ANDROID_SERIAL = $Serial"
    }
}

# --- argument handling ---------------------------------------------------

switch -Regex ($Target) {
    '^(-h|--help|help|/\?)$' { Show-SetAdbHelp; return }
    '^(-v|--version)$' { Write-Host "setadb $SetAdbVersion"; return }
    '^(-c|clear|--clear)$' { Set-SetAdbSerial ''; return }
    '^(-s|--show)$' {
        if ($env:ANDROID_SERIAL) {
            Write-Host "[setadb] ANDROID_SERIAL = $($env:ANDROID_SERIAL)"
        }
        else {
            Write-Host '[setadb] ANDROID_SERIAL is not set.'
        }
        return
    }
}

if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
    Write-Host "[setadb] Error: 'adb' was not found in PATH."
    return
}

$devices = Get-SetAdbDevices

if ($Target -match '^(-l|--list|list)$') {
    Show-SetAdbMenu $devices
    return
}

if ([string]::IsNullOrEmpty($Target)) {
    Show-SetAdbMenu $devices
    # Not $input - that name is a PowerShell automatic variable.
    $answer = Read-Host 'Please select'
    if ([string]::IsNullOrWhiteSpace($answer)) {
        Write-Host '[setadb] Cancelled, nothing changed.'
        return
    }
    if ($answer -notmatch '^\d+$') {
        Write-Host "[setadb] Invalid input: $answer"
        return
    }
    $Target = $answer
}

if ($Target -match '^\d+$') {
    $index = [int]$Target
    if ($index -ge $devices.Count) {
        Write-Host "[setadb] Index out of range: $index (valid: 0-$($devices.Count - 1))"
        return
    }
    Set-SetAdbSerial $devices[$index].Serial
    return
}

# Anything else is treated as a raw serial.
if (-not ($devices | Where-Object { $_.Serial -eq $Target })) {
    Write-Host "[setadb] Warning: '$Target' is not in the device list, setting it anyway."
}
Set-SetAdbSerial $Target
