function ShowMenuItem {
    param([string]$item)
    Write-Host "$global:IDX. [$item]"
    Set-Variable -Name "global:DEVICE_$global:IDX" -Value $item
    $global:IDX++
}

function SetDevice {
    param([string]$device)
    $env:ANDROID_SERIAL = $device
}

Write-Host "ADB devices"
Write-Host "-------------------"

$global:IDX = 0
ShowMenuItem "Clear"

$adbDevices = adb devices | Select-Object -Skip 1 | Where-Object { $_ -match '^\S+' } | ForEach-Object { ($_ -split '\s+')[0] }
$adbDevices | ForEach-Object {
    ShowMenuItem $_
}

Write-Host "-------------------"

Write-Host -NoNewline "Please select: "
$ID = Read-Host
if ($ID -eq "0") {
    $env:ANDROID_SERIAL = ""
}
elseif ($ID -lt $global:IDX) {
    $device = (Get-Variable -Name "DEVICE_$ID").Value
    SetDevice $device
}
else {
    Write-Host "No Select!"
}
