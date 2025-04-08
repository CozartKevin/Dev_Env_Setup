# Dev Environment Bootstrapper

This PowerShell script automates the setup and management of a structured development environment based on a JSON configuration file. It supports installing, uninstalling, updating, and cleaning up tools and libraries used in C++ projects.

## Features

- JSON-driven configuration
- Dynamic folder mapping and validation
- Modular install/uninstall/update logic
- Enum-based action handling
- Extensible for custom toolchains and libraries

## Folder Structure

All tools and libraries are installed relative to a root `_dev` directory on the same drive as the script.

Example:
D:_dev
├── build_tools
├── libraries
│ ├── audio
│ ├── embedded
│ ├── graphics
│ └── networking
├── tools\

## Configuration File

`programs-config.json` defines:

```json
{
  "FolderMappings": [
    { "Key": "BUILD_TOOLS", "Path": "build_tools" },
    { "Key": "LIBRARIES", "Path": "libraries" },
    { "Key": "TOOLS", "Path": "tools" },
    { "Key": "AUDIO_LIB", "Path": "libraries\\audio" },
    { "Key": "EMBEDDED_LIB", "Path": "libraries\\embedded" },
    { "Key": "GRAPHICS_LIB", "Path": "libraries\\graphics" },
    { "Key": "NETWORKING_LIB", "Path": "libraries\\networking" }
  ],
  "Programs": [
    {
      "Name": "vcpkg",
      "Command": "git clone https://github.com/microsoft/vcpkg.git; .\\bootstrap-vcpkg.bat",
      "InstallLocation": "TOOLS",
      "Action": "install"
    }
  ]
}
```

## Supported Actions
* install – Runs the install command(s)
* uninstall – Removes installed tools (with vcpkg support)

## Future Supported Actions:
* update – Placeholder for future use
* clean – Removes install directories
* validate – Placeholder for validation logic
* noaction – Skips the program

## Usage

Place the script and programs-config.json in the same directory.
Edit programs-config.json to reflect your tools and structure.
Run the script:
.\dev-setup.ps1

## Skills Demonstrated
- PowerShell scripting
- JSON parsing and validation
- Automation and tooling
- Enum-based state handling
- DevOps environment bootstrapping


## License

MIT License

Copyright (c) [2025] Kevin Cozart.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

### Note:
This software must include the reference to the original author, Kevin Cozart at Core Utilities Inc., when used, distributed, or modified.

---
[LinkedIn](https://www.linkedin.com/in/Cozartkevin)  
[GitHub](https://www.github.com/CozartKevin)

