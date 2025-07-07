Pod::Spec.new do |m|

  m.name             = 'AnyoneKit'
  m.version          = '409.11.2'
  m.summary          = 'AnyoneKit is the easiest way to embed the Anyone network in your iOS and macOS application.'
  m.description      = 'AnyoneKit is the easiest way to embed the Anyone network in your iOS and macOS application. Currently, the framework compiles in static versions of anon, libevent, openssl, and liblzma.'

  m.homepage         = 'https://github.com/anyone-protocol/AnyoneKit'
  m.license          = { :type => 'MIT', :file => 'LICENSE' }
  m.authors          = { 'Benjamin Erhart' => 'berhart@netzarchitekten.com', }
  m.source           = {
    :git => 'https://github.com/anyone-protocol/AnyoneKit.git',
    :branch => 'main',
    :tag => "v#{m.version}" }
  m.social_media_url = 'https://chaos.social/@tla'

  m.ios.deployment_target = '12.0'
  m.macos.deployment_target = '10.13'

  m.requires_arc = true

  m.source_files = 'AnyoneKit/Classes/**/*'

  m.resource_bundles = {
    'GeoIP' => ['AnyoneKit/Assets/geoip', 'AnyoneKit/Assets/geoip6']
  }

  m.vendored_frameworks = 'anon.xcframework'
  m.libraries = 'z'

  m.pod_target_xcconfig = {
    'HEADER_SEARCH_PATHS' => '$(inherited) "${PODS_TARGET_SRCROOT}/anon.xcframework/ios-arm64/anon.framework/Headers"'
  }

  m.preserve_paths = 'build-xcframework.sh', 'anon.xcframework', 'AnyoneKit/download.sh'

  m.prepare_command = "AnyoneKit/download.sh v#{m.version}"

end
