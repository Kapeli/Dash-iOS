Pod::Spec.new do |s|
  s.name         = 'KissXML'
  s.version      = '5.1.2'
  s.license      = { :type => 'MIT', :file => 'LICENSE.txt' }
  s.summary      = 'A replacement for Cocoa\'s NSXML cluster of classes. Based on libxml.'
  s.homepage     = 'https://github.com/robbiehanson/KissXML'
  s.author       = { 'Robbie Hanson' => 'robbiehanson@deusty.com' }
  s.source       = { :git => 'https://github.com/robbiehanson/KissXML.git', :tag => s.version }

  s.requires_arc = true
  s.default_subspecs = 'Core'

  s.subspec 'Core' do |ss|
    ss.source_files = 'KissXML/**/*.{h,m}'
    ss.private_header_files = 'KissXML/Private/**/*.h'
    ss.library      = 'xml2'
    ss.xcconfig     = { 'HEADER_SEARCH_PATHS' => '$(SDKROOT)/usr/include/libxml2'}
  end

  # Requires 'use_frameworks!' in Podfile
  s.subspec 'SwiftNSXML' do |ss|
  	ss.dependency 'KissXML/Core'
    ss.source_files = 'KissXML/**/*.{h,m,swift}'
    ss.osx.exclude_files = 'KissXML/**/*.swift'
    ss.private_header_files = 'KissXML/Private/**/*.h'
    ss.ios.deployment_target = '8.0'
    ss.osx.deployment_target = '10.8'
  	ss.tvos.deployment_target = '9.0'
  	ss.watchos.deployment_target = '2.0'
  end

  # This is left here for backwards compatibility
  s.subspec 'libxml_module' do |ss|
    ss.dependency 'KissXML/SwiftNSXML'
    ss.ios.deployment_target = '8.0'
    ss.osx.deployment_target = '10.8'
  	ss.tvos.deployment_target = '9.0'
  	ss.watchos.deployment_target = '2.0'
  end

  s.ios.deployment_target = '6.0'
  s.osx.deployment_target = '10.8'
  s.tvos.deployment_target = '9.0'
  s.watchos.deployment_target = '2.0'
end
