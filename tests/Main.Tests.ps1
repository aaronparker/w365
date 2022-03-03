<#
    .SYNOPSIS
        Main Pester function tests.
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
    Write-Host " Export software list to: $SoftwareFile."
    $Software = Get-InstalledSoftware | Sort-Object -Property "Publisher", "Version"

    # Get the scripts to test
    $EdgeCurrent = Get-EvergreenApp -Name "MicrosoftEdge" | Where-Object { $_.Architecture -eq "x64" -and $_.Channel -eq "Stable" -and $_.Release -eq "Enterprise" } `
    | Sort-Object -Property @{ Expression = { [System.Version]$_.Version }; Descending = $true } | Select-Object -First 1
}

# Per script tests
Describe "Validate installed applications" {
    BeforeAll {
        $EdgeInstalled = $Software | Where-Object { $_.Name -eq "Microsoft Edge" }
    }

    Context "Validate Microsoft Edge" {
        It "Should be the current version" {
            [System.Version]$EdgeInstalled.Version -eq [System.Version]$EdgeCurrent.Version  | Should -Be $True
        }
    }
}
