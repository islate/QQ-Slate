
Pod::Spec.new do |s|

  s.name         = "QQ-Slate"
  s.version      = "0.1.1"
  s.summary      = "Slate QQ Wrapper."


  s.description  = <<-DESC
		   Slate QQ Wrapper. SDK ver 0.1.1
	
                   DESC

  s.homepage     = "http://github.com/islate/QQ-Slate"
  s.license      = "Apache 2.0"
  s.author       = { "linyize" => "linyize@gmail.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "http://github.com/islate/QQ-Slate.git", :tag => "#{s.version}" }

  s.dependency 'TencentOpenApiSDK', '3.2.3.501'

  s.source_files  = 'TencentWrapper.*'

end
