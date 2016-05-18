Install-ChocolateyPackage `
  -PackageName 'rubymine' `
  -FileType 'EXE' `
  -Silent '/S' `
  -ChecksumType 'sha256'
  -Checksum '{{checksum}}' `
  -Url '{{download}}'
