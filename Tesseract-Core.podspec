Pod::Spec.new do |s|
  s.name             = 'Tesseract-Core'
  s.version          = '999.99.9'
  s.summary          = 'Compiled rust core for Tesseract protocol implementation'
  s.homepage         = 'https://github.com/tesseract-one/Tesseract.swift'
  s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.author           = { 'Tesseract Systems, Inc.' => 'info@tesseract.one' }
  s.source           = { :http => "file://#{File.dirname(__FILE__)}/Tesseract-Core.bin.zip" }
  
  s.module_name      = 'CTesseract'
  s.platforms        = { :ios => '13.0' }

  s.source_files      = 'Sources/CTesseract/**/*.{h,c}'
  s.static_framework  = true

  s.vendored_frameworks = 'CTesseractBin.xcframework'
end
