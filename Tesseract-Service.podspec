Pod::Spec.new do |s|
  s.name             = 'Tesseract-Service'
  s.version          = '999.99.9'
  s.summary          = 'Tesseract protocol service SDK'
  s.homepage         = 'https://github.com/tesseract-one/Tesseract.swift'
  s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.author           = { 'Tesseract Systems, Inc.' => 'info@tesseract.one' }
  s.source           = { :git => 'https://github.com/tesseract-one/Tesseract.swift.git', :tag => s.version.to_s }
  
  s.module_name      = 'TesseractService'
  s.swift_version    = '5.6'
  s.platforms        = { :ios => '13.0' }

  s.source_files     = 'Sources/TesseractService/**/*.swift', 'Sources/TesseractTransportsService/**/*.swift'
  s.static_framework = true

  s.dependency 'Tesseract-Shared', "#{s.version}"
end
