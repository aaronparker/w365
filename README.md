# Windows 365

[![validate-Install.ps1](https://github.com/aaronparker/w365/actions/workflows/validate-Install.ps1.yml/badge.svg)](https://github.com/aaronparker/w365/actions/workflows/validate-Install.ps1.yml)

Build a quick and dirty image for Windows 365 with [`Install.ps1`](Install.ps1). This script will perform the following changes:

1. Set regional settings (currently supports en-AU, en-GB, en-US)
2. Configures [image customisations](https://stealthpuppy.com/image-customise) including the default profile, Start menu & taskbar
3. Installs supported [Microsoft Visual C++ Redistributables](https://vcredist.com/)
4. Installs the latest Microsoft FSLogix Apps agent
5. Installs the latest version of Microsoft Edge
6. Installs the latest version of Microsoft 365 Apps for enterprise, Current channel
7. Installs the latest version of Microsoft Teams
8. Installs the latest version of Microsoft OneDrive
9. Installs the latest version of Adobe Acrobat Reader DC

Full documentation is found here: [stealthpuppy.com/w365](https://stealthpuppy.com/w365).