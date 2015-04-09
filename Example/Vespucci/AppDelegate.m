//
//  AppDelegate.m
//  Vespucci
//
//  Created by CocoaPods on 04/08/2015.
//  Copyright (c) 2014 Sash Zats. All rights reserved.
//

#import "AppDelegate.h"

#import "NavigationService.h"
#import <Vespucci/WMLNavigationManager.h>


@interface AppDelegate ()

@end


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window.tintColor = [UIColor whiteColor];
    
    // We don't remove these observers from those only because this is a demo.
    
    [[NSNotificationCenter defaultCenter] addObserverForName:WMLNavigationManagerDidFinishNavigationNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        WMLNavigationNode *node = note.userInfo[WMLNavigationManagerNotificationNodeKey];
        NSLog(@"Navigation manager did finish navigation.\nNode: %@\nParameters: %@", node.root, note.userInfo[WMLNavigationManagerNotificationParametersKey]);
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:WMLNavigationManagerDidFailNavigationNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        NSLog(@"Navigation manager did FAIL navigation.\nNode: %@\nParameters: %@", note.userInfo[WMLNavigationManagerNotificationNodeKey], note.userInfo[WMLNavigationManagerNotificationParametersKey]);
    }];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [[NavigationService sharedService] handleURL:url];
}

@end
