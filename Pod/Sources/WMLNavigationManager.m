//
//  WMLNavigationManager.m
//  Wondermall
//
//  Created by Sash Zats on 3/30/15.
//  Copyright (c) 2015 Wondermall Inc. All rights reserved.
//

#import "WMLNavigationManager.h"

#import "NSError+Vespucci.h"
#import "WMLNavigationNode.h"
#import <JLROutes/JLRoutes.h>
#import <ReactiveCocoa/RACExtScope.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <Vespucci/WMLNavigationManager.h>


NSString *const WMLNavigationManagerDidFinishNavigationNotification = @"WMLNavigationManagerDidFinishNavigationNotification";
NSString *const WMLNavigationManagerDidFailNavigationNotification = @"WMLNavigationManagerDidFailNavigationNotification";
NSString *const WMLNavigationManagerNotificationNodeKey = @"WMLNavigationManagerNotificationNodeKey";
NSString *const WMLNavigationManagerNotificationParametersKey = @"WMLNavigationManagerNotificationParametersKey";


@interface __WMLMountingTuple : NSObject

+ (instancetype)tupleWithMountBlock:(WMLNavigationNodeViewControllerMountHandler)mountBlock dismountBlock:(WMLNavigationNodeViewControllerDismountHandler)dismountBlock;

@property (nonatomic, copy) WMLNavigationNodeViewControllerMountHandler mountHandler;

@property (nonatomic, copy) WMLNavigationNodeViewControllerDismountHandler dismountHandler;

@end


@implementation __WMLMountingTuple

+ (instancetype)tupleWithMountBlock:(WMLNavigationNodeViewControllerMountHandler)mountBlock dismountBlock:(WMLNavigationNodeViewControllerDismountHandler)dismountBlock {
    __WMLMountingTuple *tuple = [[self alloc] init];
    tuple.mountHandler = mountBlock;
    tuple.dismountHandler = dismountBlock;
    return tuple;
}

@end


@interface WMLNavigationManager (NodeHostingInternal)

- (BOOL)_getHost:(inout WMLNavigationNode **)inOutParent forChild:(inout WMLNavigationNode **)inOutChild;

- (RACSignal *)_makeHostNode:(inout WMLNavigationNode **)host hostChildNode:(inout WMLNavigationNode **)child animated:(BOOL)animated;

@end


@interface WMLNavigationManager ()

@property (nonatomic) JLRoutes *router;

@property (nonatomic) NSURL *URL;

@property (nonatomic) WMLNavigationNode *navigationRoot;

@property (nonatomic) NSMutableDictionary *hostingRules;

@end


@implementation WMLNavigationManager

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
        return NO;
    }
    BOOL didNavigate = [self.router routeURL:URL];
    if (didNavigate) {
        self.URL = URL;
    }
    return didNavigate;
}

#pragma mark - Private

- (void)_navigationWithNode:(WMLNavigationNode *)child parameters:(NSDictionary *)parameters {
    NSAssert(self.navigationRoot, @"No root node installed");
    BOOL animated = NO;
    if (parameters[@"animated"]) {
        NSString *animatedString = [parameters[@"animated"] lowercaseString];
        animated = [animatedString isEqual:@"true"] || [animatedString isEqual:@"yes"] || [animatedString isEqual:@"1"];
    }
    @weakify(self);
    WMLNavigationNode *proposedRoot = self.navigationRoot;
    WMLNavigationNode *proposedChild = child;
    RACSignal *makeHost = [self _makeHostNode:&proposedRoot hostChildNode:&proposedChild animated:animated];
    [makeHost subscribeError:^(NSError *error) {
        @strongify(self);
        [self _postNotificationNamed:WMLNavigationManagerDidFailNavigationNotification node:proposedChild.leaf parameters:parameters];
    } completed:^{
        @strongify(self);
        [self _postNotificationNamed:WMLNavigationManagerDidFinishNavigationNotification node:proposedChild.leaf parameters:parameters];
    }];
}

- (void)_postNotificationNamed:(NSString *)notificationName node:(WMLNavigationNode *)node parameters:(NSDictionary *)parameters {
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self userInfo:@{
        WMLNavigationManagerNotificationNodeKey: node ?: [NSNull null],
        WMLNavigationManagerNotificationParametersKey: parameters ?: [NSNull null]
    }];
}

- (void)_notifyNavigationDidFinishForNode:(WMLNavigationNode *)node parameters:(NSDictionary *)parameters {
    [[NSNotificationCenter defaultCenter] postNotificationName:WMLNavigationManagerDidFinishNavigationNotification object:self userInfo:@{
        WMLNavigationManagerNotificationNodeKey: node ?: [NSNull null],
        WMLNavigationManagerNotificationParametersKey: parameters ?: [NSNull null]
    }];
}

@end


@implementation WMLNavigationManager (NodeHosting)

#pragma mark - Public

- (void)registerNavigationForRoute:(NSString *)route handler:(WMLNavigationNode *(^)(NSDictionary *))handler {
    @weakify(self);
    [self.router addRoute:route handler:^BOOL(NSDictionary *parameters) {
        WMLNavigationNode *node = handler(parameters);
        if (!node) {
            return NO;
        }
        @strongify(self);
        NSAssert(node.viewController, @"No view controller provided, this can't be good!");
        [self _navigationWithNode:node parameters:parameters];
        return YES;
    }];
}

