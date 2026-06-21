# Kanata Integration

OverKeys provides integration with [Kanata](https://github.com/jtroo/kanata), allowing you to visualize active keyboard layers when using Kanata's keyboard remapping functionality.

## What is Kanata?

Kanata is a keyboard remapper that supports advanced features like layers, tap-hold, and leader keys. The integration between OverKeys and Kanata enables OverKeys to display the active layer from Kanata, making it easier to visualize which keys are available in your current layer.

### OverKeys with Kanata Integration Demos

<https://github.com/user-attachments/assets/5e7878d8-b51d-447d-946d-6ffeb063701c>

<https://github.com/user-attachments/assets/c687a448-52b0-41bc-9b6b-07e61c2d3b31>

## Setup Instructions

### Configuring OverKeys

1. Right-click the OverKeys icon in the system tray or macOS menu bar
2. Select **Preferences**
3. Go to the **Advanced** tab
4. Toggle the **Turn on advanced settings** option
5. Toggle the **Connect to Kanata** option
6. Click **Open** next to **Open config file** to edit the configuration file
7. Modify the `overkeys_config.json` file:

   ```json
   {
       "kanataHost": "127.0.0.1",
       "kanataPort": 4039,
       "userLayouts": [...],
       "defaultUserLayout": "Colemak"
   }
   ```

8. Save the file
9. Right-click the OverKeys icon in the system tray or macOS menu bar, then click **Reload config** to apply changes

### Configuring Kanata

When running Kanata, use the `-p` flag to enable TCP communication. On Windows:

```pwsh
kanata.exe -p 127.0.0.1:4039
```

If your macOS or Linux Kanata build supports TCP layer-change messages, run:

```bash
kanata -p 127.0.0.1:4039
```

On Windows, create a shortcut for `kanata_gui.exe` if you want Kanata to start
automatically:

1. Right-click > Create Shortcut
2. Edit the shortcut properties
3. Add `-p 127.0.0.1:4039` to the target field
4. Place the shortcut in your Windows Startup folder

> **Note**: Windows `kanata_gui.exe` with LLHOOK is the tested setup.
> Other Kanata builds must support TCP layer-change messages.

## Adding Kanata Layers

To display your Kanata layers in OverKeys, you need to configure them in the `userLayouts` section of your configuration file:

```json
"userLayouts": [
   {
      "name": "Colemak",
      "keys": [
      ["`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", "BSPC"],
      ["Q", "W", "F", "P", "G", "J", "L", "U", "Y", ";", "[", "]"],
      ["A", "R", "S", "T", "D", "H", "N", "E", "I", "O", "'"],
      ["Z", "X", "C", "V", "B", "K", "M", ",", ".", "/"],
      [" "]
      ]
   },
   {
      "name": "Symbol",
      "keys": [
         ["`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", "BSPC"],
         ["'", "<", ">", ":", "@", "~", "\"", "{", "}", "%", "[", "]"],
         ["!", "-", "+", "=", "`", "|", ".", "(", ")", "?", "'"],
         ["^", "/", "*", "_", "\\", "&", "$", "[", "]", "#"],
         [" "]
      ]
   },
   {
      "name": "Extend",
      "keys": [
         ["`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", "BSPC"],
         ["UNDO", "CUT", "COPY", "PASTE", "FIND", "DEV", "⇤", "↑", "⇥", "", "", ""],
         ["1", "2", "3", "4", "5", "⤒", "←", "↓", "→", "⤓", ""],
         ["6", "7", "8", "9", "0", "", "", "", "", ""],
         [" "]
      ]
   }
]
```

## How It Works

When configured properly:

1. Start both OverKeys and Kanata (recommended to start OverKeys first)
2. OverKeys will automatically detect layer changes in Kanata
3. When you switch layers in Kanata, OverKeys will update to show the active layer

<https://github.com/user-attachments/assets/ab50455d-52e4-44b5-a409-c90f1e07c15b>

## Implementation Notes

- The Kanata integration works across all configured layers
- Layer visualization is immediate when switching with Kanata shortcuts
- When you switch to a layer other than your default/base layer (defined by `defaultUserLayout`), OverKeys will temporarily suspend its auto-hide feature, keeping the non-default layer visible for easier reference

## Troubleshooting

- If layer switching doesn't work, ensure both applications are running
- Check that they're using the same host and port
- Verify your layer configurations in `overkeys_config.json` have no errors
- Try disabling and re-enabling the Kanata integration toggle in Preferences
