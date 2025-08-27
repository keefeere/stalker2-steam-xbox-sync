# ==================================================================
# Stalker 2 Save Sync: Steam → Xbox
# PowerShell 5.1+ / 7.x
# ==================================================================

param(
    # How many recent backups to keep
    [int]$KeepCount = 5
)

# ------------------------------
# Check if Xbox version is running
# ------------------------------
$processName = "Stalker2-WinGDK-Shipping"
$running = Get-Process -Name $processName -ErrorAction SilentlyContinue

if (-not $running) {
    Write-Host "Please launch Stalker 2 (Xbox Game Pass version) and run this script BEFORE exiting the game."
    exit 1
}

# ------------------------------
# Path settings
# ------------------------------
$UserName       = $env:USERNAME
$SteamSavePath  = "$env:LOCALAPPDATA\Stalker2\Saved\STEAM\SaveGames"
$BackupRoot     = "C:\Users\$UserName\SavesBackup\XboxStalker2"

$XboxRoot       = "$env:LOCALAPPDATA\Packages\GSCGameWorld.S.T.A.L.K.E.R.2HeartofChernobyl_6fr1t1rwfarwt\SystemAppData\xgs"
$XboxWgs        = "$env:LOCALAPPDATA\Packages\GSCGameWorld.S.T.A.L.K.E.R.2HeartofChernobyl_6fr1t1rwfarwt\SystemAppData\wgs"

# ------------------------------
# Create new folder with timestamp
# ------------------------------
$TimeStamp      = Get-Date -Format "yyMMdd-HHmmss"
$NewBackupPath  = Join-Path $BackupRoot $TimeStamp

# ------------------------------
# 1. Rotate Xbox save backups
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
# 2. Backup Xbox saves
# ------------------------------
if (Test-Path $XboxRoot) {
    $latestXboxFolder = Get-ChildItem -Path $XboxRoot -Directory |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($null -ne $latestXboxFolder) {
        $XboxSavePath = Join-Path $latestXboxFolder.FullName "SaveGames"
        if (Test-Path $XboxSavePath) {
            Write-Host "Copying Xbox saves to $NewBackupPath"
            Copy-Item -Path $XboxSavePath -Destination $NewBackupPath -Recurse
        } else {
            Write-Host "No SaveGames in the newest Xbox folder"
        }
    } else {
        Write-Host "No folders found in $XboxRoot"
    }
} else {
    Write-Host "Xbox root not found: $XboxRoot"
}

# ------------------------------
# 3. Delete only container files in Xbox wgs and then SaveGames
# ------------------------------
if (Test-Path $XboxWgs) {
    $subFolders = Get-ChildItem -Path $XboxWgs -Directory -ErrorAction SilentlyContinue
    foreach ($folder in $subFolders) {
        $containerFiles = Get-ChildItem -Path $folder.FullName -Filter "container.*" -File -ErrorAction SilentlyContinue
        foreach ($file in $containerFiles) {
            Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
            Write-Host "Deleted container file: $($file.FullName)"
        }
    }
}

if ($null -ne $latestXboxFolder) {
    $XboxSavePath = Join-Path $latestXboxFolder.FullName "SaveGames"
    if (Test-Path $XboxSavePath) {
        Write-Host "Deleting Xbox SaveGames folder: $XboxSavePath"
        Remove-Item -Path $XboxSavePath -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# ------------------------------
# 4. Copy Steam saves → Xbox SaveGames
# ------------------------------
if ((Test-Path $SteamSavePath) -and ($null -ne $latestXboxFolder)) {
    $XboxSavePath = Join-Path $latestXboxFolder.FullName "SaveGames"
    if (!(Test-Path $XboxSavePath)) {
        New-Item -Path $XboxSavePath -ItemType Directory | Out-Null
    }
    Write-Host "Copying Steam saves ($SteamSavePath) → Xbox ($XboxSavePath)"
    Copy-Item -Path "$SteamSavePath\*" -Destination $XboxSavePath -Recurse -Force
} else {
    Write-Host "Steam saves not found or Xbox folder unavailable"
}