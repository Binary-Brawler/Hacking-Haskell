# Hacking-Haskell

## Windows GTK Installer Guide

The `Win-GTK-Installer.ps1` script automates the setup of a complete Haskell GUI development environment on Windows 10/11 using GTK4.

### What It Does

The script automatically installs and configures:

1. **Git** - Version control system (if not already installed)
2. **MSYS2** - Unix-like environment for Windows
3. **GTK Packages** - GTK3, GTK4, and related libraries via MSYS2
4. **Haskell Toolchain** - GHCup, GHC, and Cabal (if not already installed)
5. **Sample Project** - Creates a working GTK4 example project (`gi-gtk-test`)

### Prerequisites

- Windows 10 or Windows 11
- PowerShell (comes pre-installed on Windows)
- Administrator privileges (may be required for installations)
- Internet connection (for downloading installers and packages)

### How to Run

1. **Open PowerShell as Administrator** (Right-click PowerShell → "Run as Administrator")

2. **Navigate to the project directory**:
   ```powershell
   cd C:\Users\Hupport\Desktop\Workspace\Haskell\Hacking-Haskell
   ```

3. **Set execution policy** (if needed):
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

4. **Run the installer script**:
   ```powershell
   .\Win-GTK-Installer.ps1
   ```

5. **Confirm the installation** when prompted by the dialog box

### What to Expect

- The script will show a confirmation dialog before starting
- Installation progress will be displayed with colored output
- The script checks for existing installations and skips them if found
- MSYS2 installation may take several minutes
- After installation, the script creates a sample project and attempts to build/run it
- **Note**: The script includes a 20-second delay before running the project to allow Windows to update environment variables

### Troubleshooting

If the build fails:

1. Delete the `gi-gtk-test` directory
2. Reboot your computer (to ensure environment variables are loaded)
3. Re-run the script

### Manual Steps After Installation

After running the script, you may need to:

- **Restart your terminal** or **reboot** to ensure all environment variables are loaded
- Verify installation:
  ```powershell
  git --version
  cabal --version
  ```

### Project Structure

The script creates a sample project with the following structure:

```
gi-gtk-test/
├── app/
│   └── Main.hs          # Application entry point
├── src/
│   └── UI/
│       ├── MainWindow.hs    # Main window UI
│       ├── StatusPage.hs    # Status page component
│       ├── Shared.hs        # Shared UI functions
│       └── Layout.hs        # Layout utilities
└── gi-gtk-test.cabal    # Cabal project file
```

### Running the Sample Project

After installation, navigate to the project directory and run:

```powershell
cd gi-gtk-test
cabal run gi-gtk-test
```

This will build and launch a simple GTK4 window with a button that opens a status page when clicked.