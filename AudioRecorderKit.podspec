Pod::Spec.new do |s|

s.name         = 'AudioRecorderKit'

s.version      = "1.0"

s.swift_version = "4.0"

s.summary      = 'Simple Project.'

s.author       = { "vjieshao" => "461128269@qq.com" }

s.homepage     = 'https://github.com/vjieshao/AudioRecorderKit.git'

s.license      = { :type => "MIT", :file => "LICENSE" }

s.source       = { :git => "https://github.com/vjieshao/AudioRecorderKit.git", :tag => s.version}

s.platform     = :ios

s.ios.deployment_target = "9.0"

s.frameworks = 'Foundation'

s.source_files = 'AudioRecorderKit/**/*.swift'

s.requires_arc = true

end