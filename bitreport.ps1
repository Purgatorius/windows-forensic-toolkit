# bitreport.ps1 - BitLocker Volume Status Reporter

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
  ____    _   _     _____                                  _   
 |  _ \  (_) | |   |  __ \                                | |  
 | |_) |  _  | |_  | |__) |   ___   _ __     ___    _ __  | |_ 
 |  _ <  | | | __| |  _  /   / _ \ | '_ \   / _ \  | '__| | __|
 | |_) | | | | |_  | | \ \  |  __/ | |_) | | (_) | | |    | |_ 
 |____/  |_|  \__| |_|  \_\  \___| | .__/   \___/  |_|     \__|
                                   | |        created by bbug93                 
                                   |_|        
'@

function Show-ProgressBar($message, $delay = 30) {
    Write-Host "`n$message"
    for ($i = 1; $i -le 100; $i++) {
        $progressBar = "=" * ($i / 2)
        $spaces = " " * (50 - ($i / 2))
        $percent = "{0,3}" -f $i
        Write-Host -NoNewline "`r[$progressBar$spaces] $percent%"
        Start-Sleep -Milliseconds $delay
    }
    [console]::beep(800, 150)
    Write-Host ""
}

Write-Host $banner -ForegroundColor Cyan


# Get current timestamp
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm"

# Get device ID and sanitize
$DeviceID = Read-Host "Device ID (no slashes or special characters)"
[console]::beep(800, 150)  # Short tone 3
$DeviceIDfixed = $DeviceID -replace '[\\/:*?"<>|]', '_'
Start-Sleep -Milliseconds 1000

# Get path of script (assumed USB)
$scriptPath = $MyInvocation.MyCommand.Path
$usbRoot = Split-Path -Parent $scriptPath

# Create output folder
$outputDir = Join-Path $usbRoot "$DeviceIDfixed-bitlocker_report-$timestamp"
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

# Define report file
$outputFile = Join-Path $outputDir "$DeviceIDfixed-bitlocker_report-$timestamp.txt"

# Initialize report
$report = @()
$report += "==== BITLOCKER STATUS REPORT ===="
$report += "Timestamp : $timestamp"
$report += "Device ID : $DeviceID"
$report += ""

# Get list of all logical drives
$volumes = Get-BitLockerVolume

if ($volumes.Count -eq 0) {
    $report += "No BitLocker-compatible volumes found."
    Write-Host "No BitLocker-compatible volumes found." -ForegroundColor Yellow
} else {
    $volCount = $volumes.Count
    $i = 1
    foreach ($vol in $volumes) {
        Write-Host "`n[$i/$volCount] Analyzing volume: $($vol.MountPoint)" -ForegroundColor Green
        Show-ProgressBar -message "Analyzing..." -delay 10

        $drive = $vol.MountPoint
        $status = $vol.VolumeStatus
        $protection = $vol.ProtectionStatus
        $encryption = $vol.EncryptionMethod
        $lockStatus = $vol.LockStatus

        $report += "Drive: $drive"
        $report += "  Protection Status : $protection"
        $report += "  Volume Status     : $status"
        $report += "  Lock Status       : $lockStatus"
        $report += "  Encryption Method : $encryption"
        $report += "----------------------------------------"

        Write-Host "Drive: $drive"
        Write-Host "  Protection Status : $protection"
        Write-Host "  Volume Status     : $status"
        Write-Host "  Lock Status       : $lockStatus"
        Write-Host "  Encryption Method : $encryption"
        Write-Host "----------------------------------------"

        $i++
    }
}

# Save report
$report | Out-File -FilePath $outputFile -Encoding UTF8
Write-Host "`nReport saved to: $outputFile" -ForegroundColor Cyan
[console]::beep(800, 650)  # short tone 
[console]::beep(800, 150)  # short tone 
[console]::beep(800, 150)  # short tone 

