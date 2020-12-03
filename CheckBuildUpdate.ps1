param (
    [switch]$force = $false
)

if ($force) {
    Write-Host "Force update, will perform checks but ignore the result"
}

# Get directory of this script
$directory = Split-Path $MyInvocation.MyCommand.Definition

. $directory\tools\helper.ps1

# If nuspec exists, grab the old version number
if (Test-Path "$directory\phpstorm-eap.nuspec") {
    Write-Host "Found cached phpstorm-eap.nuspec"
    $oldVersion = (([xml](Get-Content "$directory\phpstorm-eap.nuspec")).package.metadata.version)
    $versions = $oldVersion -Split '-EAP'
    if ($versions.Length -gt 1) {
        $oldBuild = $versions[1] -replace('-', '.')
        $oldEap = $true
    }
    else {
        $oldBuild = $oldVersion
        $oldEap = $false
    }
} else {
    Write-Host "Couldn't find cached phpstorm-eap.nuspec at $directory\phpstorm-eap.nuspec"
    $oldBuild = "0.0.0"
}
# Get new version number from release API
$release = (Invoke-RestMethod -Uri 'https://data.services.jetbrains.com/products/releases?code=PS&latest=true&type=eap' -UseBasicParsing)
$isEap = $release.PS.type -eq 'eap'
if ($release.PS.type -eq 'eap') {
    $newVersion = "$($release.PS.version)-EAP$($release.PS.build -replace('\.', '-'))"
    $newBuild = $release.PS.build
}
else {
    $newVersion = $release.PS.version
    $newBuild = $release.PS.version
}


Write-Host "Version compare: old: $($oldBuild) new: $($newBuild)"
# Compare versions, only proceed if new version is real smaller than old version
if (([version]$oldBuild -lt [version]$newBuild) -or $force -or ($oldEap -ne $isEap)) {
    Write-Host "Cached phpstorm-eap.nuspec not found or web version differs from cache"
    # If the version appears new to us, but is already on chocolatey.org, ignore it
    try {
        Write-Host "Check if Version is already released on chocolatey.org"
        Invoke-WebRequest -Uri https://chocolatey.org/packages/phpstorm/$($newVersion) | out-null
        # If we get to this point, the webrequest didn't fail and this version already exists on chocolatey.org
        Write-Error "Version $($newVersion) already pushed to chocolatey.org"
        if (-not $force) {
            Exit
        }
    }
    catch {
    }    
}
else {
    $oldNetVersion = $oldVersion -replace "[a-zA-Z]"
    $newNetVersion = $newVersion -replace "[a-zA-Z]"

    if (($oldNetVersion -ne $newNetVersion) -and ($newNetVersion.Length -ge $newVersion.Length)) {
        throw [System.InvalidOperationException] "Invalid Version string"
    }
    else {
        throw [System.InvalidOperationException] "Already up to date (old: $($oldVersion) new: $($newVersion))"
    }
}


# Jetbrains can be a little inconsistent in their naming of document pages.
# So we verify the release specific page actually exist where we think it should.
# If not fallback to a documentation page that contains a list of all release note pages.
try {
    Write-Host "Test version specific releaseNotes url"
    $release_url = $release.PS.notesLink
    $response = Invoke-WebRequest -Uri $release_url -method head
} catch {
    Write-Host ">>`tERROR:`t`tVersion specific releaseNotes url test failed" -foreground "red"
    # Check for 404 status code and ignore other status codes that might be temporary only (i.e. 5xx codes)
    if ($_.Exception.Response.StatusCode -eq 404) {
        Write-Host ">>`t404 response`tFalling back to generic releaseNotes url" -foreground "red"
        $release_url = "https://confluence.jetbrains.com/display/PhpStorm/PhpStorm+Release+Notes"
    } else {
        Write-Host "->`t$($_.Exception.Response.StatusCode) response" -foreground "red"
    }
}

# Get download link from release API
$download = $release.PS.downloads.windows.link

# Use sha256 checksum from release API directly
$checksum = ((Invoke-RestMethod -Uri $release.PS.downloads.windows.checksumLink -UseBasicParsing).Split(" "))[0]

Write-Host "Update nuspec"
[xml]$nuspec_template = (Get-Content .\template.nuspec)
$nuspec_template.package.metadata.version = $newVersion
$nuspec_template.package.metadata.releaseNotes = $release_url
$nuspec_template.package.metadata.description = $nuspec_template.package.metadata.description -replace ('{{release}}', $release.PS.whatsnew)
if (Test-Path "$directory\phpstorm-eap.nuspec") { Remove-Item "$directory\phpstorm-eap.nuspec" }
$nuspec_template.save("$directory\phpstorm-eap.nuspec")

Write-Host "Update Installer Powershell script with new URL and checksum"
if (Test-Path "$directory\tools\chocolateyInstall.ps1") { Remove-Item "$directory\tools\chocolateyInstall.ps1" }
(Get-Content "$directory\tools\chocolateyInstall_template.ps1") -replace('{{checksum}}', $checksum) -replace('{{download}}', $download) | Set-Content "$directory\tools\chocolateyInstall.ps1"
Write-Host "Update Uninstaller Powershell script with new URL"
if (Test-Path "$directory\tools\chocolateyUninstall.ps1") { Remove-Item "$directory\tools\chocolateyUninstall.ps1" }
(Get-Content "$directory\tools\chocolateyUninstall_template.ps1") -replace('{{version}}', $newVersion) | Set-Content "$directory\tools\chocolateyUninstall.ps1"

# Pack Nupkg file
choco pack "$directory\phpstorm-eap.nuspec"

$env:PHPSTORM_VERSION=$newVersion