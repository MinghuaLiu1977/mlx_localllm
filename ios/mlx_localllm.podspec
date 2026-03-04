#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint mlx_localllm.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'mlx_localllm'
  s.version          = '0.1.0'
  s.summary          = 'A high-performance local LLM plugin for iOS using Apple MLX.'
  s.description      = <<-DESC
A high-performance local LLM plugin for iOS using Apple's MLX framework. Supports model downloading and inference.
                       DESC
  s.homepage         = 'https://github.com/MinghuaLiu1977/mlx_localllm'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'MinghuaLiu' => 'support@eastlakestudio.com' }

  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '17.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.9'
end
