# 🎮 Epic Librarian

[![PowerShell](https://img.shields.io/badge/PowerShell-7%2B-blue?logo=powershell&logoColor=white)](https://learn.microsoft.com/powershell/)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%2F11-lightgrey?logo=windows&logoColor=white)](https://www.microsoft.com/windows)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-green?logo=gnu&logoColor=white)](https://www.gnu.org/licenses/gpl-3.0)

**Epic Librarian** is a PowerShell 7 utility designed to **move Epic Games installations between drives** while keeping them playable through symbolic links.  
It helps free up space on your system drive without breaking your games, and now supports **two-way moves**:  
- From the default Epic Games folder to another drive.  
- From the secondary drive back to the original location.  

It was crafted with care by [José Luis Orihuela Conde](https://github.com/OrihuelaConde) and Microsoft Copilot, iteratively refined for stability, usability, and speed.

---

## ✨ Features

- **Automatic game detection** in both source and destination folders.
- **Two-way movement**: move to free space or restore to original location.
- **Symbolic link creation/removal** for seamless Epic Games Launcher recognition.
- **Size-based sorting** (largest games first).
- **Color-coded list**:  
  - Default location → normal color.  
  - Moved games → green.
- **Interactive menu** with numeric selection.
- **Spinner animation** during moves to indicate progress.
- **Safe operations**: confirmation prompts, duplicate checks, and error handling.

---

## 📂 Default Paths

- **Source (default Epic install)**:  
  `C:\Program Files (x86)\Epic Games`
- **Destination (secondary library)**:  
  `D:\Epic Games` *(can be changed in the script)*

---

## 🚀 Requirements

- **Windows 10/11**
- **PowerShell 7+**
- Run as **Administrator** (required for `mklink`).

---

## 🛠 Usage

1. Download `EpicLibrarian.ps1`.
2. Open **PowerShell 7** as Administrator.
3. Allow script execution for the session:
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   ```
4. Run the script:
   ```powershell
   .\EpicLibrarian.ps1
   ```
5. Select the game number from the list.  
   - Type `0` to exit.  
   - If the game is in the default folder, it will be moved to the destination and linked.  
   - If the game is in the destination, it will be restored to the default folder and the link removed.

---

## 📊 Workflow Diagram

```text
[ Epic Games Default Folder ]
          |
          |  (Move & Create Symlink)
          v
[ Secondary Drive Folder ]
          ^
          |  (Remove Symlink & Move Back)
          |
[ Epic Games Default Folder ]
```

---

## 📸 Example

```
Detected games (sorted by size):
1. Fortnite - 45.23 GB [Origin]
2. GTA V - 89.10 GB [Destination]
3. Rocket League - 12.45 GB [Origin]

Enter the number of the game to move (0 to exit):
```

---

## ⚠️ Notes

- Moving between drives will take time depending on game size and disk speed.
- Symbolic links require Administrator privileges.
- The script does **not** delete game data — it only moves and links.

---

## 🤝 Credits

- **José Luis Orihuela Conde** — Concept, testing, and iterative refinement.  
- **Microsoft Copilot** — Co-development, scripting, and documentation.
