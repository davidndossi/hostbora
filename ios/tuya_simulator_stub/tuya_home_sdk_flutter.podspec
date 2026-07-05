Pod::Spec.new do |s|
  s.name             = 'tuya_home_sdk_flutter'
  s.version          = '0.0.2'
  s.summary          = 'Tuya Smart home SDK for flutter (simulator stub)'
  s.description      = 'Simulator-safe stub without Tuya native XCFrameworks.'
  s.homepage         = 'https://premierank.com'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Host Bora' => 'dev@hostbora.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency       'Flutter'
  s.static_framework = true
  s.platform         = :ios, '15.5'
  s.swift_version    = '5.0'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
  }
end
