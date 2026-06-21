# Shift Mappings

The custom shift mappings feature in OverKeys allows you to define your own shift-key behavior for specific characters.

## Overview

<https://github.com/user-attachments/assets/93ab7a80-5ccf-4404-87c0-952bd61378b5>

When you press Shift plus a key, the keyboard typically produces an alternate symbol. OverKeys lets you customize these shift mappings, overriding the default system behavior for specific keys in your layouts.

## Setup Instructions

### Using Configuration File

1. Right-click the OverKeys tray or menu bar icon
2. Select **Preferences**
3. Go to the **Advanced** tab
4. Click **Open** in the **Open config file** row
5. In the JSON file, add or modify the `customShiftMappings` object:

    ```jsonc
    {
        "customShiftMappings": {
            "[": "{",
            "]": "}",
            "1": "!",
            "2": "@",
            "-": "_"
        }
    }
    ```

6. Save the file
7. Right-click the tray or menu bar icon and click **Reload config** to apply changes

## Default Shift Mappings

OverKeys includes the following default shift mappings:

| Key     | Shifted Key | Description                  |
| ------- | ----------- | ---------------------------- |
| `` ` `` | `~`         | Backtick → Tilde             |
| `1`     | `!`         | Number 1 → Exclamation Mark  |
| `2`     | `@`         | Number 2 → At Symbol         |
| `3`     | `#`         | Number 3 → Hash/Pound        |
| `4`     | `$`         | Number 4 → Dollar Sign       |
| `5`     | `%`         | Number 5 → Percent           |
| `6`     | `^`         | Number 6 → Caret             |
| `7`     | `&`         | Number 7 → Ampersand         |
| `8`     | `*`         | Number 8 → Asterisk          |
| `9`     | `(`         | Number 9 → Left Parenthesis  |
| `0`     | `)`         | Number 0 → Right Parenthesis |
| `-`     | `_`         | Hyphen → Underscore          |
| `=`     | `+`         | Equals → Plus                |
| `[`     | `{`         | Left Bracket → Left Brace    |
| `]`     | `}`         | Right Bracket → Right Brace  |
| `\`     | `\|`        | Backslash → Pipe             |
| `;`     | `:`         | Semicolon → Colon            |
| `'`     | `"`         | Apostrophe → Quote           |
| `,`     | `<`         | Comma → Less Than            |
| `.`     | `>`         | Period → Greater Than        |
| `/`     | `?`         | Slash → Question Mark        |

These mappings are applied automatically unless overridden by custom mappings.

## Creating Custom Shift Mappings

You can create custom shift mappings by adding key-value pairs to the `customShiftMappings` section in your configuration file:

```json
"customShiftMappings": {
    "key": "shifted-value",
    "another-key": "another-shifted-value"
}
```

Examples:

```json
"customShiftMappings": {
    "A": "Æ",
    "O": "Ø",
    "9": "(",
    "0": ")",
    "/": "|"
}
```

This would override the default shift behavior for these keys, so when pressing Shift+A, "Æ" would be displayed instead of "A".
Note that when you apply custom shift mappings, the press state of the mapped key is separate from the remapped character. For example, if you remap Shift+A to "Æ", when you press Shift+A, the visual representation will show "Æ" but since this is not recognized by OverKeys, it would not be in a pressed state.

## Implementation Notes

- Custom shift mappings only affect the visual representation in OverKeys, not the actual keyboard input/logic. For locale-specific shift mappings that dwell with key logic, refer to the [Locales](../advanced/locales.md) documentation instead
- The mappings are applied globally across all layouts, including custom and alternative layouts.
- For modifier keys and function keys, shift mappings typically have no effect.

## Troubleshooting

- If your custom shift mappings aren't displaying correctly, verify the JSON format in your configuration file.
- Remember that these mappings only affect the visual display in OverKeys, not the actual key input behavior of your system.
- If a key doesn't appear to have a custom shift mapping applied, check that the key name in your mapping exactly matches the key name in your layout.
