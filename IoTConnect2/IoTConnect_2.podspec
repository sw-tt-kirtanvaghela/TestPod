#
#  Be sure to run `pod spec lint IoTConnect_2.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  spec.name         = "IoTConnect_2"
  spec.version      = "1.0"
  spec.summary      = "SDK for IoTConnect portal"

  spec.description  = "This is second version of IoTConnect SDK"

  spec.homepage     = "https://github.com/sw-tt-kirtanvaghela/TestPod.git"
  # spec.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"

  spec.license      = "MIT"
  # spec.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  
  spec.author             = { "sw-tt-kirtanvaghela" => "135005218+sw-tt-kirtanvaghela@users.noreply.github.com" }

   spec.platform     = :ios
   spec.platform     = :ios, "12.0"

  # spec.ios.vendored_frameworks = "IoTConnect_2.0.framework"
  spec.source = { :git => "https://github.com/sw-tt-kirtanvaghela/TestPod.git", :tag => "v1.0" }
  spec.source_files  = "IoTConnect2/**/*"

 # spec.exclude_files = "Classes/Exclude"

  spec.dependency "CocoaMQTT"
  spec.swift_version = "5.0"
end
