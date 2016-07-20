//
//  VSPNavigationManager.m
//  Wondermall
//
//  Created by Sash Zats on 3/30/15.
//  Copyright (c) 2015 Wondermall Inc. All rights reserved.
//

#import "VSPNavigationManager.h"
#import "VSPNavigationNode+Internal.h"

#import "NSError+Vespucci.h"
#import <JLROutes/JLRoutes.h>
#import <Vespucci/Vespucci.h>


NSString *const VSPNavigationManagerWillNavigateNotification = @"VSPNavigationManagerWillNavigateNotification";
NSString *const VSPNavigationManagerDidFinishNavigationNotification = @"VSPNavigationManagerDidFinishNavigationNotification";
NSString *const VSPNavigationManagerDidFailNavigationNotification = @"VSPNavigationManagerDidFailNavigationNotification";
NSString *const VSPNavigationManagerNotificationDestinationNodeKey = @"VSPNavigationManagerNotificationDestinationNodeKey";
NSString *const VSPNavigationManagerNotificationSourceNodeKey = @"VSPNavigationManagerNotificationSourceNodeKey";

NSString *const VSPHostingRuleAnyNodeId = @"VSPHostingRuleAnyNodeId";


@interface __VSPMountingTuple : NSObject

+ (instancetype)tupleWithMountBlock:(VSPNavigationNodeViewControllerMountHandler)mountBlock unmountBlock:(VSPNavigationNodeViewControllerDismountHandler)unmountBlock;

@property (nonatomic, copy) VSPNavigationNodeViewControllerMountHandler mountHandler;

@property (nonatomic, copy) VSPNavigationNodeViewControllerDismountHandler unmountHandler;

@end


@implementation __VSPMountingTuple

+ (instancetype)tupleWithMountBlock:(VSPNavigationNodeViewControllerMountHandler)mountBlock unmountBlock:(VSPNavigationNodeViewControllerDismountHandler)unmountBlock {
    __VSPMountingTuple *tuple = [[self alloc] init];
    tuple.mountHandler = mountBlock;
    tuple.unmountHandler = unmountBlock;
    return tuple;
}

@end


@interface VSPNavigationManager (NodeHostingInternal)

- (BOOL)_getHost:(inout VSPNavigationNode **)inOutParent forChild:(inout VSPNavigationNode **)inOutChild;

- (BOOL)_navigationWithHost:(VSPNavigationNode **)host newChild:(VSPNavigationNode **)child completion:(VSPNavigatonTransitionCompletion)completion;

@end


@interface VSPNavigationManager ()

@property (nonatomic) JLRoutes *router;

@property (nonatomic) VSPNavigationNode *root;

@property (nonatomic) NSMutableDictionary *hostingRules;


@property (nonatomic) NSMutableDictionary *viewControllerFactories;

@property (nonatomic, getter=isNavigationInFlight) BOOL navigationInFlight;
@property (nonatomic) NSTimer *inflightNavigationTimer;

@property (nonatomic) id navigationDidFailToken;
@property (nonatomic) id navigationDidFinishToken;

@end


@implementation VSPNavigationManager

#pragma mark - Lifecycle

- (instancetype)initWithURLScheme:(NSString *)URLScheme {
    NSParameterAssert(URLScheme);
    self = [super init];
    if (!self) {
        return nil;
    }
    self.router = [JLRoutes routesForScheme:URLScheme];
    self.hostingRules = [NSMutableDictionary dictionary];
    self.viewControllerFactories = [NSMutableDictionary dictionary];
    return self;
}

- (instancetype)init {
    return [self initWithURLScheme:nil];
}

#pragma mark - Public

- (BOOL)handleURL:(NSURL *)URL {
    return [self navigateToURL:URL completion:^(BOOL finished) {
        // no-op
    }];
}

- (BOOL)navigateToURL:(NSURL *)URL completion:(VSPNavigatonTransitionCompletion)completion {
    NSAssert(self.navigationDidFailToken == nil, @"Previous token was not dismissed");
    NSAssert(self.navigationDidFinishToken == nil, @"Previous token was not dismissed");
    __weak VSPNavigationManager *__weakSelf = self;
    self.navigationDidFinishToken = [[NSNotificationCenter defaultCenter] addObserverForName:VSPNavigationManagerDidFinishNavigationNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        [__weakSelf _unsubscribeFromNavigationObservers];
        completion(YES);
    }];

    self.navigationDidFailToken = [[NSNotificationCenter defaultCenter] addObserverForName:VSPNavigationManagerDidFailNavigationNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        [__weakSelf _unsubscribeFromNavigationObservers];
        completion(NO);
    }];

    if (![self.router routeURL:URL]) {
        [self _unsubscribeFromNavigationObservers];
        NSAssert(NO, @"Failed to navigate to \"%@\"", URL.absoluteString);
        completion(NO);
        return NO;
    }
    return YES;
}

- (void)_unsubscribeFromNavigationObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self.navigationDidFailToken];
    [[NSNotificationCenter defaultCenter] removeObserver:self.navigationDidFinishToken];
}


