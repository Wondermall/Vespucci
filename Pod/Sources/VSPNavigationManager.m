//
//  VSPNavigationManager.m
//  Wondermall
//
//  Created by Sash Zats on 3/30/15.
//  Copyright (c) 2015 Wondermall Inc. All rights reserved.
//

#import "VSPNavigationManager.h"

#import "NSError+Vespucci.h"
#import "VSPNavigationNode.h"
#import <JLROutes/JLRoutes.h>
#import <ReactiveCocoa/RACExtScope.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "VSPNavigationManager.h"


NSString *const VSPNavigationManagerDidFinishNavigationNotification = @"VSPNavigationManagerDidFinishNavigationNotification";
NSString *const VSPNavigationManagerDidFailNavigationNotification = @"VSPNavigationManagerDidFailNavigationNotification";
NSString *const VSPNavigationManagerNotificationNodeKey = @"VSPNavigationManagerNotificationNodeKey";
NSString *const VSPNavigationManagerNotificationParametersKey = @"VSPNavigationManagerNotificationParametersKey";


@interface __VSPMountingTuple : NSObject

+ (instancetype)tupleWithMountBlock:(VSPNavigationNodeViewControllerMountHandler)mountBlock dismountBlock:(VSPNavigationNodeViewControllerDismountHandler)dismountBlock;

@property (nonatomic, copy) VSPNavigationNodeViewControllerMountHandler mountHandler;

@property (nonatomic, copy) VSPNavigationNodeViewControllerDismountHandler dismountHandler;

@end


@implementation __VSPMountingTuple

+ (instancetype)tupleWithMountBlock:(VSPNavigationNodeViewControllerMountHandler)mountBlock dismountBlock:(VSPNavigationNodeViewControllerDismountHandler)dismountBlock {
    __VSPMountingTuple *tuple = [[self alloc] init];
    tuple.mountHandler = mountBlock;
    tuple.dismountHandler = dismountBlock;
    return tuple;
}

@end


@interface VSPNavigationManager (NodeHostingInternal)

- (BOOL)_getHost:(inout VSPNavigationNode **)inOutParent forChild:(inout VSPNavigationNode **)inOutChild;

- (RACSignal *)_makeHostNode:(inout VSPNavigationNode **)host hostChildNode:(inout VSPNavigationNode **)child animated:(BOOL)animated;

@end


@interface VSPNavigationManager ()

@property (nonatomic) JLRoutes *router;

@property (nonatomic) NSURL *URL;

@property (nonatomic) VSPNavigationNode *root;

@property (nonatomic) NSMutableDictionary *hostingRules;

@end


@implementation VSPNavigationManager

#pragma mark - Lifecycle

- (instancetype)initWithURLScheme:(NSString *)URLScheme {
    NSParameterAssert(URLScheme);
    self = [super init];
    if (!self) {
        return nil;
    }

    // just in case
    JLRoutes *router = [JLRoutes routesForScheme:URLScheme];
    [router removeAllRoutes];
    self.router = router;

    self.URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://", URLScheme]];

    self.hostingRules = [NSMutableDictionary dictionary];

    return self;
}

- (instancetype)init {
    return [self initWithURLScheme:nil];
}

#pragma mark - Public

- (BOOL)handleURL:(NSURL *)URL {
    // TODO: add support for relative URLs here
    if ([self.URL isEqual:URL]) {
        return YES;
    }
    BOOL didNavigate = [self.router routeURL:URL];
    if (didNavigate) {
        self.URL = URL;
    }
    return didNavigate;
}

#pragma mark - Private

