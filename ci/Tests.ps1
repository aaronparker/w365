<#
    .SYNOPSIS
        Tests script.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
[CmdletBinding()]
param()


# Configure the test environment
Import-Module -Name "Pester" -Force
$testsPath = Join-Path -Path $env:GITHUB_WORKSPACE -ChildPath "tests"
$testOutput = Join-Path -Path $env:GITHUB_WORKSPACE -ChildPath "TestsResults.xml"
$testConfig = [PesterConfiguration] @{
    Run        = @{
        Path     = $testsPath
        PassThru = $True
    }
    TestResult = @{
        OutputFormat = "NUnitXml"
        OutputFile   = $testOutput
    }
    Show       = "Default"
}
Write-Host "Tests path:      $testsPath."
Write-Host "Output path:     $testOutput."

# Invoke Pester tests
Invoke-Pester -Configuration $testConfig

# Line break for readability in console
Write-Host ""
