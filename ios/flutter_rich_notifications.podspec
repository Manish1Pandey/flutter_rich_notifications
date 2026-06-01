Pod::Spec.new do |s|
  s.name             = 'flutter_rich_notifications'
  s.version          = '0.1.0'
  s.summary          = 'Hero image + full multi-line body push notifications for Android and iOS.'
  s.description      = <<-DESC
Display Android and iOS push notifications with a full hero image AND
full multi-line body text. Uses custom RemoteViews on Android and a
Notification Content Extension on iOS to bypass the stock notification
style limits.
                       DESC
  s.homepage         = 'https://github.com/Manish1Pandey/flutter_rich_notifications'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Manish Pandey' => 'manish1pandey@github.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
