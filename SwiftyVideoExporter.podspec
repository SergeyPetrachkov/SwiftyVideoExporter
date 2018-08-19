Pod::Spec.new do |s|
  s.name             = 'SwiftyVideoExporter'
  s.version          = '1.0.1'
  s.summary          = 'SwiftyVideoExporter is to help developers in video export.'
  s.description      = 'SwiftyVideoExporter is to help developers in video export. Export from gallery, compress and crop.'

  s.homepage         = 'https://github.com/SergeyPetrachkov/SiberianSwift'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'sergey petrachkov' => 'petrachkovsergey@gmail.com' }
  s.source           = { :git => 'https://github.com/SergeyPetrachkov/SwiftyVideoExporter.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'

  s.source_files = 'SwiftyVideoExporter/**/*'
end
