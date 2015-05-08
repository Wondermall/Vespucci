//
//  AppDelegate.m
//  Vespucci
//
//  Created by CocoaPods on 04/08/2015.
//  Copyright (c) 2014 Sash Zats. All rights reserved.
//

#import "AppDelegate.h"

#import "NavigationService.h"
#import <Vespucci/VSPNavigationManager.h>


@interface AppDelegate ()

@end


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window.tintColor = [UIColor whiteColor];
    
#ifdef DEBUG
    // Just for the purpose of the demo
    [[NSNotificationCenter defaultCenter] addObserverForName:VSPNavigationManagerDidFinishNavigationNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        VSPNavigationNode *node = note.userInfo[VSPNavigationManagerNotificationNodeKey];
        NSLog(@"Navigation manager did finish navigation.\nNode: %@\nParameters: %@", node.root, note.userInfo[VSPNavigationManagerNotificationParametersKey]);
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:VSPNavigationManagerDidFailNavigationNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        NSLog(@"Navigation manager did FAIL navigation.\nNode: %@\nParameters: %@", note.userInfo[VSPNavigationManagerNotificationNodeKey], note.userInfo[VSPNavigationManagerNotificationParametersKey]);
    }];
#endif
    
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [[NavigationService sharedService] handleURL:url];
}

@end
