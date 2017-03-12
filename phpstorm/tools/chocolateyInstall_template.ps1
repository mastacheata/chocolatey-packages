$tools = Split-Path $MyInvocation.MyCommand.Definition

. $tools\helper.ps1

﻿Install-ChocolateyPackage `
  -PackageName 'phpstorm' `
  -FileType 'EXE' `
  -Silent '/S' `
  -ChecksumType 'sha256'
  -Checksum '{{checksum}}' `
  -Url '{{download}}'