- (BOOL)navigateWithNewNavigationTree:(VSPNavigationNode *)tree completion:(VSPNavigatonTransitionCompletion)completion {
    return [self _navigateToNode:tree completion:completion];
}

#pragma mark - Private

- (void)_inflightNavigationTimerHandler {
    NSAssert(NO, @"Failed to navigate in 5 seconds; Current navigation tree: %@", self.root.recursiveDescription);
    self.inflightNavigationTimer = nil;

}

- (BOOL)_navigateToNode:(VSPNavigationNode *)node completion:(VSPNavigatonTransitionCompletion)completion {
    NSAssert(!self.isNavigationInFlight, @"Another navigaiton is in flight");
    if (self.isNavigationInFlight) {
        [self _postNotificationNamed:VSPNavigationManagerDidFailNavigationNotification destination:node.root source:self.root];
        return NO;
    }

    self.inflightNavigationTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(_inflightNavigationTimerHandler) userInfo:nil repeats:NO];

    NSAssert(self.root, @"No root node installed");
    VSPNavigationNode *oldTree = [self.root copy];
    if (![self.root.nodeId isEqual:node.nodeId]) {
        // this is a relative path
        VSPNavigationNode *rootCopy = [self.root copy];
        rootCopy.leaf.child = node;
        node = rootCopy;
    }

    __weak VSPNavigationManager *__weakSelf = self;
    VSPNavigationNode *proposedHost = self.root, *proposedChild = node;

    self.navigationInFlight = YES;
    return [self _navigationWithHost:&proposedHost newChild:&proposedChild completion:^(BOOL finished) {
        VSPNavigationManager *self = __weakSelf;
        self.navigationInFlight = NO;

        [self.inflightNavigationTimer invalidate];
        self.inflightNavigationTimer = nil;

        NSAssert(finished, @"Navigation to node %@ failed", node.nodeId);
        if (!finished) {
            [self _postNotificationNamed:VSPNavigationManagerDidFailNavigationNotification destination:self.root source:oldTree];
            completion(NO);
            return;
        }

        [self _postNotificationNamed:VSPNavigationManagerDidFinishNavigationNotification destination:self.root source:oldTree];
        completion(YES);
    }];
}

- (void)_postNotificationNamed:(NSString *)notificationName destination:(VSPNavigationNode *)node source:(VSPNavigationNode *)source {
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (node) {
        userInfo[VSPNavigationManagerNotificationDestinationNodeKey] = node;
    }
    if (source) {
        userInfo[VSPNavigationManagerNotificationSourceNodeKey] = source;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self userInfo:userInfo];
}

@end


@implementation VSPNavigationManager (NodeHosting)

#pragma mark - Public

- (void)registerNavigationForRoute:(NSString *)route handler:(VSPNavigationNode *(^)(NSDictionary *))handler {
    __weak VSPNavigationManager *__weakSelf = self;
    [self.router addRoute:route handler:^BOOL(NSDictionary *parameters) {
        VSPNavigationNode *node = handler(parameters);
        NSAssert(node != nil, @"No node to navigate to");
        if (!node) {
            return NO;
        }
        VSPNavigationManager *self = __weakSelf;
        NSAssert(node.viewController, @"No view controller provided, this can't be good!");
        if (!node.viewController) {
            return NO;
        }

        return [self _navigateToNode:node completion:^(BOOL finished){}];
    }];
}

- (void)addRuleForHostNodeId:(NSString *)hostNodeId childNodeId:(NSString *)childNodeId mountBlock:(VSPNavigationNodeViewControllerMountHandler)mountBlock unmounBlock:(VSPNavigationNodeViewControllerDismountHandler)dismountBlock {
    NSMutableDictionary *hostRules = [self _rulesForHostNodeId:hostNodeId];
    hostRules[childNodeId] = [__VSPMountingTuple tupleWithMountBlock:mountBlock unmountBlock:dismountBlock];
}

- (void)registerFactoryForNodeId:(NSString *)nodeId factory:(VSPViewControllerFactory)factory {
    self.viewControllerFactories[nodeId] = [factory copy];
}

#pragma mark - Private

- (NSMutableDictionary *)_rulesForHostNodeId:(NSString *)hostNodeId {
    return self.hostingRules[hostNodeId] ?: (self.hostingRules[hostNodeId] = [NSMutableDictionary dictionary]);
}

- (__VSPMountingTuple *)_tupleForHostNodeId:(NSString *)hostNodeId childNodeId:(NSString *)childNodeId {
    if (!hostNodeId || !childNodeId) {
        return nil;
    }
    id result = self.hostingRules[hostNodeId][childNodeId];
    if (result) {
        return result;
    }
    // any host
    result = self.hostingRules[VSPHostingRuleAnyNodeId][childNodeId];
    if (result) {
        return result;
    }
    // any child
    result = self.hostingRules[hostNodeId][VSPHostingRuleAnyNodeId];
    if (result) {
        return result;
    }
    // any any
    return self.hostingRules[VSPHostingRuleAnyNodeId][VSPHostingRuleAnyNodeId];
}

@end


@implementation VSPNavigationManager (NodeHostingInternal)

