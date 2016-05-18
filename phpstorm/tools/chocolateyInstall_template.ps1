Install-ChocolateyPackage `
  -PackageName 'phpstorm' `
  -FileType 'EXE' `
  -Silent '/S' `
  -ChecksumType 'sha256'
  -Checksum '{{checksum}}' `
  -Url '{{download}}'
