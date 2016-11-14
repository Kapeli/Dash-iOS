Pod::Spec.new do |spec|
  spec.name         = 'DTBonjour'
  spec.version      = '1.1.1'
  spec.summary      = "Client/Server Communication of NSObjects over WiFi."
  spec.homepage     = "https://github.com/Cocoanetics/DTBonjour"
  spec.author       = { "Oliver Drobnik" => "oliver@drobnik.com" }
  spec.source       = { :git => "https://github.com/Cocoanetics/DTBonjour.git", :tag => spec.version.to_s  }
  spec.source_files = 'Core/Source/*.{h,m}'
  spec.license      = 'BSD'
  spec.ios.deployment_target = '5.0'
  spec.osx.deployment_target = '10.7'
  spec.ios.frameworks   =  ["CoreFoundation", "Foundation", "UIKit"] 
  spec.osx.frameworks   =  ["CoreFoundation", "Foundation"] 
  spec.requires_arc = true
end
