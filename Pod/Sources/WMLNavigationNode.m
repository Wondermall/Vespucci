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


@interface __WMLHostingStrategy : NSObject
@property (nonatomic, copy) WMLNavigationNodeViewControllerMountHandler mountingBlock;
@property (nonatomic, copy) WMLNavigationNodeViewControllerMountHandler unmountingBlock;
@property (nonatomic, copy) NSString *nodeId;
- (BOOL)isGoodForNode:(WMLNavigationNode *)node;
@end


@implementation __WMLHostingStrategy
- (BOOL)isGoodForNode:(WMLNavigationNode *)node {
    return [self.nodeId isEqualToString:node.nodeId];
}
@end


@interface WMLNavigationNode ()

@property (nonatomic, weak) WMLNavigationNode *parent;
@property (nonatomic, copy) NSDictionary *navigationParameters;

@property (nonatomic) NSMutableArray *logicalEqualityRules;
@property (nonatomic) NSMutableArray *hostingRules;

@end


@implementation WMLNavigationNode

#pragma mark - Lifecycle

+ (instancetype)navigationNodeWithName:(NSString *)name {
    WMLNavigationNode *item = [WMLNavigationNode new];
    item.name = name;
    return item;
}

- (instancetype)initWithNavigationParameters:(NSDictionary *)dictionary {
    self = [super init];
    if (!self) {
        return nil;
    }
    self.navigationParameters = dictionary;
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

- (NSString *)debugDescription {
    if (!self.child) {
        return self.description;
    }
    return [NSString stringWithFormat:@"%@ -> %@", self.description, self.child.debugDescription];
}

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
    return [self.model isEqual:node.model] && (!self.child || (self.child && [self.child isEqual:node.child]));
}

- (NSUInteger)hash {
    NSUInteger base = self.model ? [self.model hash] : [super hash];
    return self.child ? (base ^ [self.child hash]) : base;
}

@end


@implementation WMLNavigationNode (Hosting)

#pragma mark - Public

- (BOOL)canHostItem:(WMLNavigationNode *)node {
    NSAssert(node.nodeId, @"Node doesn't have an identifier");
    for (__WMLHostingStrategy *strategy in self.hostingRules) {
        if ([strategy.nodeId isEqualToString:node.nodeId]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)getHost:(WMLNavigationNode **)outParent forNode:(WMLNavigationNode **)inOutChild {
    NSParameterAssert(outParent);
    NSParameterAssert(inOutChild);
    WMLNavigationNode *child = (*inOutChild).root;
    WMLNavigationNode *parent = self.root;
    
    if ([self _getHost:&parent forNode:&child]) {
        *outParent = parent;
        *inOutChild = child;
        return YES;
    }
    
    return NO;
}

- (RACSignal *)hostNode:(WMLNavigationNode *)child animated:(BOOL)animated {
    RACSubject *subject = [RACSubject subject];
    
    WMLNavigationNode *host = nil;
    WMLNavigationNode *childToStartFrom = child;
    if (![self getHost:&host forNode:&childToStartFrom]) {
        [subject sendError:[NSError wml_vespuciErrorWithCode:0 message:@"Failed to find the host for %@", child]];
        return subject;
    }
    
    [[host _hostNode:child animated:animated] subscribe:subject];
    
    return [subject replayLast];
}

- (void)addIsDataEqualRule:(WMLNavigationNodeLogicalEqualityRule)rule {
    [self.logicalEqualityRules addObject:[rule copy]];
}

- (void)addHostingRuleForNodeId:(NSString *)nodeId mountingBlock:(WMLNavigationNodeViewControllerMountHandler)mountingBlock unmountingBlock:(WMLNavigationNodeViewControllerMountHandler)unmountingBlock {
    __WMLHostingStrategy *strategy = [[__WMLHostingStrategy alloc] init];
    strategy.nodeId = nodeId;
    strategy.mountingBlock = mountingBlock;
    strategy.unmountingBlock = unmountingBlock;
    [self.hostingRules addObject:strategy];
}


#pragma mark - Private

- (RACSignal *)_hostNode:(WMLNavigationNode *)newChild animated:(BOOL)animated {
//    ZAssert([self canHostItem:newChild], @"%@ can't host %@", self, newChild);

    @weakify(self);
    RACSequence *hostingRules = self.hostingRules.rac_sequence;
    WMLNavigationNodeViewControllerMountHandler unmountBlock = [[[hostingRules
        filter:^BOOL(__WMLHostingStrategy *strategy) {
            @strongify(self);
            return [strategy isGoodForNode:self.child];
        }]
        take:1]
        map:^id(__WMLHostingStrategy *strategy) {
            return strategy.unmountingBlock;
        }].head;

    WMLNavigationNodeViewControllerMountHandler mountBlock = [[[hostingRules
        filter:^BOOL(__WMLHostingStrategy *strategy) {
            return [strategy isGoodForNode:newChild];
        }]
        take:1]
        map:^id(__WMLHostingStrategy *strategy) {
            return strategy.mountingBlock;
        }].head;
    
    if (!mountBlock) {
        return [RACSignal error:[NSError wml_vespuciErrorWithCode:0 message:@"Failed to find mount blocks for %@", newChild]];
    }

    return [[unmountBlock ? unmountBlock(self.viewController, self.child.viewController, animated) : [RACSignal empty]
        doCompleted:^{
            @strongify(self);
            self.child = newChild;
            if ([newChild.viewController conformsToProtocol:@protocol(WMLNavigationParametrizedViewController)]) {
                ((UIViewController <WMLNavigationParametrizedViewController> *)newChild.viewController).navigationParameters = newChild.navigationParameters;
            }
        }]
        concat:mountBlock(self.viewController, newChild.viewController, animated)];
}

- (BOOL)_containsSameDataAsNode:(WMLNavigationNode *)node {
    for (WMLNavigationNodeLogicalEqualityRule rule in self.logicalEqualityRules) {
        if (rule(self, node)) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)_getHost:(inout WMLNavigationNode **)inOutParent forNode:(inout WMLNavigationNode **)inOutChild {
    if (!inOutParent || !*inOutParent || !inOutChild || !*inOutChild) {
        return NO;
    }
    WMLNavigationNode *child = *inOutChild;
    WMLNavigationNode *parent = *inOutParent;
    if ([parent _containsSameDataAsNode:child]) {
        WMLNavigationNode *proposedParent = parent.child;
        WMLNavigationNode *grandchild = child.child;
        if ([self _getHost:&proposedParent forNode:&grandchild]) {
            *inOutParent = proposedParent;
            *inOutChild = grandchild;
            return YES;
        } else if ([self _getHost:inOutParent forNode:&grandchild]) {
            *inOutChild = grandchild;
            return YES;
        }
    } else if ([parent canHostItem:child]) {
        *inOutParent = parent;
        *inOutChild = child;
        return YES;
    }
    return NO;
}

@end
