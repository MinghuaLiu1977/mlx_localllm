#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint mlx_localllm.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'mlx_localllm'
  s.version          = '0.1.0'
  s.summary          = 'A high-performance local LLM plugin for macOS using Apple MLX.'
  s.description      = <<-DESC
A high-performance local LLM plugin for macOS using Apple's MLX framework. Supports model downloading and inference.
                       DESC
  s.homepage         = 'https://github.com/EastlakeStudio/mlx_localllm'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'EastlakeStudio' => 'support@eastlakestudio.com' }

  s.source           = { :path => '.' }
  s.source_files = 'mlx_localllm/Classes/**/*'
  s.resource_bundles = {
    'mlx_localllm_privacy' => ['mlx_localllm/Resources/PrivacyInfo.xcprivacy']
  }

  s.dependency 'FlutterMacOS'

  s.platform = :osx, '14.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.9'
end
