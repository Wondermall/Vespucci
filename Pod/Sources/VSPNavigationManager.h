//
//  VSPNavigationManager.h
//  Wondermall
//
//  Created by Sash Zats on 3/30/15.
//  Copyright (c) 2015 Wondermall Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "VSPNavigationNode.h"


extern NSString *const VSPNavigationManagerDidFinishNavigationNotification;
extern NSString *const VSPNavigationManagerDidFailNavigationNotification;
extern NSString *const VSPNavigationManagerNotificationNodeKey;
extern NSString *const VSPNavigationManagerNotificationParametersKey;


@class JLRoutes;
@class RACSignal;
@interface VSPNavigationManager : NSObject

@property (nonatomic, readonly) JLRoutes *router;

@property (nonatomic, readonly) VSPNavigationNode *root;

@property (nonatomic, readonly) NSURL *URL;

- (instancetype)initWithURLScheme:(NSString *)URLScheme NS_DESIGNATED_INITIALIZER;

- (BOOL)handleURL:(NSURL *)URL;

- (RACSignal *)navigateWithNewNavigationTree:(VSPNavigationNode *)tree;

@end


@interface VSPNavigationManager (Compatibility)

- (void)setNavigationRoot:(VSPNavigationNode *)navigationRoot URL:(NSURL *)URL;

@end


typedef RACSignal *(^VSPNavigationNodeViewControllerMountHandler)(UIViewController *parent, UIViewController *child, BOOL animated);

typedef RACSignal *(^VSPNavigationNodeViewControllerDismountHandler)(UIViewController *parent, UIViewController *child, BOOL animated);


@interface VSPNavigationManager (NodeHosting)

- (void)registerNavigationForRoute:(NSString *)string handler:(VSPNavigationNode *(^)(NSDictionary *parameters))handler;

- (void)addRuleForHostNodeId:(NSString *)hostNodeId childNodeId:(NSString *)childNodeId mountBlock:(VSPNavigationNodeViewControllerMountHandler)mountBlock dismounBlock:(VSPNavigationNodeViewControllerDismountHandler)dismountBlock;

@end