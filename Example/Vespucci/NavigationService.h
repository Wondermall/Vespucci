//
// Created by Sash Zats on 4/8/15.
// Copyright (c) 2015 Sash Zats. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 * Node Identifiers
 */
extern NSString *const RootNodeId;
extern NSString *const MessagesNodeId;
extern NSString *const SingleMessageNodeId;
extern NSString *const NotificationsNodeId;
extern NSString *const ProfileNodeId;
extern NSString *const BlockUserNodeId;


static NSString *const AppSpecificURLScheme = @"vsp";


@interface NavigationService : NSObject

+ (instancetype)sharedService;

- (void)setupDefaultRoutesWithRootViewController:(UITabBarController *)tabController;

- (BOOL)handleURL:(NSURL *)url;

@end


@interface NavigationService (URLBuilder)

- (NSURL *)messagesURL;

- (NSURL *)messageURLForMessageId:(NSString *)userId;

- (NSURL *)picturesURLForPictureId:(NSString *)pictureId;

- (NSURL *)profileURLForUser:(NSString *)userId;

- (NSURL *)notificationsURL;

- (NSURL *)blockUserWithUserIdURL:(NSString *)userId;

@end


@interface NavigationService (Compatibility)

- (void)syncStateForRootController:(UITabBarController *)tabController;

// This doesn't sound safe at all
- (void)syncStateByRemovingLastNode;

@end