---
title: Home
summary: Build a quick and dirty image for Windows 365
authors:
    - Aaron Parker
---
Build a quick and dirty gold image for Windows 365 or Azure Virtual Desktop.

[![Validate script](https://github.com/aaronparker/w365/actions/workflows/validate-script.yml/badge.svg)](https://github.com/aaronparker/w365/actions/workflows/validate-script.yml)

## Quick install

Running the [`Install-Apps.ps1`](Install-Apps.ps1) on a virtual machine deployed into Azure, will install and configure the following items:

1. Set [regional settings](https://github.com/aaronparker/packer/blob/main/build/common/03_RegionLanguage.ps1) (currently supports `en-AU`, `en-GB`, `en-US`)
2. Configures [image customisations](https://stealthpuppy.com/image-customise) including the default profile, Start menu & taskbar
3. Installs supported [Microsoft Visual C++ Redistributables](https://vcredist.com/)
4. Installs the latest [Microsoft FSLogix Apps agent](https://github.com/aaronparker/packer/blob/main/build/rds/08_MicrosoftFSLogixApps.ps1)
5. Installs the latest version of [Microsoft Edge](https://github.com/aaronparker/packer/blob/main/build/rds/09_MicrosoftEdge.ps1)
6. Installs the latest version of [Microsoft 365 Apps for enterprise](https://github.com/aaronparker/packer/blob/main/build/rds/10_Microsoft365Apps.ps1), Current channel
7. Installs the latest version of [Microsoft Teams](https://github.com/aaronparker/packer/blob/main/build/rds/11_MicrosoftTeams.ps1)
8. Installs the latest version of [Microsoft OneDrive](https://github.com/aaronparker/packer/blob/main/build/rds/12_MicrosoftOneDrive.ps1)
9. Installs the latest version of [Adobe Acrobat Reader DC](https://github.com/aaronparker/packer/blob/main/build/rds/39_AdobeAcrobatReaderDC.ps1)

### Locale

`03_RegionLanguage.ps1` will configure regional settings on the local machine, but will default to `en-AU`. To configure other regional settings, use the following command in the current PowerShell session, before running `Install-Apps.ps1`, with a value of `en-US`, or `en-GB`. For example:

```powershell title="Set locale" linenums="1"
$Env:Locale = "en-GB"
```

## Steps

1. First, ensure that you are using a PowerShell as an administrator. Find PowerShell in the Start menu, right-click on the shortcut and choose `Run as Administrator`
2. Optionally set the value of `Locale` as covered in the section above
3. Run `Install-Apps.ps1` and install applications - copy the following command:

    ```powershell title="Run Install-Apps.ps1" linenums="1"
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/aaronparker/w365/main/Install-Apps.ps1'))
    ```

4. Paste the code into the PowerShell prompt that you have chosen to run as administrator
5. Wait for the command to run. If the script does not produce any errors, then the application listed above should be installed - validate by checking the applications in the **Settings** app or **Programs and Features** in **Control Panel**.
