//
//  VSPNavigationNode.m
//  Wondermall
//
//  Created by Sash Zats on 3/30/15.
//  Copyright (c) 2015 Wondermall Inc. All rights reserved.
//

#import "VSPNavigationNode.h"

#import "RACSignal.h"
#import "RACSignal+Operations.h"
#import "RACSequence.h"
#import "RACSubject.h"
#import "RACEXTScope.h"
#import "NSArray+RACSequenceAdditions.h"
#import "NSError+Vespucci.h"
#import "VSPNavigatable.h"

@interface VSPNavigationNode ()

@property (nonatomic, weak) VSPNavigationNode *parent;
@property (nonatomic, copy) NSDictionary *parameters;

@property (nonatomic) NSMutableArray *logicalEqualityRules;
@property (nonatomic) NSMutableArray *hostingRules;

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
    self.parameters = dictionary;
    self.hostingRules = [NSMutableArray array];
    self.logicalEqualityRules = [NSMutableArray array];

    return self;
}

- (instancetype)init {
    return [self initWithNavigationParameters:nil];
}

#pragma mark - Public

- (void)setChild:(VSPNavigationNode *)child {
    self.child.parent = nil;
    _child = child;
    child.parent = self;
}

- (void)setViewController:(UIViewController *)viewController {
    _viewController = viewController;

    if ([viewController conformsToProtocol:@protocol(VSPNavigatable)]) {
        ((id <VSPNavigatable>)viewController).navigationNode = self;
    }
}

- (UIViewController *)viewController {
    if (!_viewController) {
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
    node.viewController = self.viewController;
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

@end