- (void)_navigationWithNode:(VSPNavigationNode *)child parameters:(NSDictionary *)parameters {
    NSAssert(self.root, @"No root node installed");
    BOOL animated = NO;
    if (parameters[@"animated"]) {
        NSString *animatedString = [parameters[@"animated"] lowercaseString];
        animated = [animatedString isEqual:@"true"] || [animatedString isEqual:@"yes"] || [animatedString isEqual:@"1"];
    }
    @weakify(self);
    VSPNavigationNode *proposedRoot = self.root;
    VSPNavigationNode *proposedChild = child;
    RACSignal *makeHost = [self _makeHostNode:&proposedRoot hostChildNode:&proposedChild animated:animated];
    [makeHost subscribeError:^(NSError *error) {
        @strongify(self);
        [self _postNotificationNamed:VSPNavigationManagerDidFailNavigationNotification node:proposedChild.leaf parameters:parameters];
    } completed:^{
        @strongify(self);
        [self _postNotificationNamed:VSPNavigationManagerDidFinishNavigationNotification node:proposedChild.leaf parameters:parameters];
    }];
}

- (void)_postNotificationNamed:(NSString *)notificationName node:(VSPNavigationNode *)node parameters:(NSDictionary *)parameters {
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self userInfo:@{
            VSPNavigationManagerNotificationNodeKey : node ?: [NSNull null],
            VSPNavigationManagerNotificationParametersKey : parameters ?: [NSNull null]
    }];
}

- (void)_notifyNavigationDidFinishForNode:(VSPNavigationNode *)node parameters:(NSDictionary *)parameters {
    [[NSNotificationCenter defaultCenter] postNotificationName:VSPNavigationManagerDidFinishNavigationNotification object:self userInfo:@{
            VSPNavigationManagerNotificationNodeKey : node ?: [NSNull null],
            VSPNavigationManagerNotificationParametersKey : parameters ?: [NSNull null]
    }];
}

@end


@implementation VSPNavigationManager (NodeHosting)

#pragma mark - Public

- (void)registerNavigationForRoute:(NSString *)route handler:(VSPNavigationNode *(^)(NSDictionary *))handler {
    @weakify(self);
    [self.router addRoute:route handler:^BOOL(NSDictionary *parameters) {
        VSPNavigationNode *node = handler(parameters);
        if (!node) {
            return NO;
        }
        @strongify(self);
        NSAssert(node.viewController, @"No view controller provided, this can't be good!");
        [self _navigationWithNode:node parameters:parameters];
        return YES;
    }];
}

- (void)addRuleForHostNodeId:(NSString *)hostNodeId childNodeId:(NSString *)childNodeId mountBlock:(VSPNavigationNodeViewControllerMountHandler)mountBlock dismounBlock:(VSPNavigationNodeViewControllerDismountHandler)dismountBlock {
    NSMutableDictionary *hostRules = [self _rulesForHostNodeId:hostNodeId];
    hostRules[childNodeId] = [__VSPMountingTuple tupleWithMountBlock:mountBlock dismountBlock:dismountBlock];
}

#pragma mark - Private

- (NSMutableDictionary *)_rulesForHostNodeId:(NSString *)hostNodeId {
    return self.hostingRules[hostNodeId] ?: (self.hostingRules[hostNodeId] = [NSMutableDictionary dictionary]);
}

- (__VSPMountingTuple *)_tupleForHostNodeId:(NSString *)hostNodeId childNodeId:(NSString *)childNodeId {
    if (!hostNodeId || !childNodeId) {
        return nil;
    }
    return self.hostingRules[hostNodeId][childNodeId];
}

@end


@implementation VSPNavigationManager (NodeHostingInternal)

- (BOOL)_getHost:(inout VSPNavigationNode **)inOutParent forChild:(inout VSPNavigationNode **)inOutChild {
    if (!inOutParent || !*inOutParent || !inOutChild || !*inOutChild) {
        return NO;
    }
    VSPNavigationNode *child = *inOutChild;
    VSPNavigationNode *parent = *inOutParent;
    if ([parent.nodeId isEqualToString:child.nodeId]) {
        VSPNavigationNode *proposedParent = parent.child;
        VSPNavigationNode *grandchild = child.child;
        if ([self _getHost:&proposedParent forChild:&grandchild]) {
            *inOutParent = proposedParent;
            *inOutChild = grandchild;
            return YES;
        } else if ([self _getHost:inOutParent forChild:&grandchild]) {
            *inOutChild = grandchild;
            return YES;
        }
    } else if ([self _canParent:parent hostChild:child]) {
        *inOutParent = parent;
        *inOutChild = child;
        return YES;
    }
    return NO;
}

