$tools = Split-Path $MyInvocation.MyCommand.Definition

. $tools\helper.ps1

$packageArgs = @{
  PackageName     = 'rubymine'
  FileType        = 'exe'
  Silent          = "/S /CONFIG=$tools\silent.config"
  ChecksumType    = 'sha256'
  Checksum        = '{{checksum}}'
  Url             = '{{download}}'
}
Install-ChocolateyPackage @packageArgs
