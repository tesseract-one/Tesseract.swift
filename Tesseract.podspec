Pod::Spec.new do |s|
  s.name             = 'Tesseract'
  s.version          = '0.1.0'
  s.summary          = 'Tesseract DApp Platform SDK for iOS and OSX'

  s.description      = <<-DESC
Tesseract DApp Platform SDK for iOS and OSX
                       DESC

  s.homepage         = 'https://github.com/tesseract-one/Tesseract.swift'

  s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.author           = { 'Tesseract Systems, Inc.' => 'info@tesseract.one' }
  s.source           = { :git => 'https://github.com/tesseract-one/Tesseract.swift.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/tesseract_one'

  s.ios.deployment_target = '10.0'

  s.module_name = 'Tesseract'

  s.subspec 'Core' do |ss|
    ss.source_files = 'Sources/Tesseract/Core/**/*.swift'

    ss.dependency 'Tesseract.OpenWallet/Client', '~> 0.1'
  end

  s.subspec 'Ethereum.Core' do |ss|
    ss.source_files = 'Sources/Tesseract/Ethereum/Core/**/*.swift'

    ss.dependency 'Tesseract/Core'
    ss.dependency 'Tesseract.OpenWallet/Ethereum', '~> 0.1'
    ss.dependency 'Tesseract.EthereumTypes', '~> 0.1'
  end

  #s.subspec 'Ethereum.Web3' do |ss|
  #  ss.source_files = 'Sources/Tesseract/Ethereum/Web3.swift'

  #  ss.dependency 'Tesseract/Ethereum.Core'
  #  ss.dependency 'Tesseract.EthereumWeb3', '~> 0.1'
  #end

  #s.subspec 'Ethereum.Web3.PromiseKit' do |ss|
  #  ss.dependency 'Tesseract/Ethereum.Web3'
  #  ss.dependency 'Tesseract.EthereumWeb3/PromiseKit', '~> 0.1'
  #end

  #s.subspec 'Ethereum' do |ss|
  #  ss.dependency 'Tesseract/Ethereum.Web3'
  #end

  #s.subspec 'Ethereum.PromiseKit' do |ss|
  #  ss.dependency 'Tesseract/Ethereum.Web3.PromiseKit'
  #end

  s.default_subspecs = 'Core'
end
