#
# Be sure to run `pod lib lint Vespucci.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "Vespucci"
  s.version          = "0.5.3"
  s.summary          = "Navigation microframework"
  s.description      = <<-DESC
                        Routing made simple. Not only for UINavigationController.

                        1. Register a route.
                        2. Explain how to present a view controller.
                        3. Explain how to dismiss it.

                        That's it. Framework takes care of all the transition permutations!
                       DESC
  s.homepage         = "https://github.com/Wondermall/Vespucci"
  s.license          = 'MIT'
  s.author           = { "Sash Zats" => "sash@zats.io" }
  s.source           = { :git => "https://github.com/Wondermall/Vespucci.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/zats'
  s.platform     = :ios
  s.ios.deployment_target = '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Sources/**/*'
  s.dependency 'JLRoutes', '~> 1.6'
end
