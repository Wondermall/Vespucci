//
//  VSPNavigationNode.h
//  Wondermall
//
//  Created by Sash Zats on 3/30/15.
//  Copyright (c) 2015 Wondermall Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef UIViewController *(^WMLNavigationNodeViewControllerFactory)(NSDictionary *navigationParameters);


@class RACSignal;
@interface VSPNavigationNode : NSObject <NSCopying>

/**
 *  Creates a chain of @c VSPNavigationNode with, returns the @c root node.
 *
 *  @param parameters navigation parameters passed to each node in the chain
 *  @param nodeId    @c nodeIds used for creating the chain
 *
 *  @return A root of the chain of @c VSPNavigationNode
 */
+ (instancetype)rootNodeForParameters:(NSDictionary *)parameters nodeIds:(NSString *)nodeId, ... NS_REQUIRES_NIL_TERMINATION;

+ (instancetype)nodeWithParameters:(NSDictionary *)parameters;

+ (instancetype)node;

/**
 *  For debug proposes only
 */
@property (nonatomic, copy) NSString *name;

/**
 *  Next item in the navigation stack
 */
@property (nonatomic) VSPNavigationNode *child;

/**
 *  Parent
 */
@property (nonatomic, weak, readonly) VSPNavigationNode *parent;

/**
 *  View controller corresponding with the current navigation item.
 */
@property (nonatomic) UIViewController *viewController;

@property (nonatomic, copy) UIViewController *(^lazyViewControllerFactory)(void);


/**
 *  If navigation item was created in response to URL navigation, 
 *  this property will contain all the provided parameters.
 */
@property (nonatomic, copy, readonly) NSDictionary *parameters;

@property (nonatomic, copy) NSString *nodeId;

- (instancetype)initWithNavigationParameters:(NSDictionary *)dictionary NS_DESIGNATED_INITIALIZER;

- (BOOL)isEqualToNode:(VSPNavigationNode *)node;

@end


@interface VSPNavigationNode (Hierarchy)

@property (nonatomic, readonly, getter=isRootNode) BOOL rootNode;

@property (nonatomic, readonly) VSPNavigationNode *root;

@property (nonatomic, readonly) VSPNavigationNode *leaf;

- (BOOL)containsNodeWithId:(NSString *)nodeId;

- (void)removeFromParent;

@end


@interface VSPNavigationNode (Debugging)

- (NSString *)recursiveDescription;

@end