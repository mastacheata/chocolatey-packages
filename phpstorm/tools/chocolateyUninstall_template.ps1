$tools = Split-Path $MyInvocation.MyCommand.Definition

. $tools\uninstall.ps1

Uninstall-ChocolateyPackage `
  -PackageName 'phpstorm' `
  -FileType 'EXE' `
  -Silent '/S' `
  -File (Get-Uninstaller -Name 'JetBrains PhpStorm {{version}}')
