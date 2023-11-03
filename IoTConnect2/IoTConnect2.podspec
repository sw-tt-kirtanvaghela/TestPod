#
#  Be sure to run `pod spec lint IoTConnect2.podspec' to ensure this is a
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

  spec.name         = "IoTConnect2"
  spec.version      = "1.0.0"
  spec.summary      = "Second version of IoTConnecr SDK"


  spec.description  = "To connect, and send data to IoTDevice"

  spec.homepage     = "https://github.com/sw-tt-kirtanvaghela/TestPod.git"
  
  spec.license      = "MIT"

  spec.author             = { "sw-tt-kirtanvaghela" => "135005218+sw-tt-kirtanvaghela@users.noreply.github.com" }

  # spec.platform     = :ios
  # spec.platform     = :ios, "10.0"


  spec.source       = { :git => "https://github.com/sw-tt-kirtanvaghela/TestPod.git", :tag => "v1.0.0" }

  spec.source_files  = "IoTConnect2/**/*"
  # spec.exclude_files = "Classes/Exclude"

  # spec.public_header_files = "Classes/**/*.h"

    spec.dependency "CocoaMQTT"
    spec.swift_version = "5.0"

end
