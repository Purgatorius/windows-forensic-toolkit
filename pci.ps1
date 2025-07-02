# pci.ps1 - Password Check + Report + PIN/Policy Info

# === STARTUP BEEP + BANNER ===
[console]::beep(800, 600)
Start-Sleep -Milliseconds 200
[console]::beep(800, 150)
Start-Sleep -Milliseconds 100
[console]::beep(800, 150)
Start-Sleep -Milliseconds 100
[console]::beep(800, 150)

$banner = @'

  _____                                                      _    _____   _                     _    
 |  __ \                                                    | |  / ____| | |                   | |   
 | |__) |   __ _   ___   ___  __      __   ___    _ __    __| | | |      | |__     ___    ___  | | __
 |  ___/   / _` | / __| / __| \ \ /\ / /  / _ \  | '__|  / _` | | |      | '_ \   / _ \  / __| | |/ /
 | |      | (_| | \__ \ \__ \  \ V  V /  | (_) | | |    | (_| | | |____  | | | | |  __/ | (__  |   < 
 |_|       \__,_| |___/ |___/   \_/\_/    \___/  |_|     \__,_|  \_____| |_| |_|  \___|  \___| |_|\_\
                                                                                     created by bbug93

'@

Write-Host $banner -ForegroundColor Cyan

# === DLL IMPORT: LOGONUSER ===
Add-Type -AssemblyName System.Runtime.InteropServices
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class LogonTest {
    [DllImport("advapi32.dll", SetLastError=true)]
    public static extern bool LogonUser(
        string lpszUsername,
        string lpszDomain,
        string lpszPassword,
        int dwLogonType,
        int dwLogonProvider,
        out IntPtr phToken);
}
"@

# === INPUT ===
$Username = Read-Host "User: "
[console]::beep(800, 150)
$Domain = Read-Host "Domain: (or leave empty for local account)"
[console]::beep(800, 150)
if ([string]::IsNullOrWhiteSpace($Domain)) { $Domain = "." }
$Password = Read-Host "Password for check: "
[console]::beep(800, 150)
$DeviceID = Read-Host "Device ID"
[console]::beep(800, 150)
Start-Sleep -Milliseconds 1000

function Show-ProgressBar($message, $delay = 30) {
    Write-Host "`n$message"
    for ($i = 1; $i -le 100; $i++) {
        $progressBar = "=" * ($i / 2)
        $spaces = " " * (50 - ($i / 2))
        $percent = "{0,3}" -f $i
        Write-Host -NoNewline "`r[$progressBar$spaces] $percent%"
        Start-Sleep -Milliseconds $delay
    }
    Write-Host ""
}

# === PIN DETECTION ===
function Check-WindowsHelloPIN {
    param ($Username)

    try {
        $userSID = (Get-CimInstance Win32_UserAccount | Where-Object { $_.Name -eq $Username }).SID
        if (!$userSID) {
            return "[-] Nie znaleziono profilu użytkownika. Nie można sprawdzić PIN-u."
        }

        $ngcPath = "C:\Windows\ServiceProfiles\LocalService\AppData\Local\Microsoft\NGC"
        if (Test-Path $ngcPath) {
            return "[*] PIN (Windows Hello) probably configured. I am not sure."
        } else {
            return "[*] Brak konfiguracji PIN / Windows Hello."
        }
    } catch {
        return "[-] Błąd przy sprawdzaniu PIN: $_"
    }
}

# === POLITYKA HASEŁ ===
function Show-PasswordPolicySummary {
    try {
        $threshold = (net accounts) -match "Lockout threshold" | ForEach-Object { ($_ -split ":")[1].Trim() }
        $duration  = (net accounts) -match "Lockout duration" | ForEach-Object { ($_ -split ":")[1].Trim() }

        if ($threshold -eq "0") {
            return "[*] Password Policy: Account Blocker is DISABLED."
        } else {
            return "[*]  Password Policy: Account will be blocked after $threshold wrong tries. Block Time: $duration minutes."
        }
    } catch {
        return "[-] Cant take Password Policy: $_"
    }
}

# === INFORMACJE DODATKOWE ===
Write-Host "`nChecking PIN configuration..." -ForegroundColor Yellow
$pinStatus = Check-WindowsHelloPIN -Username $Username
Write-Host $pinStatus

Write-Host "`nChecking password policy..." -ForegroundColor Yellow
$policySummary = Show-PasswordPolicySummary
Write-Host $policySummary

# === POŁĄCZENIE I WALIDACJA ===
[console]::beep(800, 150)
Show-ProgressBar "Connecting to Windows API via PowerShell..." 20
[console]::beep(800, 150)
Write-Host "Connection Established.`n" -ForegroundColor Cyan
Start-Sleep -Milliseconds 1000

Show-ProgressBar "Checking Password..." 2
[console]::beep(800, 150)
Write-Host "Done." -ForegroundColor Cyan

$token = [IntPtr]::Zero
$logonType = 2
$logonProvider = 0
$result = [LogonTest]::LogonUser($Username, $Domain, $Password, $logonType, $logonProvider, [ref]$token)

# === RAPORT ===
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
$scriptPath = $MyInvocation.MyCommand.Path
$usbRoot = Split-Path -Parent $scriptPath
$outputDir = Join-Path $usbRoot "$DeviceID-password_check-$timestamp"
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
$outputFile = Join-Path $outputDir "$DeviceID-password_check-$timestamp.txt"

$report = @()
$report += "==== PASSWORD CHECK REPORT ===="
$report += "Timestamp : $timestamp"
$report += "Device ID : $DeviceID"
$report += "Username  : $Username"
$report += "Domain    : $Domain"
$report += "Password  : $Password"
$report += ""

if ($result) {
    $report += "[+] RESULT: Password is CORRECT."
    Write-Host "`nPassword is CORRECT." -ForegroundColor Green
    Write-Host "`nUser: $Username" -ForegroundColor Magenta
    Write-Host "Password: $Password" -ForegroundColor Magenta
    [console]::beep(800, 150)
    [console]::beep(800, 150)
} else {
    $errorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
    $report += "[-] RESULT: Password is WRONG (Error code: $errorCode)"
    Write-Host "`nPassword is !!! W_R_O_N_G !!! (Error code: $errorCode)" -ForegroundColor Red
    [console]::beep(800, 3650)
}

# === DODATKOWE INFO DO RAPORTU ===
$report += "`n==== ADDITIONAL INFO ===="
$report += $pinStatus
$report += $policySummary

$report | Out-File -FilePath $outputFile -Encoding UTF8
Write-Host "`nReport saved to: $outputFile" -ForegroundColor Cyan
