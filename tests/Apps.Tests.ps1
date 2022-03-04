<#
    .SYNOPSIS
        Use Pester and Evergreen to validate installed apps.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
[CmdletBinding()]
param()


BeforeDiscovery {
    # Set $VerbosePreference so full details are sent to the log; Make Invoke-WebRequest faster
    $VerbosePreference = "Continue"
    $ProgressPreference = "SilentlyContinue"

    #region Functions
    Function Get-InstalledSoftware {
        <#
        .SYNOPSIS
            Retrieves a list of all software installed

        .EXAMPLE
            Get-InstalledSoftware

            This example retrieves all software installed on the local computer

        .PARAMETER Name
            The software title you'd like to limit the query to.

        .NOTES
            Author: Adam Bertram
            URL: https://4sysops.com/archives/find-the-product-guid-of-installed-software-with-powershell/
    #>
        [OutputType([System.Management.Automation.PSObject])]
        [CmdletBinding()]
        param (
            [Parameter()]
            [ValidateNotNullOrEmpty()]
            [System.String] $Name
        )

        $UninstallKeys = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall", "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
        $null = New-PSDrive -Name HKU -PSProvider Registry -Root Registry::HKEY_USERS
        $UninstallKeys += Get-ChildItem HKU: -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'S-\d-\d+-(\d+-){1,14}\d+$' } | `
            ForEach-Object { "HKU:\$($_.PSChildName)\Software\Microsoft\Windows\CurrentVersion\Uninstall" }
        if (-not $UninstallKeys) {
            Write-Verbose -Message "$($MyInvocation.MyCommand): No software registry keys found."
        }
        else {
            foreach ($UninstallKey in $UninstallKeys) {
                if ($PSBoundParameters.ContainsKey('Name')) {
                    $WhereBlock = { ($_.PSChildName -match '^{[A-Z0-9]{8}-([A-Z0-9]{4}-){3}[A-Z0-9]{12}}$') -and ($_.GetValue('DisplayName') -like "$Name*") }
                }
                else {
                    $WhereBlock = { ($_.PSChildName -match '^{[A-Z0-9]{8}-([A-Z0-9]{4}-){3}[A-Z0-9]{12}}$') -and ($_.GetValue('DisplayName')) }
                }
                $gciParams = @{
                    Path        = $UninstallKey
                    ErrorAction = 'SilentlyContinue'
                }
                $selectProperties = @(
                    @{n = 'Publisher'; e = { $_.GetValue('Publisher') } },
                    @{n = 'Name'; e = { $_.GetValue('DisplayName') } },
                    @{n = 'Version'; e = { $_.GetValue('DisplayVersion') } }
                )
                Get-ChildItem @gciParams | Where-Object $WhereBlock | Select-Object -Property $selectProperties
            }
        }
    }
    #endregion

    # Get the Software list; Output the installed software to the pipeline for Packer output
    $Software = Get-InstalledSoftware | Sort-Object -Property "Publisher", "Version"
}

# Per script tests
Describe "Validate installed applications" {
    BeforeAll {
        # Microsoft FSLogix Apps
        $FSLogixInstalled = $Software | Where-Object { $_.Name | Should -Be "Microsoft FSLogix Apps" } | Select-Object -First 1
        $FSLogixCurrent = Get-EvergreenApp -Name "AdobeAcrobatReaderDC" | Where-Object { $_.Language | Should -Be $Language -and $_.Architecture | Should -Be $Architecture } | `
            Select-Object -First 1

        # Microsoft Edge
        $EdgeInstalled = $Software | Where-Object { $_.Name | Should -Be "Microsoft Edge" } | Select-Object -First 1
        $EdgeCurrent = Get-EvergreenApp -Name "MicrosoftEdge" | Where-Object { $_.Architecture | Should -Be "x64" -and $_.Channel | Should -Be "Stable" -and $_.Release | Should -Be "Enterprise" } | `
            Sort-Object -Property @{ Expression = { [System.Version]$_.Version }; Descending = $true } | Select-Object -First 1

        # Teams Machine-Wide Installer
        $TeamsInstalled = $Software | Where-Object { $_.Name | Should -Be "Teams Machine-Wide Installer" } | Select-Object -First 1
        $TeamsCurrent = Get-EvergreenApp -Name "MicrosoftTeams" | Where-Object { $_.Architecture | Should -Be "x64" -and $_.Ring | Should -Be "General" -and $_.Type | Should -Be "msi" } | `
            Select-Object -First 1

        # Office 16 Click-to-Run Licensing Component
        $OfficeInstalled = $Software | Where-Object { $_.Name | Should -Be "Office 16 Click-to-Run Licensing Component" } | Select-Object -First 1
        $OfficeCurrent = Get-EvergreenApp -Name "Microsoft365Apps" | Where-Object { $_.Channel | Should -Be "Current" } | Select-Object -First 1

        # Adobe Acrobat DC (64-bit)
        $ReaderInstalled = $Software | Where-Object { $_.Name | Should -Be "Adobe Acrobat DC (64-bit)" } | Select-Object -First 1
        $ReaderCurrent = Get-EvergreenApp -Name "AdobeAcrobatReaderDC" | Where-Object { $_.Language | Should -Be $Language -and $_.Architecture | Should -Be $Architecture } | `
            Select-Object -First 1
    }

    Context "Validate Microsoft FSLogix Apps" {
        It "Should be the current version" {
            [System.Version]$FSLogixInstalled.Version | Should -Be [System.Version]$FSLogixCurrent.Version
        }
    }

    Context "Validate Microsoft Edge" {
        It "Should be the current version" {
            [System.Version]$EdgeInstalled.Version | Should -Be [System.Version]$EdgeCurrent.Version
        }
    }

    Context "Validate Microsoft Teams" {
        It "Should be the current version" {
            [System.Version]$TeamsInstalled.Version | Should -Be [System.Version]$TeamsCurrent.Version
        }
    }

    Context "Validate Microsoft 365 Apps" {
        It "Should be the current version" {
            [System.Version]$OfficeInstalled.Version | Should -Be [System.Version]$OfficeCurrent.Version
        }
    }

    Context "Validate Adobe Acrobat" {
        It "Should be the current version" {
            [System.Version]$ReaderInstalled.Version | Should -Be [System.Version]$ReaderCurrent.Version
        }
    }
}
