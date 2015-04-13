//
//  WMLNavigationNode.m
//  Wondermall
//
//  Created by Sash Zats on 3/30/15.
//  Copyright (c) 2015 Wondermall Inc. All rights reserved.
//

#import "WMLNavigationNode.h"

#import "RACSignal.h"
#import "RACSignal+Operations.h"
#import "RACSequence.h"
#import "RACSubject.h"
#import "RACEXTScope.h"
#import "NSArray+RACSequenceAdditions.h"
#import "NSError+Vespucci.h"


@interface WMLNavigationNode ()

@property (nonatomic, weak) WMLNavigationNode *parent;
@property (nonatomic, copy) NSDictionary *parameters;

@property (nonatomic) NSMutableArray *logicalEqualityRules;
@property (nonatomic) NSMutableArray *hostingRules;

@end


@implementation WMLNavigationNode

#pragma mark - Lifecycle

+ (instancetype)nodeWithParameters:(NSDictionary *)parameters {
    return [[WMLNavigationNode alloc] initWithNavigationParameters:parameters];
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

- (void)setChild:(WMLNavigationNode *)child {
    self.child.parent = nil;
    _child = child;
    child.parent = self;
}

- (void)setViewController:(UIViewController *)viewController {
    _viewController = viewController;

    if ([viewController conformsToProtocol:@protocol(WMLNavigationParametrizedViewController)]) {
        ((id <WMLNavigationParametrizedViewController>)viewController).navigationNode = self;
    }
}

- (WMLNavigationNode *)leaf {
    WMLNavigationNode *node = self;
    while (node.child) {
        node = node.child;
    }
    return node;
}

- (BOOL)isRootNode {
    return self.parent == nil;
}

- (WMLNavigationNode *)root {
    WMLNavigationNode *node = self;
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
    if (![object isKindOfClass:[WMLNavigationNode class]]) {
        return [super isEqual:object];
    }
    return [self isEqualToNode:object];
}

- (BOOL)isEqualToNode:(WMLNavigationNode *)node {
    return [self.nodeId isEqual:node.nodeId] && (!self.child || [self.child isEqual:node.child]);
}

- (NSUInteger)hash {
    NSUInteger base = [self.nodeId hash];
    return self.child ? (base ^ [self.child hash]) : base;
}

- (id)copyWithZone:(NSZone *)zone {
    WMLNavigationNode *node = [[WMLNavigationNode allocWithZone:zone] initWithNavigationParameters:self.parameters];
    node.viewController = self.viewController;
    node.nodeId = self.nodeId;
    node.child = [self.child copy];
    return node;
}

@end


@implementation WMLNavigationNode (Debugging)

- (NSString *)recursiveDescription {
    if (!self.child) {
        return self.description;
    }
    return [NSString stringWithFormat:@"%@ → %@", self.description, self.child.debugDescription];
}

@end