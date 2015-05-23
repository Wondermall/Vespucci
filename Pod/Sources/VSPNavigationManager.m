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
#import <ReactiveCocoa/RACExtScope.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <Vespucci/Vespucci.h>


NSString *const VSPNavigationManagerWillNavigateNotification = @"VSPNavigationManagerWillNavigateNotification";
NSString *const VSPNavigationManagerDidFinishNavigationNotification = @"VSPNavigationManagerDidFinishNavigationNotification";
NSString *const VSPNavigationManagerDidFailNavigationNotification = @"VSPNavigationManagerDidFailNavigationNotification";
NSString *const VSPNavigationManagerNotificationDestinationNodeKey = @"VSPNavigationManagerNotificationDestinationNodeKey";
NSString *const VSPNavigationManagerNotificationSourceNodeKey = @"VSPNavigationManagerNotificationSourceNodeKey";

NSString *const VSPHostingRuleAnyNodeId = @"VSPHostingRuleAnyNodeId";


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

- (RACSignal *)_navigateWithHost:(inout VSPNavigationNode **)host newChild:(inout VSPNavigationNode **)child animated:(BOOL)animated;

@end


@interface VSPNavigationManager ()

@property (nonatomic) JLRoutes *router;

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
    self.router = [JLRoutes routesForScheme:URLScheme];
    self.hostingRules = [NSMutableDictionary dictionary];
    return self;
}

- (instancetype)init {
    return [self initWithURLScheme:nil];
}

#pragma mark - Public

- (BOOL)handleURL:(NSURL *)URL {
    return [self.router routeURL:URL];
}

- (RACSignal *)navigateWithNewNavigationTree:(VSPNavigationNode *)tree {
    return [self _navigateWithNode:tree];
}

#pragma mark - Private

- (RACSignal *)_navigateWithNode:(VSPNavigationNode *)node {
    NSAssert(self.root, @"No root node installed");
    VSPNavigationNode *oldTree = [self.root copy];
    if (![self.root.nodeId isEqual:node.nodeId]) {
        // this is a relative path
        VSPNavigationNode *rootCopy = [self.root copy];
        rootCopy.leaf.child = node;
        node = rootCopy;
    }
    
    BOOL animated = NO;
    if (node.parameters[@"animated"]) {
        NSString *animatedString = [node.parameters[@"animated"] lowercaseString];
        animated = [animatedString isEqual:@"true"] || [animatedString isEqual:@"yes"] || [animatedString isEqual:@"1"];
    }
    @weakify(self);
    VSPNavigationNode *proposedHost = self.root;
    VSPNavigationNode *proposedChild = node;
    RACSignal *navigation = [self _navigateWithHost:&proposedHost newChild:&proposedChild animated:animated];
    [self _postNotificationNamed:VSPNavigationManagerWillNavigateNotification destination:proposedChild.leaf source:oldTree];
    [navigation subscribeError:^(NSError *error) {
        @strongify(self);
        [self _postNotificationNamed:VSPNavigationManagerDidFailNavigationNotification destination:proposedChild.leaf source:oldTree];
    } completed:^{
        @strongify(self);
        [self _postNotificationNamed:VSPNavigationManagerDidFinishNavigationNotification destination:proposedChild.leaf source:oldTree];
    }];
    return navigation;
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
    @weakify(self);
    [self.router addRoute:route handler:^BOOL(NSDictionary *parameters) {
        VSPNavigationNode *node = handler(parameters);
        if (!node) {
            return NO;
        }
        @strongify(self);
        NSAssert(node.viewController, @"No view controller provided, this can't be good!");
        RACSignal *navigation = [self _navigateWithNode:node];
        if (!navigation) {
            return NO;
        }
        
        __block BOOL isSuccessfull = YES;
        [navigation subscribeError:^(NSError *error) {
            isSuccessfull = NO;
        }];
        
        return isSuccessfull;
    }];
}

- (void)addRuleForHostNodeId:(NSString *)hostNodeId childNodeId:(NSString *)childNodeId mountBlock:(VSPNavigationNodeViewControllerMountHandler)mountBlock unmounBlock:(VSPNavigationNodeViewControllerDismountHandler)dismountBlock {
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

- (RACSignal *)_navigateWithHost:(VSPNavigationNode **)host newChild:(VSPNavigationNode **)child animated:(BOOL)animated {
    // we need to capture new parameters before child will be modified
    NSDictionary *parameters = (*child).parameters;

    // Calculate actual host and actual child
    VSPNavigationNode *proposedChild = (*child).root;
    VSPNavigationNode *proposedHost = (*host).root;
    if (![self _getHost:&proposedHost forChild:&proposedChild]) {
        return [RACSignal error:[NSError vsp_vespucciErrorWithCode:0 message:@"Failed to find the host for %@", *child]];
    }

    // Update original pointers with calculated host and child
    *child = proposedChild;
    *host = proposedHost;
    
    RACSignal *unmount = [self _dismountForHost:proposedHost animated:animated];
    unmount = [unmount doCompleted:^{
        [proposedHost.root updateParametersRecursively:parameters];
        proposedHost.child = proposedChild;
    }];
    RACSignal *mount = [self _mountForHost:proposedHost newChild:proposedChild animated:animated];
    return [unmount concat:mount];
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
        RACSignal *dismount = dismountBlock(host, host.child, animated) ?: [RACSignal empty];
        dismount = dismount ?: [RACSignal empty];
        if (result) {
            result = [result concat:dismount];
        } else {
            result = dismount;
        }
    } while (![currentHost isEqual:host]);
    result.name = [NSString stringWithFormat:@"Dismounting all %@", host.nodeId];
    return result;
}

- (RACSignal *)_mountForHost:(VSPNavigationNode *)host newChild:(VSPNavigationNode *)proposedChild animated:(BOOL)animated {
    if (!proposedChild) {
        // nothing to mount
        return [RACSignal empty];
    }
    NSParameterAssert(host);
    NSParameterAssert(proposedChild);
    RACSignal *result = [RACSignal empty];
    VSPNavigationNode *child = proposedChild;
    while (child) {
        __VSPMountingTuple *tuple = [self _tupleForHostNodeId:host.nodeId childNodeId:child.nodeId];
        VSPNavigationNodeViewControllerMountHandler mountBlock = tuple.mountHandler;
        if (child && !mountBlock) {
            [[NSException exceptionWithName:NSInternalInconsistencyException
                                     reason:[NSString stringWithFormat:@"\"%@\" doesn't know how to mount \"%@\"", host.nodeId, child.nodeId]
                                   userInfo:nil] raise];
        }

        RACSignal *mount = mountBlock(host, child, animated) ?: [RACSignal empty];
        result = [result concat:mount];

        host = child;
        child = child.child;        
    }
    result.name = [NSString stringWithFormat:@"Mount %@ on %@", proposedChild.nodeId, host.nodeId];
    return result;
}

@end


@implementation VSPNavigationManager (Compatibility)

- (void)setNavigationRoot:(VSPNavigationNode *)navigationRoot {
    self.root = navigationRoot;
}

@end
