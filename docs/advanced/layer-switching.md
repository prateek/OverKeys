# Layer Switching

The layer switching feature in OverKeys allows you to switch between multiple custom keyboard layers, each with its own key arrangement and activation method. This is particularly useful when using keyboard firmware like QMK or ZMK, where you can configure the keyboard to have different layers.

While OverKeys doesn't directly communicate with QMK or ZMK (unlike its [Kanata integration](./kanata-integration.md)), you can still visualize different layers by configuring your keyboard firmware to send designated trigger keys (typically F13-F24) when switching layers.

For a more native layer switching experience and synchronization, consider using the [Kanata integration](./kanata-integration.md) instead.

## Setup Instructions

### Turning the setting on

1. Open OverKeys
2. Right-click the OverKeys icon in the system tray or macOS menu bar
3. Select **Preferences**
4. Go to the **Advanced** tab
5. Toggle the **Turn on advanced settings** option
6. Toggle the **Use user layouts** option

### Using Configuration File

1. Right-click the OverKeys icon in the system tray or macOS menu bar
2. Select **Preferences**
3. Go to the **Advanced** tab
4. Click **Open** next to **Open config file**
5. In the JSON file, edit the `userLayouts` array and set the `defaultUserLayout` field. Each layer must include:

   - `name`: Unique name for the layer
   - `keys`: The layout rows for this layer
   - `trigger`: The key used to activate this layer (usually F13–F24, or any key from [Supported Keys](./supported-keys.md))
   - `type`: Either `"held"` (layer is active while key is held) or `"toggle"` (press once to activate, again to deactivate)

    ```json
    {
        "userLayouts": [
            {
                "name": "Extend",
                "keys": [
                    ["`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", "BSPC"],
                    ["UNDO", "CUT", "COPY", "PASTE", "FIND", "DEV", "⇤", "↑", "⇥", "", "", ""],
                    ["1", "2", "3", "4", "5", "⤒", "←", "↓", "→", "⤓", ""],
                    ["6", "7", "8", "9", "0", "", "", "", "", ""],
                    [" "]
                ],
                "trigger": "F14",
                "type": "held"
            },
            {
                "name": "Symbol",
                "keys": [
                    ["`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", "BSPC"],
                    ["'", "<", ">", ":", "@", "~", "\"", "{", "}", "%", "[", "]"],
                    ["!", "-", "+", "=", "`", "|", ".", "(", ")", "?", "'"],
                    ["^", "/", "*", "_", "\\", "&", "$", "[", "]", "#"],
                    [" "]
                ],
                "trigger": "F15",
                "type": "toggle"
            }
        ],
        "defaultUserLayout": "QWERTY"
    }
    ```

   > **Note:** For best compatibility, use F13–F24 as triggers, or any key (not alias) listed in [Supported Keys](./supported-keys.md). The `type` field determines if the layer is active only while the trigger is held (`"held"`) or toggles on/off with each press (`"toggle"`).

6. Save the file
7. Right-click the OverKeys icon in the system tray or macOS menu bar, then click **Reload config** to apply changes

## Creating Custom Layers

You can add as many layers as you want to the `userLayouts` array. Each must have a unique `name`, a `keys` array, a `trigger`, and a `type`. Refer to [Custom Layouts](./custom-layouts.md) documentation when defining your layers.

## Format Guidelines

1. **Trigger**: The key that activates the layer. F13–F24 are recommended, but any supported key can be used.
2. **Type**: `"held"` for momentary layers, `"toggle"` for persistent layers.

## Implementation Notes

- User layers are loaded when OverKeys starts or when you toggle the setting.
- If a layer's `trigger` key is pressed, the corresponding layer will be activated according to its `type`.
- Best case scenario is if the key can be configured so that it could both send a layer change and the trigger key in one press, i.e., combo or macro.
- Layer change listening and Kanata integration cannot be used simultaneously.
- When using Kanata integration, the `trigger` and `type` fields in the layer configuration are ignored, as layer switching is controlled by Kanata.

## Troubleshooting

- Ensure each layer in `userLayouts` has a unique `name`.
- The `defaultUserLayout` must match one of the defined layer names or natively supported layouts.
- If layers do not appear or do not switch, verify that **Use user layouts** is enabled and your configuration is valid.
- Make sure your `trigger` key is not used by another application or system shortcut.
