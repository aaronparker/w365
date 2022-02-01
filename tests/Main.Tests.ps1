<#
    .SYNOPSIS
        Main Pester function tests.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
[CmdletBinding()]
param()

# Set variables
If (Test-Path -Path env:GITHUB_WORKSPACE -ErrorAction "SilentlyContinue") {
    $projectRoot = Resolve-Path -Path $env:GITHUB_WORKSPACE
}
Else {
    # Local Testing
    $projectRoot = Resolve-Path -Path (((Get-Item (Split-Path -Parent -Path $MyInvocation.MyCommand.Definition)).Parent).FullName)
}

BeforeDiscovery {
    # Set $VerbosePreference so full details are sent to the log; Make Invoke-WebRequest faster
    $VerbosePreference = "Continue"
    $ProgressPreference = "SilentlyContinue"

    # Get the scripts to test
    $Scripts = @(Get-ChildItem -Path $([System.IO.Path]::Combine($projectRoot, "Install-Apps.ps1")) -ErrorAction "SilentlyContinue")
    $testCase = $Scripts | ForEach-Object { @{file = $_ } }
}

# Per script tests
Describe "Script execution validation" -Tag "Windows" -ForEach $Scripts {
    BeforeAll {
        # Renaming the automatic $_ variable to $application to make it easier to work with
        $script = $_
    }

    Context "Validate <script.Name>." {
        It "<script.Name> should execute OK" {
            & $script.FullName | Should -Not Throw
        }
    }
}
