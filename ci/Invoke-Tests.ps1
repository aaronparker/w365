<#
    .SYNOPSIS
        Tests script.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
[CmdletBinding()]
param()

# Get path
if ([System.String]::IsNullOrWhiteSpace($env:GITHUB_WORKSPACE)) {
    $Path = $PWD.Path
}
Else {
    $Path = $env:GITHUB_WORKSPACE
}

# Configure the test environment
Import-Module -Name "Pester" -Force
$TestsPath = Join-Path -Path $Path -ChildPath "tests"
$TestOutput = Join-Path -Path $Path -ChildPath "TestsResults.xml"
$CoverageOutput = Join-Path -Path $Path -ChildPath "CodeCoverage.xml"
Write-Host "Tests path:      $testsPath."
Write-Host "Output path:     $testOutput."

# Invoke Pester tests
$Config = [PesterConfiguration]::Default
$Config.Run.Path = $TestsPath
$Config.Run.PassThru = $True
$Config.CodeCoverage.Enabled = $True
$Config.CodeCoverage.OutputPath = $CoverageOutput
$Config.TestResult.Enabled = $True
$Config.TestResult.OutputFormat = "NUnitXml"
$Config.TestResult.OutputPath = $TestOutput
Invoke-Pester -Configuration $Config

# Line break for readability in console
Write-Host ""
