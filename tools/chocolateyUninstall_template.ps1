$tools = Split-Path $MyInvocation.MyCommand.Definition

. $tools\helper.ps1

$packageArgs = @{
  PackageName     = 'rubymine'
  FileType        = 'exe'
  Silent          = '/S'
  File            = (Get-Uninstaller -Name 'JetBrains RubyMine {{version}}')
}
Uninstall-ChocolateyPackage @packageArgs
