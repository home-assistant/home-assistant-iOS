use_frameworks!
inhibit_all_warnings!

project 'HomeAssistant', 'Debug' => :debug, 'Release' => :release, 'Beta' => :release
plugin 'cocoapods-acknowledgements'

if not File.exist?("Tools/MaterialDesignIcons.ttf")
    puts "Didn't find Tools/MaterialDesignIcons.ttf, downloading and building now"
    system("./Tools/BuildMaterialDesignIconsFont.sh")
else
    puts "Tools/MaterialDesignIcons.ttf already exists"
end

# Set FONT_PATH and CUSTOM_FONT_NAME variables for MDI
puts "Setting FONT_PATH to '#{File.expand_path('./Tools/MaterialDesignIcons.ttf')}'"
ENV['FONT_PATH'] = File.expand_path('./Tools/MaterialDesignIcons.ttf')
puts "Setting CUSTOM_FONT_NAME to 'MaterialDesignIcons'"
ENV['CUSTOM_FONT_NAME'] = 'MaterialDesignIcons'
pod 'Alamofire', '~> 4.0'
pod 'Communicator', '~> 3.3.0'
#pod 'Iconic', :git => 'https://github.com/home-assistant/Iconic.git', :branch => 'master'
pod 'KeychainAccess'
pod 'ObjectMapper', :git => 'https://github.com/tristanhimmelman/ObjectMapper.git', :branch => 'master'
pod 'PromiseKit'
pod 'UIColor_Hex_Swift'
pod 'Version'
pod 'XCGLogger'

def test_pods
    pod 'OHHTTPStubs/Swift'
end

abstract_target 'iOS' do
    platform :ios, '11.0'

    pod 'MBProgressHUD', '~> 1.2.0'
    pod 'ReachabilitySwift'

    target 'Shared-iOS' do
        target 'Tests-Shared' do
            inherit! :search_paths
            test_pods
        end
    end

    target 'App' do
        pod 'CallbackURLKit'
        pod 'ColorPickerRow', :git => 'https://github.com/EurekaCommunity/ColorPickerRow', :branch => 'master'
        pod 'CPDAcknowledgements', :git => 'https://github.com/CocoaPods/CPDAcknowledgements', :branch => 'master'
        pod 'Eureka', :git => 'https://github.com/xmartlabs/Eureka.git', :branch => 'xcode12'
        pod 'Firebase/Messaging'
        pod 'Lokalise', '~> 0.10.0'
        pod 'lottie-ios'
        pod 'Sentry'
        pod 'SimulatorStatusMagic', :configurations => ['Debug']
        pod 'SwiftGen', '~> 6.3.0'
        pod 'SwiftLint'
        pod 'SwiftMessages', :git => 'https://github.com/SwiftKickMobile/SwiftMessages.git', :branch => 'master'
        pod 'ViewRow', :git => 'https://github.com/EurekaCommunity/ViewRow', :branch => 'master'
        pod 'WhatsNewKit'
        pod 'ZIPFoundation', '~> 0.9'

        target 'Tests-App' do
            inherit! :search_paths
            test_pods
        end
    end

    target 'Extensions-Intents'
    target 'Extensions-NotificationContent'
    target 'Extensions-NotificationService'
    target 'Extensions-Share'
    target 'Extensions-Today'
    target 'Extensions-Widgets'
end

abstract_target 'watchOS' do
    platform :watchos, '5.0'

    target 'Shared-watchOS'

    target 'WatchExtension-Watch' do
        pod 'EMTLoadingIndicator', :git => 'https://github.com/hirokimu/EMTLoadingIndicator', :branch => 'master'
    end
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            xcconfig_path = config.base_configuration_reference.real_path
            xcconfig = File.read(xcconfig_path)
            xcconfig.sub!('-framework "Lokalise"', '')
            File.open(xcconfig_path, "w") { |file| file << xcconfig }

            config.build_settings['WATCHOS_DEPLOYMENT_TARGET'] = '5.0'
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '11.0'
            config.build_settings['EXCLUDED_ARCHS[sdk=watchsimulator*]'] = 'x86_64 arm64'
        end

        # Fix bundle targets' 'Signing Certificate' to 'Sign to Run Locally'
        # (catalyst fix)
        if target.respond_to?(:product_type) and target.product_type == "com.apple.product-type.bundle"
            target.build_configurations.each do |config|
                config.build_settings['CODE_SIGN_IDENTITY[sdk=macosx*]'] = '-'
            end
        end
    end
end
