platform :ios, '9.0'
use_frameworks!

target 'WWDCCompanion' do
    pod 'Fuzi', '~> 1.0.0'
    pod 'GRMustache.swift', '~> 2.0.0'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |configuration|
            configuration.build_settings['SWIFT_VERSION'] = "3.2"
        end
    end
end
