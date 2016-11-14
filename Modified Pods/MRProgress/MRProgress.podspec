Pod::Spec.new do |s|
  s.name                  = 'MRProgress'
  s.version               = '0.7.0'
  s.summary               = 'Collection of iOS drop-in components to visualize progress with different modes'
  s.homepage              = 'https://github.com/mrackwitz/MRProgress'
  s.social_media_url      = 'https://twitter.com/mrackwitz'
  s.author                = { 'Marius Rackwitz' => 'git@mariusrackwitz.de' }
  s.license               = 'MIT License'
  s.source                = { :git => 'https://github.com/mrackwitz/MRProgress.git', :tag => s.version.to_s }
  s.source_files          = 'src/MRProgress.h'
  s.platform              = :ios, '7.0'
  s.requires_arc          = true
  s.default_subspecs      = %w{Blur ActivityIndicator Circular Icons NavigationBarProgress Overlay}
  
  s.subspec 'Blur' do |subs|
    subs.source_files = 'src/Blur/*.{h,m}'
    subs.dependency 'MRProgress/Helper'
    subs.ios.frameworks = %w{UIKit QuartzCore CoreGraphics Accelerate}
  end

  s.subspec 'ActivityIndicator' do |subs|
    subs.source_files = 'src/Components/MRActivityIndicatorView.{h,m}'
    subs.dependency 'MRProgress/Stopable'
    subs.ios.frameworks = %w{UIKit QuartzCore CoreGraphics}
  end

  s.subspec 'Circular' do |subs|
    subs.source_files = 'src/Components/MRCircularProgressView.{h,m}'
    subs.dependency 'MRProgress/Stopable'
    subs.dependency 'MRProgress/Helper'
    subs.dependency 'MRProgress/ProgressBaseClass'
    subs.ios.frameworks = %w{UIKit QuartzCore}
  end

  s.subspec 'Icons' do |subs|
    subs.source_files = 'src/Components/MRIconView.{h,m}'
    subs.ios.frameworks = %w{UIKit QuartzCore}
  end
  
  s.subspec 'NavigationBarProgress' do |subs|
    subs.source_files = 'src/Components/MRNavigationBarProgressView.{h,m}'
    subs.dependency 'MRProgress/ProgressBaseClass'
    subs.ios.frameworks = %w{UIKit}
  end
  
  s.subspec 'Overlay' do |subs|
    subs.source_files = 'src/Components/MRProgressOverlayView.{h,m}'
    subs.dependency 'MRProgress/ActivityIndicator'
    subs.dependency 'MRProgress/Circular'
    subs.dependency 'MRProgress/Icons'
    subs.dependency 'MRProgress/Blur'
    subs.dependency 'MRProgress/Helper'
    subs.ios.frameworks = %w{UIKit QuartzCore CoreGraphics}
  end
  
  # Optional support subspecs - you can use them if they make sense for you
  s.subspec 'AFNetworking' do |subs|
    subs.subspec 'Base' do |subs|
      subs.dependency 'MRProgress/MethodCopier'
      subs.dependency 'AFNetworking'
      subs.dependency 'AFNetworking/UIKit', '2.4.1'
    end

    def subs.subspec_with_category_for(spec_name, class_name)
      subspec spec_name do |subs|
        subs.dependency 'MRProgress/AFNetworking/Base'
        subs.dependency "MRProgress/#{spec_name}"
        subs.source_files = "src/Support/AFNetworking/#{class_name}+AFNetworking.{h,m}"
      end
    end

    def subs.alias_subspecs(hash)
      hash.each do |alias_name, target_name|
        subspec alias_name do |subs|
          subs.dependency "MRProgress/AFNetworking/#{target_name}"
        end
      end
    end

    subs.subspec_with_category_for('ActivityIndicator', 'MRActivityIndicatorView')
    subs.subspec_with_category_for('ProgressBaseClass', 'MRProgressView')
    subs.subspec_with_category_for('Overlay',           'MRProgressOverlayView').tap do |subs|
      subs.dependency 'MRProgress/AFNetworking/ActivityIndicator'
      subs.dependency 'MRProgress/AFNetworking/Circular'
    end
    subs.alias_subspecs 'Circular'              => 'ProgressBaseClass'
    subs.alias_subspecs 'NavigationBarProgress' => 'ProgressBaseClass'
  end
  
  # "Public" helper subspecs - you can rely on these
  s.subspec 'MessageInterceptor' do |subs|
    subs.source_files = 'src/Utils/MRMessageInterceptor.{h,m}'
  end
  
  s.subspec 'MethodCopier' do |subs|
    subs.source_files = 'src/Utils/MRMethodCopier.{h,m}'
  end

  s.subspec 'WeakProxy' do |subs|
    subs.source_files = 'src/Utils/MRWeakProxy.{h,m}'
  end

  # "Private" helper subspecs - do not depend on these
  s.subspec 'ProgressBaseClass' do |subs|
    subs.source_files = 'src/Components/MRProgressView.{h,m}'
    subs.ios.frameworks = %w{UIKit}
  end

  s.subspec 'Stopable' do |subs|
    subs.source_files = 'src/Components/{MRStopableView,MRStopButton}.{h,m}'
    subs.ios.frameworks = %w{UIKit QuartzCore}
    subs.dependency 'MRProgress/Helper'
  end
  
  s.subspec 'Helper' do |subs|
    subs.source_files = 'src/Utils/MRProgressHelper.h'
    subs.ios.frameworks = %w{UIKit QuartzCore}
  end
end