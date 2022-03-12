<#
    .SYNOPSIS
        Use Pester and Evergreen to validate installed apps.
#>
#[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
[CmdletBinding()]
param()


BeforeDiscovery {
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
    $InstalledSoftware = Get-InstalledSoftware | Sort-Object -Property "Publisher", "Version"
    Import-Module -Name "Evergreen" -Force

    # Get the list of software to test
    # Get path
    if ([System.String]::IsNullOrWhiteSpace($env:GITHUB_WORKSPACE)) {
        $Path = $PWD.Path
    }
    Else {
        $Path = $env:GITHUB_WORKSPACE
    }
    Write-Host "Read input file: $([System.IO.Path]::Combine($Path, "tests", "Apps.json"))."
    $Applications = Get-Content -Path $([System.IO.Path]::Combine($Path, "tests", "Apps.json")) | ConvertFrom-Json
}

# Per script tests
Describe -Name "Validate installed <App.Name>" -ForEach $Applications {
    BeforeAll {

        # Get details for the current application
        $App = $_
        Write-Host "Getting details for $($App.Name)."
        $Latest = Invoke-Expression -Command $App.Filter
        $Installed = $InstalledSoftware | Where-Object { $_.Name -eq $App.Installed } | Select-Object -First 1
    }

    Context "Validate <App.Installed> is installed" {
        It "Should be a valid object" {
            $Installed | Should -Not -BeNullOrEmpty
        }
    }

    Context "Validate <App.Installed> version" {
        It "Should be the current version or better" {
            [System.Version]$Installed.Version | Should -BeGreaterOrEqual ([System.Version]$Latest.Version)
        }
    }
}