- (void)addRuleForHostNodeId:(NSString *)hostNodeId childNodeId:(NSString *)childNodeId mountBlock:(WMLNavigationNodeViewControllerMountHandler)mountBlock dismounBlock:(WMLNavigationNodeViewControllerDismountHandler)dismountBlock {
    NSMutableDictionary *hostRules = [self _rulesForHostNodeId:hostNodeId];
    hostRules[childNodeId] = [__WMLMountingTuple tupleWithMountBlock:mountBlock dismountBlock:dismountBlock];
}

#pragma mark - Private

- (NSMutableDictionary *)_rulesForHostNodeId:(NSString *)hostNodeId {
    return self.hostingRules[hostNodeId] ?: (self.hostingRules[hostNodeId] = [NSMutableDictionary dictionary]);
}

- (__WMLMountingTuple *)_tupleForHostNodeId:(NSString *)hostNodeId childNodeId:(NSString *)childNodeId {
    if (!hostNodeId || !childNodeId) {
        return nil;
    }
    return self.hostingRules[hostNodeId][childNodeId];
}

@end


@implementation WMLNavigationManager (NodeHostingInternal)

- (BOOL)_getHost:(inout WMLNavigationNode **)inOutParent forChild:(inout WMLNavigationNode **)inOutChild {
    if (!inOutParent || !*inOutParent || !inOutChild || !*inOutChild) {
        return NO;
    }
    WMLNavigationNode *child = *inOutChild;
    WMLNavigationNode *parent = *inOutParent;
    if ([parent containsSameDataAsNode:child]) {
        WMLNavigationNode *proposedParent = parent.child;
        WMLNavigationNode *grandchild = child.child;
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

- (BOOL)_canParent:(WMLNavigationNode *)parent hostChild:(WMLNavigationNode *)child {
    return [self _tupleForHostNodeId:parent.nodeId childNodeId:child.nodeId] != nil;
}

- (RACSignal *)_makeHostNode:(WMLNavigationNode **)host hostChildNode:(WMLNavigationNode **)child animated:(BOOL)animated {
    RACSubject *subject = [RACSubject subject];

    // Calculate actual host and actual child
    WMLNavigationNode *proposedChild = (*child).root;
    WMLNavigationNode *proposedHost = (*host).root;
    if (![self _getHost:&proposedHost forChild:&proposedChild]) {
        [subject sendError:[NSError wml_vespuciErrorWithCode:0 message:@"Failed to find the host for %@", *child]];
        return subject;
    }

    // Update original pointers with calculated host and child
    *child = proposedChild;
    *host = proposedHost;
    
    RACSignal *dismount = [self dismountForHost:proposedHost animated:animated];
    dismount = [dismount doCompleted:^{
        proposedHost.child = proposedChild;
        if ([proposedChild.viewController conformsToProtocol:@protocol(WMLNavigationParametrizedViewController)]) {
            ((id<WMLNavigationParametrizedViewController>)proposedChild.viewController).navigationNode = proposedChild;
        }
    }];

    RACSignal *mount = [self mountForHost:proposedHost newChild:proposedChild animated:animated];
    [[dismount
        concat:mount]
        subscribe:subject];
    return [subject replayLast];
}

- (RACSignal *)dismountForHost:(WMLNavigationNode *)host animated:(BOOL)animated {
    // TODO: should dismount all children not just immediate one
    // i.e. if there are popups or alerts or something like that, they won't disappear by dismounting immediate child
    if (!host.child) {
        return [RACSignal empty];
    }

    RACSignal *result = nil, *currentSignal = nil;
    WMLNavigationNode *currentHost = host.leaf.parent;
    do {
        __WMLMountingTuple *tuple = [self _tupleForHostNodeId:currentHost.nodeId childNodeId:currentHost.child.nodeId];
        WMLNavigationNodeViewControllerDismountHandler dismountBlock = tuple.dismountHandler;
        NSAssert(dismountBlock, @"Don't know how to dismount current child %@", host.child);
        RACSignal *dismount = dismountBlock(host.viewController, host.child.viewController, animated) ?: [RACSignal empty];
        dismount = dismount ?: [RACSignal empty];
        dismount.name = @"dismount";
        
        if (!result) {
            result = dismount;
        }
        if (currentSignal) {
            currentSignal = [currentSignal concat:dismount];
        } else {
            currentSignal = dismount;
        }
        
        currentHost = currentHost.parent;
    } while (![currentHost isEqual:host]);

    return currentSignal;
}

- (RACSignal *)mountForHost:(WMLNavigationNode *)host newChild:(WMLNavigationNode *)child animated:(BOOL)animated {
    RACSignal *result = nil, *currentSignal = nil;

    while (child) {
        __WMLMountingTuple * tuple = [self _tupleForHostNodeId:host.nodeId childNodeId:child.nodeId];
        WMLNavigationNodeViewControllerMountHandler mountBlock = tuple.mountHandler;
        NSAssert(!child || mountBlock, @"Don't know hot to mount new child %@", child);
        // TODO: mount children recursively not just the first one
        RACSignal *mount = mountBlock(host.viewController, child.viewController, animated) ?: [RACSignal empty];
        mount.name = @"mount";
        if (!result) {
            result = mount;
        }
        if (currentSignal) {
            currentSignal = [currentSignal concat:mount];
        } else {
            currentSignal = mount;
        }

        host = child;
        child = child.child;        
    }
    return result;
}

@end


@implementation WMLNavigationManager (Compatibility)

- (void)setNavigationRoot:(WMLNavigationNode *)navigationRoot URL:(NSURL *)URL {
    self.navigationRoot = navigationRoot;
    self.URL = URL;
}

@end
