platform :ios, '18.0'  # Changed to match your iOS version

target 'Driveuploader' do
  use_frameworks!
  
  # Pods for Google Sign-In and Drive
  pod 'GoogleSignIn'
  pod 'GoogleAPIClientForREST/Drive'

  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        # Update this to 18.0 as well
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '18.0'
        # Keep this for M1 Mac compatibility
        config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
        # Add these for iOS 15+ compatibility
        config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
        config.build_settings['DEAD_CODE_STRIPPING'] = 'YES'
      end
    end
  end
end