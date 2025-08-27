# ==================================================================
# Stalker 2 Save Sync: Xbox → Steam
# PowerShell 5.1+ / 7.x
# ==================================================================

param(
    # How many recent backups to keep
    [int]$KeepCount = 5
)

# ------------------------------
# Check for running processes: steam.exe, steamwebhelper.exe, Stalker2.exe, Stalker2-Win64-Shipping.exe
# ------------------------------
$processesToCheck = @("steam", "steamwebhelper", "Stalker2", "Stalker2-Win64-Shipping")
$runningProcesses = Get-Process | Where-Object { $processesToCheck -contains $_.ProcessName }

if ($runningProcesses) {
    Write-Host "Please close Steam and Stalker 2 before running this script."
    exit 1
}


# ------------------------------
# Path settings
# ------------------------------
$UserName       = $env:USERNAME
$SteamSavePath  = "$env:LOCALAPPDATA\Stalker2\Saved\STEAM\SaveGames"
$BackupRoot     = "C:\Users\$UserName\SavesBackup\SteamStalker2"

# Xbox folder with various GUIDs inside
$XboxRoot       = "$env:LOCALAPPDATA\Packages\GSCGameWorld.S.T.A.L.K.E.R.2HeartofChernobyl_6fr1t1rwfarwt\SystemAppData\xgs"

# ------------------------------
# Create new folder with timestamp
# ------------------------------
$TimeStamp      = Get-Date -Format "yyMMdd-HHmmss"
$NewBackupPath  = Join-Path $BackupRoot $TimeStamp

# ------------------------------
# 1. Rotate Steam save backups
# ------------------------------
if (!(Test-Path $BackupRoot)) {
    New-Item -Path $BackupRoot -ItemType Directory | Out-Null
}

$existingBackups = Get-ChildItem -Path $BackupRoot -Directory |
    Sort-Object CreationTime -Descending

if ($existingBackups.Count -ge $KeepCount) {
    $toDelete = $existingBackups | Select-Object -Skip $KeepCount
    foreach ($folder in $toDelete) {
        Write-Host "Deleting old backup: $($folder.FullName)"
        Remove-Item -Path $folder.FullName -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# ------------------------------
# 2. Backup Steam saves + clean up
# ------------------------------
if (Test-Path $SteamSavePath) {
    Write-Host "Copying Steam saves to $NewBackupPath"
    Copy-Item -Path $SteamSavePath -Destination $NewBackupPath -Recurse

    Write-Host "Cleaning Steam saves folder"
    Remove-Item -Path "$SteamSavePath\*" -Recurse -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "Steam saves folder not found: $SteamSavePath"
}

# ------------------------------
# 3. Take saves from Xbox and put into Steam
# ------------------------------
if (Test-Path $XboxRoot) {
    # Find the newest subfolder (should contain SaveGames)
    $latestXboxFolder = Get-ChildItem -Path $XboxRoot -Directory |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($null -ne $latestXboxFolder) {
        $XboxSavePath = Join-Path $latestXboxFolder.FullName "SaveGames"
        if (Test-Path $XboxSavePath) {
            Write-Host "Copying saves from Xbox ($XboxSavePath) → Steam ($SteamSavePath)"
            if (!(Test-Path $SteamSavePath)) {
                New-Item -Path $SteamSavePath -ItemType Directory | Out-Null
            }
            Copy-Item -Path "$XboxSavePath\*" -Destination $SteamSavePath -Recurse -Force
        } else {
            Write-Host "No SaveGames in the newest Xbox folder"
        }
    } else {
        Write-Host "No folders found in $XboxRoot"
    }
} else {
    Write-Host "Xbox root not found: $XboxRoot"
}