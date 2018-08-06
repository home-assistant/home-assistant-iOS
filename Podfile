# Uncomment this line to define a global platform for your project
platform :ios, '10.3'
# Uncomment this line if you're using Swift
use_frameworks!

plugin 'cocoapods-acknowledgements'

target 'HomeAssistant' do
  pod 'Alamofire', '4.7.3'
  pod 'AlamofireNetworkActivityIndicator', '2.2.1'
  pod 'AlamofireObjectMapper', '5.1.0'
  pod 'CPDAcknowledgements', '1.0.0'
  # pod 'Crashlytics' - Re-enable on next Xcode beta and BEFORE release
  pod 'DeviceKit', '1.7.0'
  pod 'Eureka', '4.2.0'
  # pod 'Fabric' - Re-enable on next Xcode beta and BEFORE release
  pod 'FontAwesomeKit/MaterialDesignIcons', :git => 'https://github.com/robbiet480/FontAwesomeKit.git', :branch => 'Material-Design-Icons'
  pod 'KeychainAccess', '3.1.1'
  pod 'MBProgressHUD', '1.1.0'
  pod 'ObjectMapper', '3.3.0'
  pod 'PromiseKit', '6.3.4'
  pod 'RealmSwift', '3.7.5'
  pod 'SwiftGen', '5.3.0'
  pod 'SwiftLint', '0.27.0'

  target 'HomeAssistantTests' do
    inherit! :search_paths
  end
end

target 'Shared' do
  pod 'RealmSwift', '3.7.5'
  target 'SharedTests' do
    inherit! :search_paths
  end
end


target 'HomeAssistantUITests' do

end

target 'APNSAttachmentService' do
  pod 'KeychainAccess', '3.1.1'
  pod 'RealmSwift', '3.7.5'
end

target 'MapNotificationContentExtension' do
  pod 'MBProgressHUD', '1.1.0'
  pod 'RealmSwift', '3.7.5'
end


target 'NotificationContentExtension' do
  pod 'KeychainAccess', '3.1.1'
  pod 'MBProgressHUD', '1.1.0'
  pod 'RealmSwift', '3.7.5'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    if ['AlamofireNetworkActivityIndicator', 'AlamofireObjectMapper', 'DeviceKit', 'Eureka', 'ObjectMapper', 'PromiseKit'].include? target.name
      target.build_configurations.each do |config|
        config.build_settings['SWIFT_VERSION'] = '4.0'
      end
    end
  end
end
