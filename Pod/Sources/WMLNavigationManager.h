//
//  WMLNavigationManager.h
//  Wondermall
//
//  Created by Sash Zats on 3/30/15.
//  Copyright (c) 2015 Wondermall Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMLNavigationNode.h"


@class JLRoutes;
typedef WMLNavigationNode *(^WMLNavigationRouteFactory)(NSDictionary *parameters);


@interface WMLNavigationManager : NSObject

@property (nonatomic, readonly) JLRoutes *router;

@property (nonatomic) WMLNavigationNode *root;

@property (nonatomic, readonly) NSURL *URL;

- (instancetype)initWithURLScheme:(NSString *)URLScheme NS_DESIGNATED_INITIALIZER;

- (void)registerNavigationForRoute:(NSString *)string handler:(WMLNavigationNode *(^)(NSDictionary *parameters))handler;

- (BOOL)handleURL:(NSURL *)URL;

@end

