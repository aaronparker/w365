<#
    Run application install scripts
#>
[CmdletBinding()]
param()

Set-ExecutionPolicy Bypass -Scope "Process" -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

$Scripts = @(
    "https://raw.githubusercontent.com/aaronparker/packer/main/build/rds/01_Rds-PrepImage.ps1",
    "https://raw.githubusercontent.com/aaronparker/packer/main/build/common/03_RegionLanguage.ps1",
    "https://stealthpuppy.com/image-customise/Install.ps1",
    "https://raw.githubusercontent.com/aaronparker/packer/main/build/common/06_SupportFunctions.ps1",
    "https://vcredist.com/install.ps1",
    "https://raw.githubusercontent.com/aaronparker/packer/main/build/rds/08_MicrosoftFSLogixApps.ps1",
    "https://raw.githubusercontent.com/aaronparker/packer/main/build/rds/09_MicrosoftEdge.ps1",
    "https://raw.githubusercontent.com/aaronparker/packer/main/build/rds/10_Microsoft365Apps.ps1",
    "https://raw.githubusercontent.com/aaronparker/packer/main/build/rds/11_MicrosoftTeams.ps1",
    "https://raw.githubusercontent.com/aaronparker/packer/main/build/rds/12_MicrosoftOneDrive.ps1",
    "https://raw.githubusercontent.com/aaronparker/packer/main/build/rds/39_AdobeAcrobatReaderDC.ps1"
    #"https://raw.githubusercontent.com/aaronparker/packer/main/build/rds/98_MicrosoftOptimise.ps1"
)

ForEach ($Script in $Scripts) {
    Invoke-Expression -Command ((New-Object -TypeName "System.Net.WebClient").DownloadString($Script))
}

#region List installed software
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
Get-InstalledSoftware | Format-Table
#endregion
