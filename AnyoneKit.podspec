Pod::Spec.new do |m|

  m.name             = 'AnyoneKit'
  m.version          = '408.12.1'
  m.summary          = 'AnyoneKit is the easiest way to embed the Anyone network in your iOS and macOS application.'
  m.description      = 'AnyoneKit is the easiest way to embed the Anyone network in your iOS and macOS application. Currently, the framework compiles in static versions of anon, libevent, openssl, and liblzma.'

  m.homepage         = 'https://github.com/ATOR-Development/AnyoneKit'
  m.license          = { :type => 'MIT', :file => 'LICENSE' }
  m.authors          = { 'Benjamin Erhart' => 'berhart@netzarchitekten.com', }
  m.source           = {
    :git => 'https://github.com/ATOR-Development/AnyoneKit.git',
    :branch => 'pure_pod',
    :tag => "v#{m.version}",
    :submodules => true }
  m.social_media_url = 'https://twitter.com/tladesignz'

  m.ios.deployment_target = '12.0'
  m.macos.deployment_target = '10.13'

  script = <<-ENDSCRIPT
cd "${PODS_TARGET_SRCROOT}/AnyoneKit/%1$s"
../%1$s.sh
  ENDSCRIPT

  m.subspec 'Core' do |s|
    s.requires_arc = true

    s.source_files = 'AnyoneKit/Classes/Core/**/*'

    s.resource_bundles = {
      'GeoIP' => ['AnyoneKit/anon/src/config/geoip', 'AnyoneKit/anon/src/config/geoip6']
    }
  end

  m.subspec 'Anyone' do |s|
    s.dependency 'AnyoneKit/Core'

    s.source_files = 'AnyoneKit/Classes/CTor/**/*'

    s.pod_target_xcconfig = {
      'HEADER_SEARCH_PATHS' => '$(inherited) "${PODS_TARGET_SRCROOT}/AnyoneKit/anon" "${PODS_TARGET_SRCROOT}/AnyoneKit/anon/src" "${PODS_TARGET_SRCROOT}/AnyoneKit/openssl/include" "${BUILT_PRODUCTS_DIR}/openssl" "${PODS_TARGET_SRCROOT}/AnyoneKit/libevent/include"',
      'OTHER_LDFLAGS' => '$(inherited) -L"${BUILT_PRODUCTS_DIR}/AnyoneKit" -l"z" -l"lzma" -l"crypto" -l"ssl" -l"event_core" -l"event_extra" -l"event_pthreads" -l"event" -l"anon"',
    }

    s.ios.pod_target_xcconfig = {
      'OTHER_LDFLAGS' => '$(inherited) -L"${BUILT_PRODUCTS_DIR}/AnyoneKit-iOS"'
    }

    s.macos.pod_target_xcconfig = {
      'OTHER_LDFLAGS' => '$(inherited) -L"${BUILT_PRODUCTS_DIR}/AnyoneKit-macOS"'
    }

    s.script_phases = [
    {
      :name => 'Build LZMA',
      :execution_position => :before_compile,
      :output_files => ['lzma-always-execute-this-but-supress-warning'],
      :script => sprintf(script, "xz")
    },
    {
      :name => 'Build OpenSSL',
      :execution_position => :before_compile,
      :output_files => ['openssl-always-execute-this-but-supress-warning'],
      :script => sprintf(script, "openssl")
    },
    {
      :name => 'Build libevent',
      :execution_position => :before_compile,
      :output_files => ['libevent-always-execute-this-but-supress-warning'],
      :script => sprintf(script, "libevent")
    },
    {
      :name => 'Build Anon',
      :execution_position => :before_compile,
      :output_files => ['anon-always-execute-this-but-supress-warning'],
      :script => sprintf(script, "anon")
    },
    ]

    s.preserve_paths = 'AnyoneKit/include', 'AnyoneKit/libevent', 'AnyoneKit/libevent.sh', 'AnyoneKit/openssl', 'AnyoneKit/openssl.sh', 'AnyoneKit/anon', 'AnyoneKit/anon.sh', 'AnyoneKit/xz', 'AnyoneKit/xz.sh'
  end

  m.subspec 'Anyone-NoLZMA' do |s|
    s.dependency 'AnyoneKit/Core'

    s.source_files = 'AnyoneKit/Classes/CTor/**/*'

    s.pod_target_xcconfig = {
      'HEADER_SEARCH_PATHS' => '$(inherited) "${PODS_TARGET_SRCROOT}/AnyoneKit/anon" "${PODS_TARGET_SRCROOT}/AnyoneKit/anon/src" "${PODS_TARGET_SRCROOT}/AnyoneKit/openssl/include" "${BUILT_PRODUCTS_DIR}/openssl" "${PODS_TARGET_SRCROOT}/AnyoneKit/libevent/include"',
      'OTHER_LDFLAGS' => '$(inherited) -L"${BUILT_PRODUCTS_DIR}/AnyoneKit" -l"z" -l"crypto" -l"ssl" -l"event_core" -l"event_extra" -l"event_pthreads" -l"event" -l"anon"',
    }

    s.ios.pod_target_xcconfig = {
      'OTHER_LDFLAGS' => '$(inherited) -L"${BUILT_PRODUCTS_DIR}/AnyoneKit-iOS"'
    }

    s.macos.pod_target_xcconfig = {
      'OTHER_LDFLAGS' => '$(inherited) -L"${BUILT_PRODUCTS_DIR}/AnyoneKit-macOS"'
    }

    s.script_phases = [
    {
      :name => 'Build OpenSSL',
      :execution_position => :before_compile,
      :output_files => ['openssl-always-execute-this-but-supress-warning'],
      :script => sprintf(script, "openssl")
    },
    {
      :name => 'Build libevent',
      :execution_position => :before_compile,
      :output_files => ['libevent-always-execute-this-but-supress-warning'],
      :script => sprintf(script, "libevent")
    },
    {
      :name => 'Build Anon',
      :execution_position => :before_compile,
      :output_files => ['anon-always-execute-this-but-supress-warning'],
      :script => <<-ENDSCRIPT
cd "${PODS_TARGET_SRCROOT}/AnyoneKit/anon"
../anon.sh --no-lzma
  ENDSCRIPT
    },
    ]

    s.preserve_paths = 'AnyoneKit/include', 'AnyoneKit/libevent', 'AnyoneKit/libevent.sh', 'AnyoneKit/openssl', 'AnyoneKit/openssl.sh', 'AnyoneKit/anon', 'AnyoneKit/anon.sh'
  end

  m.default_subspecs = 'Anyone'

end
