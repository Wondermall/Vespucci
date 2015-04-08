//
//  AppDelegate.m
//  Vespucci
//
//  Created by CocoaPods on 04/08/2015.
//  Copyright (c) 2014 Sash Zats. All rights reserved.
//

#import "AppDelegate.h"

#import "NavigationService.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[NavigationService sharedService] registerRoutesWithRootViewController:self.window.rootViewController];
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [[NavigationService sharedService] handleURL:url];
}
@end
