Pod::Spec.new do |s|
	s.name         = "DarklyEventSource"
	s.version      = "1.2.0"
	s.summary      = "HTML5 Server-Sent Events in your Cocoa app."
	s.homepage     = "https://github.com/launchdarkly/ios-eventsource"
	s.license      = 'MIT (see LICENSE.txt)'
	s.author       = { "Neil Cowburn" => "git@neilcowburn.com" }
	s.source       = { :git => "https://github.com/launchdarkly/ios-eventsource.git", :tag => "1.2.0" }
	s.source_files = 'EventSource', 'EventSource/EventSource.{h,m}'
	s.ios.deployment_target = '5.0'
	s.requires_arc = true
	s.xcconfig = { 'OTHER_LDFLAGS' => '-lobjc' }
end
