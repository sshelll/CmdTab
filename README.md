# CmdTab

> An alternative for MacOS Cmd+Tab

A modern, customizable(in the future) application switcher for macOS that enhances the default Cmd+Tab experience with a sleek interface and powerful search capabilities.

## Demo

![Demo](artifacts/demo.gif)

## Features

- 🎨 **Modern UI** - Beautiful glassmorphism design with smooth animations
- 🔍 **Quick Search** - Press 'i', '/', or 'a' to search applications instantly
- ⌨️ **Keyboard Navigation** - Navigate with arrow keys, Tab, or Shift+Tab
- 🖱️ **Mouse Support** - Click to switch applications directly
- 🚀 **Fast & Lightweight** - Native Swift implementation for optimal performance
- 🎯 **Smart Filtering** - Quickly find and switch to any running application

## Installation

### Download From Release

Download the latest version from the [Release Page](https://github.com/sshelll/CmdTab/releases).

1. Download the `.dmg` file from the releases page
2. Open the `.dmg` file and drag CmdTab to your Applications folder
3. Open it, use finder or spotlight to locate CmdTab in your Applications folder
4. **Important**: Since this is a self-built application, macOS will prevent it from opening by default. To allow it:
   - Go to System Settings > Privacy & Security, find the message about CmdTab being blocked, and click "Open Anyway"
5. Grant necessary permissions when prompted (Accessibility permissions are required for the app to function properly)

### Homebrew

```sh
brew tap sshelll/tap git@github.com:sshelll/homebrew-tap.git
brew install --cask sshelll/tap/cmdtab
```

And then follow the step 4 and 5 above to allow and grant permissions.

## Usage

- Press `Cmd+Tab` to open the application switcher
- Use arrow keys or Tab to navigate between applications
- Press 'i', '/', or 'a' to activate search mode
- Press Enter to switch to the selected application
- Press Esc to close the switcher

## Requirements

- macOS 12.0 or later

## License

MIT License