- (BOOL)_canParent:(VSPNavigationNode *)parent hostChild:(VSPNavigationNode *)child {
    return [self _tupleForHostNodeId:parent.nodeId childNodeId:child.nodeId] != nil;
}

- (RACSignal *)_makeHostNode:(VSPNavigationNode **)host hostChildNode:(VSPNavigationNode **)child animated:(BOOL)animated {
    RACSubject *subject = [RACSubject subject];

    // Calculate actual host and actual child
    VSPNavigationNode *proposedChild = (*child).root;
    VSPNavigationNode *proposedHost = (*host).root;
    if (![self _getHost:&proposedHost forChild:&proposedChild]) {
        [subject sendError:[NSError vsp_vespucciErrorWithCode:0 message:@"Failed to find the host for %@", *child]];
        return subject;
    }

    // Update original pointers with calculated host and child
    *child = proposedChild;
    *host = proposedHost;
    
    RACSignal *dismount = [self _dismountForHost:proposedHost animated:animated];
    dismount = [dismount doCompleted:^{
        proposedHost.child = proposedChild;
    }];

    RACSignal *mount = [self _mountForHost:proposedHost newChild:proposedChild animated:animated];
    [[dismount
        concat:mount]
        subscribe:subject];
    return [subject replayLast];
}

- (RACSignal *)_dismountForHost:(VSPNavigationNode *)host animated:(BOOL)animated {
    if (!host.child) {
        return [RACSignal empty];
    }

    RACSignal *result = nil;
    VSPNavigationNode *currentHost = host.leaf;
    do {
        currentHost = currentHost.parent;
        
        __VSPMountingTuple *tuple = [self _tupleForHostNodeId:currentHost.nodeId childNodeId:currentHost.child.nodeId];
        NSAssert(tuple, @"No tuple found for pair host: %@; child: %@", currentHost, currentHost.child);
        VSPNavigationNodeViewControllerDismountHandler dismountBlock = tuple.dismountHandler;
        NSAssert(dismountBlock, @"Don't know how to dismount current child %@", host.child);
        RACSignal *dismount = dismountBlock(host.viewController, host.child.viewController, animated) ?: [RACSignal empty];
        dismount = dismount ?: [RACSignal empty];
        if (result) {
            result = [result concat:dismount];
        } else {
            result = dismount;
        }
        
    } while (![currentHost isEqual:host]);

    return result;
}

- (RACSignal *)_mountForHost:(VSPNavigationNode *)host newChild:(VSPNavigationNode *)child animated:(BOOL)animated {
    RACSignal *result = nil;

    while (child) {
        __VSPMountingTuple *tuple = [self _tupleForHostNodeId:host.nodeId childNodeId:child.nodeId];
        VSPNavigationNodeViewControllerMountHandler mountBlock = tuple.mountHandler;
        NSAssert(!child || mountBlock, @"Don't know hot to mount new child %@", child);
        
        if (!result) {
            result = mountBlock(host.viewController, child.viewController, animated) ?: [RACSignal empty];
        } else {
            RACSignal *mount = mountBlock(host.viewController, child.viewController, animated) ?: [RACSignal empty];
            result = [result concat:mount];
        }

        host = child;
        child = child.child;        
    }
    return result;
}

@end


@implementation VSPNavigationManager (Compatibility)

- (void)setNavigationRoot:(VSPNavigationNode *)navigationRoot URL:(NSURL *)URL {
    self.root = navigationRoot;
    self.URL = URL;
}

@end
