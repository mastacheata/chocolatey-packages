# Get directory of this script
$directory = Split-Path $MyInvocation.MyCommand.Definition

# If nuspec exists, grab the old version number
if (Test-Path "$directory\phpstorm.nuspec") {
    $oldVersion = ([xml](Get-Content "$directory\phpstorm.nuspec")).package.metadata.version
} else {
    $oldVersion = "0.0.0"
}
# Get new version number from release API
$release = (Invoke-RestMethod -Uri 'https://data.services.jetbrains.com/products/releases?code=PS&latest=true&type=release' -UseBasicParsing)
$newVersion = $release.PS.version

# Compare versions, only proceed if new version is real smaller than old version
try {
    if (-not ([version]$oldVersion -lt [version]$newVersion)) {
        throw [System.InvalidOperationException] "Already up to date"
    }
}
catch {
    $oldNetVersion = $oldVersion -replace "[a-zA-Z]"
    $newNetVersion = $newVersion -replace "[a-zA-Z]"

    if ($oldNetVersion -ne $newNetVersion -and $newNetVersion.Length -ge $newVersion.Length) {
        throw [System.InvalidOperationException] "Invalid Version string"
    }
}

# Jetbrains can be a little inconsistent in their naming of document pages.
# So we verify the release specific page actually exist where we think it should.
$release_url = "https://confluence.jetbrains.com/display/PhpStorm/PhpStorm+$newVersion+Release+Notes"
$download_release = Invoke-WebRequest -Uri $release_url -UseBasicParsing
# If not fallback to a documentation page that contains a list of all release note pages.
if($download_release.RawContent -like '*Page Not Found*') {
    $release_url = "https://confluence.jetbrains.com/display/PhpStorm/PhpStorm+Release+Notes"
}

# (deprecated) Download Installer and build md5sum
<#
if (Test-Path "$directory\phpstorm.exe") { Remove-Item "$directory\phpstorm.exe" }
$download = $release.PS.downloads.windows.link
Write-Host "Getting new version from $download"
(New-Object System.Net.WebClient).DownloadFile($download, "$directory\phpstorm.exe")
$checksum = (Get-FileHash "$directory\phpstorm.exe" -Algorithm MD5).hash.ToLower()
Write-Host "New MD5 checksum is $checksum"
#>

# Use sha256 checksum from release API directly
$checksum = ((Invoke-RestMethod -Uri $release.PS.downloads.windows.checksumLink -UseBasicParsing).Split(" "))[0]

Write-Host "Update nuspec"
[xml]$nuspec_template = (Get-Content .\phpstorm_template.nuspec)
$nuspec_template.package.metadata.version = $newVersion
if (Test-Path "$directory\phpstorm.nuspec") { Remove-Item "$directory\phpstorm.nuspec" }
$nuspec_template.save("$directory\phpstorm.nuspec")
Write-Host "Update nuspec <releaseNotes> with new URL"
(Get-Content "$directory\phpstorm.nuspec") -replace('{{release_url}}', $release_url) | Set-Content "$directory\phpstorm.nuspec"

Write-Host "Update Installer Powershell script with new URL and checksum"
if (Test-Path "$directory\tools\chocolateyInstall.ps1") { Remove-Item "$directory\tools\chocolateyInstall.ps1" }
(Get-Content "$directory\tools\chocolateyInstall_template.ps1") -replace('{{checksum}}', $checksum) -replace('{{download}}', $download) | Set-Content "$directory\tools\chocolateyInstall.ps1"
Write-Host "Update Uninstaller Powershell script with new URL"
if (Test-Path "$directory\tools\chocolateyUninstall.ps1") { Remove-Item "$directory\tools\chocolateyUninstall.ps1" }
(Get-Content "$directory\tools\chocolateyUninstall_template.ps1") -replace('{{version}}', $newVersion) | Set-Content "$directory\tools\chocolateyUninstall.ps1"

# Pack Nupkg file
choco pack "$directory\phpstorm.nuspec"
# Submit to chocolatey.org Community Repository
# choco push --source https://chocolatey.org/

# Cleanup
#Write-Host "remove nupkg file"
#Get-ChildItem $directory -include *.nupkg -recurse | Remove-Item
