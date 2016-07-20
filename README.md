# Vespucci

[![CI Status](http://img.shields.io/travis/Wondermall/Vespucci.svg?style=flat)](https://travis-ci.org/Wondermall/Vespucci)
[![Version](https://img.shields.io/cocoapods/v/Vespucci.svg?style=flat)](http://cocoapods.org/pods/Vespucci)
[![License](https://img.shields.io/cocoapods/l/Vespucci.svg?style=flat)](http://cocoapods.org/pods/Vespucci)
[![Platform](https://img.shields.io/cocoapods/p/Vespucci.svg?style=flat)](http://cocoapods.org/pods/Vespucci)

## Usage

```objectivec
VSPNavigationManager *manager = [[VSPNavigationManager alloc] initWithURLScheme:@"my-app"];

// Register the route matching URL my-app://home/posts/123xyz
[manager registerNavigationForRoute:@"/home/posts/:post_id" handler:^VSPNavigationNode *(NSDictionary *parameters) {
	VSPNavigationNode *root = [VSPNavigationNode rootNodeForParameters:parameters nodeIds:RootNodeId, NewsFeedNodeId, PostNodeId, nil];
	root.leaf.viewController = [PostViewController postViewControllerWithPostId:parameters[@"post_id"]];
	return root;
}];

// Define presentation and dismissal rules
[self addRuleForHostNodeId:NewsFeedNodeId childNodeId:PostNodeId mountBlock:^RACSignal *(VSPNavigationNode *parent, VSPNavigationNode *child) {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [parent.viewController presentViewController:child.viewController animated:animated completion:^{
            [subscriber sendCompleted];
        }];
        return nil;
    }];
} unmounBlock:^RACSignal *(VSPNavigationNode *parent, VSPNavigationNode *child) {
	return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
		[child.viewController dismissViewControllerAnimated:animated completion:^(BOOL finished){
			[subscriber sendCompleted];
		}]
        return nil;
    }];
}];
```

Please see the example project for details.

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

Vespucci is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "Vespucci"
```

## Author

Sash Zats, sash@zats.io

## License

Vespucci is available under the MIT license. See the LICENSE file for more info.
