<#
    .SYNOPSIS
        Install script.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
[CmdletBinding()]
param()

# Set variables
$tests = Join-Path -Path $env:GITHUB_WORKSPACE -ChildPath "tests"
$output = Join-Path -Path $env:GITHUB_WORKSPACE -ChildPath "TestsResults.xml"

# Echo variables
Write-Host ""
Write-Host "OS version:      $((Get-CimInstance -ClassName "CIM_OperatingSystem").Caption)"
Write-Host "Project root:    $env:GITHUB_WORKSPACE."
Write-Host "Tests path:      $tests."
Write-Host "Output path:     $output."

# Line break for readability in console
Write-Host ""
Write-Host "PowerShell Version:" $PSVersionTable.PSVersion.ToString()

# Install packages
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-PackageProvider -Name "NuGet" -MinimumVersion "2.8.5.208" -Force -ErrorAction "SilentlyContinue"
If (Get-PSRepository -Name "PSGallery" | Where-Object { $_.InstallationPolicy -ne "Trusted" }) {
    Set-PSRepository -Name "PSGallery" -InstallationPolicy "Trusted"
}

# Install modules
$Modules = "Pester"
ForEach ($Module in $Modules ) {
    If ([System.Version]((Find-Module -Name $Module).Version) -gt (Get-Module -Name $Module).Version) {
        Install-Module -Name $Module -SkipPublisherCheck -Force
    }
    Import-Module -Name $Module -Force
}
