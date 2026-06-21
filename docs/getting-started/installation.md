# Installation

This guide walks through installing OverKeys on Windows and building the macOS
app bundle from source.

## Methods

### 1. Using Winget (Recommended)

The recommended installation method is using Windows Package Manager (winget), as it enables automatic updates:

```powershell
winget install AngeloConvento.OverKeys
```

### 2. Using EXE Installer

If you prefer manual installation:

1. Download the latest [EXE installer](https://github.com/conventoangelo/OverKeys/releases) from the official GitHub releases page
2. Run the installer and follow the on-screen instructions
3. Once installed, OverKeys will be available for use

### 3. Using ZIP file

For a portable version without installation:

1. Download the [portable ZIP file](https://github.com/conventoangelo/OverKeys/releases) from the GitHub releases page
2. Extract the ZIP file to any location of your choice
3. Run `OverKeys.exe` from the extracted folder

### 4. Building the macOS App Bundle

The macOS app can be built from source:

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
listen for global key events.

## First Launch

After installation:

1. OverKeys will launch automatically
2. The application will appear in your system tray or macOS menu bar
3. Right-click the OverKeys icon to access preferences and configuration options

## Updating OverKeys

### For Winget Installations

To update OverKeys when installed via winget:

```powershell
winget upgrade AngeloConvento.OverKeys
```

### For Manual Installations

Download and run the latest installer from the [GitHub releases page](https://github.com/conventoangelo/OverKeys/releases).
