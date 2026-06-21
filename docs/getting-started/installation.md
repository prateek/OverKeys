# Installation

Install OverKeys from a Windows release build, or build the macOS app bundle
from source.

## Methods

### 1. Using Winget (Recommended for Windows)

Use Windows Package Manager (winget) to get automatic updates:

```powershell
winget install AngeloConvento.OverKeys
```

### 2. Using the Windows EXE Installer

If you prefer manual installation:

1. Download the latest [EXE installer](https://github.com/conventoangelo/OverKeys/releases) from the official GitHub releases page
2. Run the installer and follow the on-screen instructions
3. Launch OverKeys after installation

### 3. Using the Windows ZIP File

For a portable version without installation:

1. Download the [portable ZIP file](https://github.com/conventoangelo/OverKeys/releases) from the GitHub releases page
2. Extract the ZIP file to any folder
3. Run `OverKeys.exe` from the extracted folder

### 4. Building the macOS App Bundle

Build the macOS app from source with Flutter 3.44.2:

```bash
flutter pub get
flutter build macos --debug
open build/macos/Build/Products/Debug/OverKeys.app
```

For a local release bundle:

```bash
flutter build macos --release
open build/macos/Build/Products/Release/OverKeys.app
```

On first launch, macOS prompts for Input Monitoring permission so OverKeys can
listen for global key events. If you grant permission after OverKeys is already
running, quit and reopen it.

## First Launch

After starting OverKeys:

1. Windows installer builds may launch automatically after installation. Portable ZIP and macOS source builds start when you open the app manually.
2. The OverKeys icon appears in the Windows system tray or macOS menu bar.
3. Right-click the OverKeys icon to open preferences and configuration options.

## Updating OverKeys

### For Winget Installations

To update OverKeys when installed via winget:

```powershell
winget upgrade AngeloConvento.OverKeys
```

### For Windows Installer or ZIP Installations

Download the latest installer or ZIP from the [GitHub releases page](https://github.com/conventoangelo/OverKeys/releases).

### For macOS Source Builds

Pull the latest source, then rebuild the app bundle.
