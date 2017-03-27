$tools = Split-Path $MyInvocation.MyCommand.Definition

. $tools\helper.ps1

$packageArgs = @{
  PackageName     = 'phpstorm'
  FileType        = 'exe'
  Silent          = '/S'
  File            = (Get-Uninstaller -Name 'JetBrains PhpStorm {{version}}')
}
Uninstall-ChocolateyPackage @packageArgs
