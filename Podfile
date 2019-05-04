use_frameworks!

def common_pods
  pod 'Tesseract.OpenWallet/Ethereum', '~> 0.1'
  pod 'Tesseract.EthereumWeb3', :git => 'https://github.com/tesseract-one/EthereumWeb3.swift.git', :branch => 'master'
  
  # temporary. Should be removed
  pod 'Web3', :git => 'https://github.com/tesseract-one/Web3.swift.git', :branch => 'master'
end

target 'Tesseract-iOS' do
  platform :ios, "10.0"
  
  common_pods
end

target 'TesseractTests-iOS' do
  platform :ios, "10.0"
  
  common_pods
end 
