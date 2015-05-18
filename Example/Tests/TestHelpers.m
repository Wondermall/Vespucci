//
//  TestHelpers.m
//  Vespucci
//
//  Created by Sash Zats on 5/18/15.
//  Copyright (c) 2015 Wondermall. All rights reserved.
//

#import "TestHelpers.h"


@implementation NSString (Routing)

- (NSString *)stringByReplacingKey:(NSString *)key withValue:(NSString *)value {
    return [self stringByReplacingOccurrencesOfString:[@":" stringByAppendingString:key] withString:value];
}

@end


@implementation NSURL (Testing)

+ (instancetype)URLWithFormat:(NSString *)format, ... {
    va_list list;
    va_start(list, format);
    NSString *string = [[NSString alloc] initWithFormat:format arguments:list];
    va_end(list);
    return [NSURL URLWithString:string];
}

@end


@implementation VSPNavigationNode (Testing)

- (NSUInteger)depth {
    NSUInteger depth = 0;
    VSPNavigationNode *node = self;
    while (node.parent) {
        node = node.parent;
        depth++;
    }
    return depth;
}

- (NSUInteger)height {
    NSUInteger height = 0;
    VSPNavigationNode *node = self;
    while (node.child) {
        node = node.child;
        height++;
    }
    return height;
}

@end


@implementation TestNodeViewController
@synthesize navigationNode;
+ (instancetype)viewControllerForNodeId:(NSString *)nodeId {
    TestNodeViewController *instance = [[self alloc] init];
    instance.nodeId = nodeId;
    return instance;
}
@end
