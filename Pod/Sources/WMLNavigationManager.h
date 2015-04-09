//
//  WMLNavigationManager.h
//  Wondermall
//
//  Created by Sash Zats on 3/30/15.
//  Copyright (c) 2015 Wondermall Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMLNavigationNode.h"


extern NSString *const WMLNavigationManagerDidFinishNavigationNotification;
extern NSString *const WMLNavigationManagerDidFailNavigationNotification;
extern NSString *const WMLNavigationManagerNotificationNodeKey;
extern NSString *const WMLNavigationManagerNotificationParametersKey;


@class JLRoutes;
@interface WMLNavigationManager : NSObject

@property (nonatomic, readonly) JLRoutes *router;

@property (nonatomic, readonly) WMLNavigationNode *navigationRoot;

@property (nonatomic, readonly) NSURL *URL;

- (instancetype)initWithURLScheme:(NSString *)URLScheme NS_DESIGNATED_INITIALIZER;

- (BOOL)handleURL:(NSURL *)URL;

@end


@interface WMLNavigationManager (Compatibility)

- (void)setNavigationRoot:(WMLNavigationNode *)navigationRoot URL:(NSURL *)URL;

@end


@class RACSignal;

typedef RACSignal *(^WMLNavigationNodeViewControllerMountHandler)(UIViewController *parent, UIViewController *child, BOOL animated);
typedef RACSignal *(^WMLNavigationNodeViewControllerDismountHandler)(UIViewController *parent, UIViewController *child, BOOL animated);


@interface WMLNavigationManager (NodeHosting)

- (void)registerNavigationForRoute:(NSString *)string handler:(WMLNavigationNode *(^)(NSDictionary *parameters))handler;

- (void)addRuleForHostNodeId:(NSString *)hostNodeId childNodeId:(NSString *)childNodeId mountBlock:(WMLNavigationNodeViewControllerMountHandler)mountBlock dismounBlock:(WMLNavigationNodeViewControllerDismountHandler)dismountBlock;

@end