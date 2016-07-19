//
//  VSPNavigationManager.h
//  Wondermall
//
//  Created by Sash Zats on 3/30/15.
//  Copyright (c) 2015 Wondermall Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "VSPNavigationNode.h"


typedef void(^VSPNavigatonTransitionCompletion)(BOOL finished);


extern NSString *const VSPNavigationManagerWillNavigateNotification;
extern NSString *const VSPNavigationManagerDidFinishNavigationNotification;
extern NSString *const VSPNavigationManagerDidFailNavigationNotification;
extern NSString *const VSPNavigationManagerNotificationDestinationNodeKey;
extern NSString *const VSPNavigationManagerNotificationSourceNodeKey;

extern NSString *const VSPHostingRuleAnyNodeId;

@class JLRoutes;
@class RACSignal;
@interface VSPNavigationManager : NSObject

@property (nonatomic, readonly) JLRoutes *router;

@property (nonatomic, readonly) VSPNavigationNode *root;

- (instancetype)initWithURLScheme:(NSString *)URLScheme NS_DESIGNATED_INITIALIZER;

- (BOOL)handleURL:(NSURL *)URL;

- (void)navigateToURL:(NSURL *)URL completion:(VSPNavigatonTransitionCompletion)completion;

- (BOOL)navigateWithNewNavigationTree:(VSPNavigationNode *)tree completion:(VSPNavigatonTransitionCompletion)completion;

@end


@interface VSPNavigationManager (Compatibility)

// TODO: Refactor me into a regular setter of root property
- (void)setNavigationRoot:(VSPNavigationNode *)navigationRoot;

@end




typedef void(^VSPNavigationNodeViewControllerMountHandler)(VSPNavigationNode *parent, VSPNavigationNode *child, BOOL animated, VSPNavigatonTransitionCompletion completion);

typedef void(^VSPNavigationNodeViewControllerDismountHandler)(VSPNavigationNode *parent, VSPNavigationNode *child, BOOL animated, VSPNavigatonTransitionCompletion completion);

typedef UIViewController *(^VSPViewControllerFactory)(VSPNavigationNode *node);


@interface VSPNavigationManager (NodeHosting)

- (void)registerNavigationForRoute:(NSString *)route handler:(VSPNavigationNode *(^)(NSDictionary *parameters))handler;

- (void)addRuleForHostNodeId:(NSString *)hostNodeId childNodeId:(NSString *)childNodeId mountBlock:(VSPNavigationNodeViewControllerMountHandler)mountBlock unmounBlock:(VSPNavigationNodeViewControllerDismountHandler)dismountBlock;

/*
 * Allows you to register view controller factory called upon node with specified
 * id is about to be inserted into navigation stack.
 */
- (void)registerFactoryForNodeId:(NSString *)nodeId factory:(VSPViewControllerFactory)factory;

@end