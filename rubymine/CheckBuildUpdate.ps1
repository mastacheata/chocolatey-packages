# Get directory of this script
$directory = Split-Path $MyInvocation.MyCommand.Definition

# If nuspec exists, grab the old version number
if (Test-Path "$directory\rubymine.nuspec") {
    $oldVersion = ([xml](Get-Content "$directory\rubymine.nuspec")).package.metadata.version
} else {
    $oldVersion = "0.0.0"
}
# Get new version number from release API
$release = (Invoke-RestMethod -Uri 'https://data.services.jetbrains.com/products/releases?code=RM&latest=true&type=release' -UseBasicParsing)
$newVersion = $release.RM.version

# Compare versions, only proceed if new version is real smaller than old version
if (-not ([version]$oldVersion -lt [version]$newVersion)) {
    throw [System.InvalidOperationException] "Already up to date"
}

# (deprecated) Download Installer and build md5sum
<#
if (Test-Path "$directory\rubymine.exe") { Remove-Item "$directory\rubymine.exe" }
$download = $release.RM.downloads.windows.link
Write-Host "Getting new version from $download"
(New-Object System.Net.WebClient).DownloadFile($download, "$directory\rubymine.exe")
$checksum = (Get-FileHash "$directory\rubymine.exe" -Algorithm MD5).hash.ToLower()
Write-Host "New MD5 checksum is $checksum"
#>

# Use sha256 checksum from release API directly
$checksum = ((Invoke-RestMethod -Uri $release.RM.downloads.windows.checksumLink -UseBasicParsing).Split(" "))[0]

Write-Host "Update nuspec"
[xml]$nuspec_template = (Get-Content .\rubymine_template.nuspec)
$nuspec_template.package.metadata.version = $newVersion
if (Test-Path "$directory\rubymine.nuspec") { Remove-Item "$directory\rubymine.nuspec" }
$nuspec_template.save("$directory\rubymine.nuspec")

Write-Host "Update Installer Powershell script with new URL and checksum"
if (Test-Path "$directory\tools\chocolateyInstall.ps1") { Remove-Item "$directory\tools\chocolateyInstall.ps1" }
(Get-Content "$directory\tools\chocolateyInstall_template.ps1") -replace('{{checksum}}', $checksum) -replace('{{download}}', $download) | Set-Content "$directory\tools\chocolateyInstall.ps1"
Write-Host "Update Uninstaller Powershell script with new URL"
if (Test-Path "$directory\tools\chocolateyUninstall.ps1") { Remove-Item "$directory\tools\chocolateyUninstall.ps1" }
(Get-Content "$directory\tools\chocolateyUninstall_template.ps1") -replace('{{version}}', $newVersion) | Set-Content "$directory\tools\chocolateyUninstall.ps1"

# Pack Nupkg file
choco pack "$directory\rubymine.nuspec"
# Submit to chocolatey.org Community Repository
# choco push --source https://chocolatey.org/

# Cleanup
Get-ChildItem $directory -include *.nupkg -recurse | Remove-Item