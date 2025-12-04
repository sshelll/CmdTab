# CmdTab

> An alternative for MacOS Cmd+Tab

A modern, customizable(in the future) application switcher for macOS that enhances the default Cmd+Tab experience with a sleek interface and powerful search capabilities.

# Table of contents

- [CmdTab](#cmdtab)
  - [1. Demo](#1-demo)
  - [2. Features](#2-features)
  - [3. Installation](#3-installation)
    - [3.1 Download From Release](#31-download-from-release)
    - [3.2 Homebrew](#32-homebrew)
  - [4. Usage](#4-usage)
  - [5. Requirements](#5-requirements)
  - [6. License](#6-license)

## 1. Demo

![Demo](artifacts/demo.gif)

## 2. Features

- 🎨 **Modern UI** - Beautiful design with smooth animations
  - glassmorphism for users under macOS 26
  - liquid glass for users above macOS 26
- 🔍 **Quick Search** - Press 'i', '/', or 'a' to search applications instantly
- ⌨️ **Keyboard Navigation** - Navigate with arrow keys, Tab, Shift+Tab, or Vim Keys(h,j,k,l)
- 🖱️ **Mouse Support** - Click to switch applications directly
- 🚀 **Fast & Lightweight** - Native Swift implementation for optimal performance
- 🎯 **Smart Filtering** - Quickly find and switch to any running application

## 3. Installation

### 3.1. Download From Release

Download the latest version from the [Release Page](https://github.com/sshelll/CmdTab/releases).

1. Download the `.dmg` file from the releases page
2. Open the `.dmg` file and drag CmdTab to your Applications folder
3. Open it, use finder or spotlight to locate CmdTab in your Applications folder
4. **Important**: Since this is a self-built application, macOS will prevent it from opening by default. To allow it:
   - Go to System Settings > Privacy & Security, find the message about CmdTab being blocked, and click "Open Anyway"
5. Grant necessary permissions when prompted (Accessibility permissions are required for the app to function properly)

### 3.2. Homebrew

```sh
brew tap sshelll/tap git@github.com:sshelll/homebrew-tap.git
brew install --cask sshelll/tap/cmdtab
```

### 3.3 Upgrading

For upgrading, you need to install the latest `.dmg`.

**Important**: After installation, when you open CmdTab, you have to grant the permissions in step 5 again. And when you're doing this, you need to remove the old grant and add the new one manually: click the '-' to remove the old grant in Accessibility settings, then click the '+' to add the new one.

And then follow the step 4 and 5 above to allow and grant permissions.

## 4. Usage

- Press `Cmd+Tab` to open the application switcher
- Use arrow keys or Tab to navigate between applications
- Press 'i', '/', or 'a' to activate search mode
- Press Enter to switch to the selected application
- Press Esc to close the switcher

## 5. Requirements

- macOS 13.0 or later

## 6. License

MIT License
