Pod::Spec.new do |s|
	s.name         = "DarklyEventSource"
	s.version      = "1.3.0"
	s.summary      = "HTML5 Server-Sent Events in your Cocoa app."
	s.homepage     = "https://github.com/launchdarkly/ios-eventsource"
	s.license      = 'MIT (see LICENSE.txt)'
	s.author       = { "Neil Cowburn" => "git@neilcowburn.com" }
	s.source       = { :git => "https://github.com/launchdarkly/ios-eventsource.git", :tag => "1.3.0" }
	s.source_files = 'EventSource', 'EventSource/EventSource.{h,m}'
	s.ios.xcconfig = { 'FRAMEWORK_SEARCH_PATHS' => '$(inherited) "$(SDKROOT)/Developer/Library/Frameworks" "$(DEVELOPER_LIBRARY_DIR)/Frameworks"' }
	s.osx.xcconfig = { 'FRAMEWORK_SEARCH_PATHS' => '$(inherited) "$(DEVELOPER_LIBRARY_DIR)/Frameworks"' }
	s.ios.deployment_target = '8.0'
	s.osx.deployment_target = '10.7'
	s.watchos.deployment_target = '2.0'
	s.tvos.deployment_target = '9.0'
	s.requires_arc = true
	s.xcconfig = { 'OTHER_LDFLAGS' => '-lobjc' }
end
