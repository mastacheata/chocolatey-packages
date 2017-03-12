$tools = Split-Path $MyInvocation.MyCommand.Definition

. $tools\helper.ps1

Uninstall-ChocolateyPackage `
  -PackageName 'phpstorm' `
  -FileType 'EXE' `
  -Silent '/S' `
  -File (Get-Uninstaller -Name 'JetBrains PhpStorm {{version}}')
