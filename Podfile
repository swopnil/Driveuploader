platform :ios, '15.0'
target 'Driveuploader' do
  use_frameworks!
  
  pod 'GoogleSignIn'
  pod 'GoogleAPIClientForREST'  # Changed this line
  pod 'GoogleAPIClientForREST/Drive'  # Keep this line too
  pod 'GTMSessionFetcher'  # Add this line
  
  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
        config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
        config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      end
    end
  end
end