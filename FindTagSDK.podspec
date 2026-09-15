Pod::Spec.new do |s|
  s.name = 'FindTagSDK'
  s.version = '1.0.1'
  s.summary = 'FindTag iOS SDK binary distribution.'
  s.homepage = 'https://github.com/EvetSoftware/FindTag_iOS_SDK'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.author = { 'EvetSoftware' => 'semih@hasvet.com' }
  s.source = { :git => 'https://github.com/EvetSoftware/FindTag_iOS_SDK.git', :tag => s.version.to_s }
  s.platform = :ios, '15.0'
  s.swift_version = '5.0'
  s.vendored_frameworks = 'libs/TagSdk.xcframework'
end
