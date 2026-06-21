# Alternative Layouts

The alternative layout feature in OverKeys allows you to display two keyboard layouts side-by-side simultaneously. This is particularly useful for users who are:

- Learning a new keyboard layout or language
- Working with multiple languages regularly
- Comparing different layouts during transition
- Teaching or demonstrating keyboard layouts to others

## Overview

When enabled, OverKeys will display your primary layout with functional key highlighting alongside a secondary reference layout. Note that key press highlighting only works on the default layout; the alternative layout serves as a visual reference only.

![image](https://github.com/user-attachments/assets/5d324b70-f916-4356-8b71-f56b126e85a6)

## Setup Instructions

### Turning the setting on

1. Open OverKeys
2. Right-click the OverKeys icon in the system tray or macOS menu bar
3. Select **Preferences**
4. Go to the **General** tab
5. Toggle the **Enable advanced settings** option
6. Toggle the **Show alternative layout** option

### Using Configuration File

1. Right-click the OverKeys tray or menu bar icon
2. Select **Preferences**
3. Go to the **General** tab
4. Click **Open Config**
5. In the JSON file, set the `altLayout` field to your preferred alternative layout name:

    ```json
    {
        "altLayout": "MyAltLayout"
    }
    ```

6. Save the file
7. Right-click the tray or menu bar icon and click **Reload config** to apply changes

## Default Alternative Layouts

OverKeys no longer comes with default/pre-configured layouts. Instead, you can find sample alternative layouts in the example configuration file at [sample_config.json](../examples/sample_config.json), which includes:

- Arabic
- Russian

You can use these sample layouts or any of the built-in keyboard layouts as your alternative layout.

## Creating Custom Alternative Layouts

You can create custom alternative layouts by adding them to the `userLayouts` section in the configuration file:

```json
"userLayouts": [
    // other layouts here...
    {
        "name": "MyAltLayout",
        "keys": [
            ["`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", "BSPC"],
            ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "[", "]"],
            ["A", "S", "D", "F", "G", "H", "J", "K", "L", ";", "'"],
            ["Z", "X", "C", "V", "B", "N", "M", ",", ".", "/"],
            [" "]
        ]
    }
]
```

Then update the `altLayout` field to reference your custom layout:

```json
"altLayout": "MyAltLayout"
```

## Implementation Notes

- If you're using Kanata for layer switching, the alternative layout will remain visible across all layers.

## Troubleshooting

- If your custom alternative layout isn't displaying correctly, verify the JSON format in your configuration file.
- Remember that key press highlighting only works for the primary layout, not the alternative layout.
- When creating custom layouts, ensure the structure matches the expected format with arrays for each keyboard row.
