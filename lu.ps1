# Script to list local users and save the report on the same USB drive

# DOS-style startup melody (1 long + 3 short)
[console]::beep(800, 600)   # Long tone
Start-Sleep -Milliseconds 200
[console]::beep(800, 150)   # Short tone 1
Start-Sleep -Milliseconds 100
[console]::beep(800, 150)  # Short tone 2
Start-Sleep -Milliseconds 100
[console]::beep(800, 150)  # Short tone 3

# ASCII banner
$banner = @'
                                                
  _    _                       _        _         _                     
 | |  | |                     | |      (_)       | |                    
 | |  | |  ___    ___   _ __  | |       _   ___  | |_                   
 | |  | | / __|  / _ \ | '__| | |      | | / __| | __|                  
 | |__| | \__ \ |  __/ | |    | |____  | | \__ \ | |_                   
  \____/  |___/  \___| |_|    |______| |_| |___/  \__|                  
                                     created by bbug93
'@

Write-Host $banner -ForegroundColor Cyan


# Get current timestamp
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm"

# Get device id
$DeviceID = Read-Host "Device ID (do not use slashes or special characters)"
$DeviceIDfixed = $DeviceID -replace '[\\/:*?"<>|]', '_'  # Change DeviceID to be processed well via Windows Powershell

# Display session info with uptime
$sessionTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$computerName = $env:COMPUTERNAME
$userName = $env:USERNAME
$userDomain = $env:USERDOMAIN

$os = Get-CimInstance -ClassName Win32_OperatingSystem
$lastBoot = $os.LastBootUpTime
$uptime = (Get-Date) - $lastBoot

# Sformatuj uptime do czytelnej postaci
$uptimeFormatted = "{0}d {1}h {2}m" -f $uptime.Days, $uptime.Hours, $uptime.Minutes

[console]::beep(800, 150)  # Short tone 3
[console]::beep(800, 150)  # Short tone 3
Write-Host ""
Write-Host "===== SESSION INFO =====" -ForegroundColor Cyan
Write-Host "Time         : $sessionTime" -ForegroundColor Magenta
Write-Host "User         : $userName" -ForegroundColor Magenta
Write-Host "User (full)  : $userDomain\$userName" -ForegroundColor Magenta
Write-Host "Computer     : $computerName" -ForegroundColor Magenta
Write-Host "Uptime       : $uptimeFormatted" -ForegroundColor Magenta
Write-Host "=========================" -ForegroundColor Cyan
Write-Host ""
Start-Sleep -Milliseconds 2000
[console]::beep(800, 150)   # Short tone 1
Write-Host "Analyzing other accounts...1/3"
Start-Sleep -Milliseconds 200
[console]::beep(800, 150)   # Short tone 1
Write-Host "Analyzing other accounts...2/3"
Start-Sleep -Milliseconds 200
[console]::beep(800, 150)   # Short tone 1
Write-Host "Analyzing other accounts...3/3"
Write-Host ""
Start-Sleep -Milliseconds 2000

# Get the directory of this script (assumed to be on USB)
$scriptPath = $MyInvocation.MyCommand.Path
$usbRoot = Split-Path -Parent $scriptPath

# Create output folder on USB
$outputDir = Join-Path $usbRoot "$DeviceIDfixed-user_report-$timestamp"
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

# Define output file
$outputFile = Join-Path $outputDir "$DeviceIDfixed-user_report-$timestamp.txt"

# Initialize report
$report = @()
$report += "===== USER SESSION INFO ====="
$report += "Timestamp     : $sessionTime"
$report += "User          : $userName"
$report += "User (full)   : $userDomain\$userName"
$report += "Computer      : $computerName"
$report += "Uptime        : $uptimeFormatted"
$report += ""

# Collect info
$currentUser = whoami
$report += "=== Currently Logged-in User ==="
$report += "User: $currentUser"
$report += ""

# Header for local users
$report += "=== List of Local Windows Users ==="
$report += ""
$report += "{0,-20} {1,-10} {2,-20} {3}" -f "Username", "Enabled", "Last Logon", "Description"
$report += "-" * 80

Get-LocalUser | ForEach-Object {
    [console]::beep(800, 150)
    Write-Host "Account found: $($_.Name)"
    $report += "{0,-20} {1,-10} {2,-20} {3}" -f $_.Name, $_.Enabled, ($_.LastLogon -replace "T", " "), $_.Description
}

# Save report to file on USB
$report | Out-File -FilePath $outputFile -Encoding UTF8

# Optionally show success message
Start-Sleep -Milliseconds 1000
[console]::beep(800, 150)
Write-Host "`nProcess ended successfully"
Start-Sleep -Milliseconds 200
[console]::beep(800, 150)
Write-Host "`nReport saved to: $outputFile"

