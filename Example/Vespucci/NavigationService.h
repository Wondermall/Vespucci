//
// Created by Sash Zats on 4/8/15.
// Copyright (c) 2015 Sash Zats. All rights reserved.
//

#import <Foundation/Foundation.h>


static NSString *const AppSpecificURLScheme = @"vsp";


@interface NavigationService : NSObject

+ (instancetype)sharedService;

- (void)registerRoutesWithRootViewController:(UIViewController *)rootViewController;

- (BOOL)handleURL:(NSURL *)url;

@end


@interface NavigationService (URLBuilder)

- (NSURL *)messagesURL;

- (NSURL *)messageURLForMessageId:(NSString *)userId;

- (NSURL *)picturesURLForPictureId:(NSString *)pictureId;

- (NSURL *)profileURLForUser:(NSString *)userId;

- (NSURL *)notificationsURL;

@end