- (BOOL)_getHost:(inout VSPNavigationNode **)inOutParent forChild:(inout VSPNavigationNode **)inOutChild {
    VSPNavigationNode *oldNode = *inOutParent, *newNode = *inOutChild;
    NSAssert([oldNode.nodeId isEqualToString:newNode.nodeId], @"Can't find host for roots without a common ancestor");
    if (![oldNode.nodeId isEqualToString:newNode.nodeId]) {
        *inOutParent = nil;
        *inOutChild = nil;
        return NO;
    }
    
    while ([oldNode.child.nodeId isEqual:newNode.child.nodeId] && oldNode.child && newNode.child) {
        oldNode = oldNode.child;
        newNode = newNode.child;
        
    }
    
    *inOutParent = oldNode;
    *inOutChild = newNode.child;
    return YES;
}

- (BOOL)_canParent:(VSPNavigationNode *)parent hostChild:(VSPNavigationNode *)child {
    return [self _tupleForHostNodeId:parent.nodeId childNodeId:child.nodeId] != nil;
}

- (BOOL)_navigationWithHost:(VSPNavigationNode **)host newChild:(VSPNavigationNode **)child completion:(VSPNavigatonTransitionCompletion)completion {
    // we need to capture new parameters before child will be modified
    NSDictionary *parameters = (*child).parameters;
    
    // Calculate actual host and actual child
    VSPNavigationNode *proposedChild = (*child).root;
    VSPNavigationNode *proposedHost = (*host).root;
    if (![self _getHost:&proposedHost forChild:&proposedChild]) {
        NSAssert(NO, @"Failed to find the host for %@", *child);
        completion(NO);
        return NO;
    }
    
    // Update original pointers with calculated host and child
    *child = proposedChild;
    *host = proposedHost;

    [self _unmountForHost:proposedHost completion:^(BOOL finished) {
        NSAssert(finished, @"Unmounting was not successfull");
        if (!finished) {
            completion(NO);
            return;
        }
        [proposedHost.root updateParametersRecursively:parameters];
        proposedHost.child = proposedChild;
        [self _mountForHost:proposedHost newChild:proposedChild completion:^(BOOL finished) {
            NSAssert(finished, @"Mounting navigation failed");
            completion(finished);
        }];
    }];
    return YES;
}

- (void)_unmountForHost:(VSPNavigationNode *)host completion:(VSPNavigatonTransitionCompletion)completion {
    if (!host.child) {
        completion(YES);
        return;
    }
    
    VSPNavigationNode *currentHost = host.leaf.parent;
    VSPNavigationNode *child = currentHost.child;
    if (!child) {
        completion(YES);
        return;
    }
    [self __unmountForHost:currentHost child:child stopAtNode:host completion:completion];
}

- (void)__unmountForHost:(VSPNavigationNode *)host child:(VSPNavigationNode *)child stopAtNode:(VSPNavigationNode *)stopNode completion:(VSPNavigatonTransitionCompletion)completion {
    __VSPMountingTuple *tuple = [self _tupleForHostNodeId:host.nodeId childNodeId:child.nodeId];
    NSAssert(tuple, @"No tuple found for pair host: %@; child: %@", host, child);
    NSAssert(tuple.unmountHandler, @"Don't know how to dismount current child %@", child);
    tuple.unmountHandler(host, child, ^(BOOL finished){
        if (!finished) {
            completion(NO);
            return;
        }
        if ([host isEqualToNode:stopNode]) {
            completion(YES);
            return;
        }
        [self __unmountForHost:host.parent child:host stopAtNode:stopNode completion:completion];
    });
}

- (void)_mountForHost:(VSPNavigationNode *)host newChild:(VSPNavigationNode *)proposedChild completion:(VSPNavigatonTransitionCompletion)completion {
    NSParameterAssert(host);
    if (!proposedChild) {
        // nothing to mount
        completion(YES);
        return;
    }
    [self __mountForHost:host child:proposedChild completion:completion];
}

- (void)__mountForHost:(VSPNavigationNode *)host child:(VSPNavigationNode *)child completion:(VSPNavigatonTransitionCompletion)completion {
    if (!child) {
        completion(YES);
        return;
    }
    __VSPMountingTuple *tuple = [self _tupleForHostNodeId:host.nodeId childNodeId:child.nodeId];
    VSPNavigationNodeViewControllerMountHandler mountBlock = tuple.mountHandler;
    NSAssert(mountBlock, @"%@ doesn't know how to mount %@", host.nodeId, child.nodeId);
    if (!mountBlock) {
        completion(NO);
        return;
    }
    mountBlock(host, child, ^(BOOL finished){
        if (!finished) {
            completion(NO);
            return;
        }
        [self __mountForHost:child child:child.child completion:completion];
    });
}

@end


@implementation VSPNavigationManager (Compatibility)

- (void)setNavigationRoot:(VSPNavigationNode *)navigationRoot {
    self.root = navigationRoot;
}

@end


@implementation VSPNavigationManager (Internal)

- (VSPViewControllerFactory)viewControllerFactoryForNodeId:(NSString *)nodeId {
    return self.viewControllerFactories[nodeId];
}

@end
