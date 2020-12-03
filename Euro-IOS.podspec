#
# Be sure to run `pod lib lint Euro-IOS.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Euro-IOS'
  s.version          = '1.9.12'
  s.summary          = 'Euro IOS Framework'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://www.visilabs.com'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'egemen@visilabs.com' => 'egemen.gulkilik@relateddigital.com' }
  s.source           = { :git => 'https://github.com/visilabs/Euro-IOS.git', :tag => s.version.to_s }

  s.ios.deployment_target = '7.0'

  s.source_files = 'Euro-IOS/Classes/**/*'
  s.pod_target_xcconfig = { 'PRODUCT_BUNDLE_IDENTIFIER': 'com.euromsg.EuroFramework' }
  
end
