//
//  VSPNavigationNode.m
//  Wondermall
//
//  Created by Sash Zats on 3/30/15.
//  Copyright (c) 2015 Wondermall Inc. All rights reserved.
//

#import "VSPNavigationNode.h"
#import "VSPNavigationNode+Internal.h"
#import <Vespucci/Vespucci.h>


@interface VSPNavigationNode ()

@property (nonatomic, weak) VSPNavigationNode *parent;

@property (nonatomic, copy) NSDictionary *parameters;

@end


@implementation VSPNavigationNode
@synthesize viewController = _viewController;

#pragma mark - Lifecycle

+ (instancetype)rootNodeForParameters:(NSDictionary *)parameters nodeIds:(NSString *)nodeId, ... {
    VSPNavigationNode *root = [[self alloc] initWithNavigationParameters:parameters];
    root.nodeId = nodeId;
    VSPNavigationNode *previousNode = root;
    va_list list;
    va_start(list, nodeId);
    NSString *currentNodeId;
    while ((currentNodeId = va_arg(list, NSString *))) {
        VSPNavigationNode *node = [[VSPNavigationNode alloc] initWithNavigationParameters:parameters];
        node.nodeId = currentNodeId;
        previousNode.child = node;
        previousNode = node;
    }
    va_end(list);
    return root;
}

+ (instancetype)nodeWithParameters:(NSDictionary *)parameters {
    return [[VSPNavigationNode alloc] initWithNavigationParameters:parameters];
}

+ (instancetype)node {
    return [[self alloc] init];
}

- (instancetype)initWithNavigationParameters:(NSDictionary *)dictionary {
    self = [super init];
    if (!self) {
        return nil;
    }
    self.parameters = dictionary ?: [NSDictionary dictionary];

    return self;
}

- (instancetype)init {
    return [self initWithNavigationParameters:nil];
}

#pragma mark - Public

- (void)setChild:(VSPNavigationNode *)newChild {
    newChild.parent.child = nil;
    self.child.parent = nil;
    _child = newChild;
    newChild.parent = self;
}

- (void)setViewController:(UIViewController *)viewController {
    _viewController = viewController;

    if ([viewController conformsToProtocol:@protocol(VSPNavigatable)] &&
        ![((id <VSPNavigatable>)viewController).navigationNode isEqual:self]) {
        ((id <VSPNavigatable>)viewController).navigationNode = self;
    }
}

- (UIViewController *)viewController {
    if (!_viewController && self.lazyViewControllerFactory) {
        _viewController = self.lazyViewControllerFactory();
        if ([_viewController conformsToProtocol:@protocol(VSPNavigatable)]) {
            ((id<VSPNavigatable>)_viewController).navigationNode = self;
        }
    }
    return _viewController;
}

- (VSPNavigationNode *)leaf {
    VSPNavigationNode *node = self;
    while (node.child) {
        node = node.child;
    }
    return node;
}

- (BOOL)isRootNode {
    return self.parent == nil;
}

- (VSPNavigationNode *)root {
    VSPNavigationNode *node = self;
    while (node.parent) {
        node = node.parent;
    }
    return node;
}

- (void)updateParametersRecursively:(NSDictionary *)parameters {
    NSMutableDictionary *newParamters = [self.parameters mutableCopy];
    [newParamters addEntriesFromDictionary:parameters];
    self.parameters = newParamters;
    [self.child updateParametersRecursively:parameters];
}

- (BOOL)isDescendantOfNode:(VSPNavigationNode *)node {
    VSPNavigationNode *currentNode = node.leaf;
    while (currentNode) {
        if ([self isEqualToNode:currentNode]) {
            return YES;
        }
        currentNode = currentNode.parent;
        if (currentNode.child == node) {
            return NO;
        }
    }
    return NO;
}

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p; id=\"%@\">", [self class], self, self.nodeId] ;
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[VSPNavigationNode class]]) {
        return [super isEqual:object];
    }
    return [self isEqualToNode:object];
}

- (BOOL)isEqualToNode:(VSPNavigationNode *)node {
    return [self.nodeId isEqual:node.nodeId] && (!self.child || [self.child isEqual:node.child]);
}

- (NSUInteger)hash {
    NSUInteger base = [self.nodeId hash];
    return self.child ? (base ^ [self.child hash]) : base;
}

- (id)copyWithZone:(NSZone *)zone {
    VSPNavigationNode *node = [[VSPNavigationNode allocWithZone:zone] initWithNavigationParameters:self.parameters];
    node.nodeId = self.nodeId;
    node.child = [self.child copy];
    return node;
}

@end


@implementation VSPNavigationNode (Debugging)

- (NSString *)recursiveDescription {
    if (!self.child) {
        return self.description;
    }
    return [NSString stringWithFormat:@"%@ → %@", self.description, self.child.recursiveDescription];
}

- (NSString *)debugDescription {
    return [self recursiveDescription];
}

@end


@implementation VSPNavigationNode (Hierarchy)

- (BOOL)containsNodeWithId:(NSString *)nodeId {
    VSPNavigationNode *node = self;
    while (node) {
        if ([node.nodeId isEqualToString:nodeId]) {
            return YES;
        }
        node = node.child;
    }
    return NO;
}

- (instancetype)nodeForId:(NSString *)nodeId {
    VSPNavigationNode *node = self;
    while (node) {
        if ([node.nodeId isEqualToString:nodeId]) {
            return node;
        }
        node = node.child;
    }
    return nil;
}

- (void)removeFromParent {
    self.parent.child = nil;
}

@end
