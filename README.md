# Stalker 2 Save Sync Scripts

## Introduction

These scripts synchronize save game files between the **Steam** and  
**Xbox Game Pass** versions of *Stalker 2* on the same Windows machine.  
They create timestamped backups of your save files and maintain a rotation  
of recent backups to help prevent data loss.

## Requirements

- Windows 11  
- PowerShell 5.1 or 7.x  
- Both Steam and Xbox versions of *Stalker 2* installed on the same PC  
- Enough disk space (backups can grow large)  

## Backup Logic

Each script:

- Creates a backup of the target save files in a timestamped folder  
  under a designated backup directory.  
- Keeps only the most recent **N** backups (configurable with the `-KeepCount` parameter).
- Deletes older backups automatically.

Example backup paths:

- Steam saves: `C:\Users\<User>\SavesBackup\SteamStalker2\<YYMMDD-HHMMSS>`  
- Xbox saves:  `C:\Users\<User>\SavesBackup\XboxStalker2\<YYMMDD-HHMMSS>`  

## Script Descriptions

### XboxToSteam.ps1

- Backs up current Steam saves.  
- Clears the Steam save folder.  
- Copies the most recent Xbox saves (`xgs\<id>\SaveGames`) into the Steam save folder.

### SteamToXbox.ps1

- Backs up current Xbox saves.  
- Deletes only `container.*` files in the `wgs` folder (to avoid cloud overwriting).
- Clears the `xgs\<id>\SaveGames` folder.  
- Copies the Steam saves into the Xbox `xgs\<id>\SaveGames` folder.  

## Usage

Run scripts from PowerShell. Adjust `-KeepCount` to set how many backups to retain.

### Example: Xbox → Steam

```powershell
.\XboxToSteam.ps1 -KeepCount 5
```

- Keeps 5 most recent backups.

> [!IMPORTANT]  
> Close both Steam and Stalker 2 before running this script.

### Example: Steam → Xbox

```powershell
.\SteamToXbox.ps1 -KeepCount 5
```

- Keeps 5 most recent backups.

> [!IMPORTANT]  
> Run this while the Xbox version of Stalker 2 is running, before quitting
> the game, so the cloud sync service registers your new saves.

## Save File Flow


Steam SaveGames
       ↓
Xbox xgs SaveGames (used directly by the game)
       ↓
Xbox wgs containers (used by GamingServices for cloud sync)
       ↓
Cloud (Xbox Live)

| Location           | Purpose                                                 |
|--------------------|---------------------------------------------------------|
| Steam Save Path    | Standard save folder for Steam version.                 |
| Xbox xgs Save Path | Active save files used by the Xbox/Game Pass version.   |
| Xbox wgs Save Path | Container files managed by GamingServices for cloud sync|
| Cloud              | Xbox Live cloud storage synced across devices.          |

## Typical Paths (Stalker 2)

- Steam saves:

```text
%LOCALAPPDATA%\Stalker2\Saved\STEAM\SaveGames
```

- Xbox saves (xgs):

```text
%LOCALAPPDATA%\Packages\GSCGameWorld.S.T.A.L.K.E.R.2HeartofChernobyl_6fr1t1rwfarwt\SystemAppData\xgs\<ID>\SaveGames
```

- Xbox containers (wgs):

```text
%LOCALAPPDATA%\Packages\GSCGameWorld.S.T.A.L.K.E.R.2HeartofChernobyl_6fr1t1rwfarwt\SystemAppData\wgs\<GUID>\container.*
```

- Backup directories:

```text
C:\Users\<User>\SavesBackup\SteamStalker2\<YYMMDD-HHMMSS>
C:\Users\<User>\SavesBackup\XboxStalker2\<YYMMDD-HHMMSS>
```

## Warnings & Limitations

- Cloud synchronization can overwrite your changes if not careful.  
- Always follow the notes:  
  - XboxToSteam → close both Steam and Xbox version.  
  - SteamToXbox → run with Xbox version open, before exit.  
- Backups take a lot of disk space (game saves can be large).  
- Scripts do not automate launching/closing the game or disabling cloud sync.  
- Use at your own risk; manual save management always carries risk of corruption.

## Licensing Note

If you want to play and synchronize saves across **Steam**,
**Windows UWP Xbox version**, and the native **Xbox console version**
(Deluxe or Ultimate editions), you will need to purchase three
separate licenses: one for Steam, one for the UWP version on Windows, and
one for the Xbox console version.
Additionally, save files from Deluxe or Ultimate editions are not compatible
with the Standard edition of the game.
