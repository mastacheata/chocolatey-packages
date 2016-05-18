$tools = Split-Path $MyInvocation.MyCommand.Definition

. $tools\uninstall.ps1

Uninstall-ChocolateyPackage `
  -PackageName 'rubymine' `
  -FileType 'EXE' `
  -Silent '/S' `
  -File (Get-Uninstaller -Name 'JetBrains RubyMine 2016.1.1')
