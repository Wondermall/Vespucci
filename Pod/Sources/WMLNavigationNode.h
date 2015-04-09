//
//  WMLNavigationNode.h
//  Wondermall
//
//  Created by Sash Zats on 3/30/15.
//  Copyright (c) 2015 Wondermall Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@class WMLNavigationNode;
/**
 *  If implemented, view controller will get navigationParameters if 
 *  presented with navigation maanger.
 */
@protocol WMLNavigationParametrizedViewController <NSObject>

@property (nonatomic, weak) WMLNavigationNode *navigationNode;

@end


typedef UIViewController *(^WMLNavigationNodeViewControllerFactory)(NSDictionary *navigationParameters);


@class RACSignal;
@interface WMLNavigationNode : NSObject <NSCopying>

+ (instancetype)navigationNodeWithName:(NSString *)name;

+ (instancetype)node;

/**
 *  For debug proposes only
 */
@property (nonatomic, copy) NSString *name;

/**
 *  Next item in the navigation stack
 */
@property (nonatomic) WMLNavigationNode *child;

/**
 *  Parent
 */
@property (nonatomic, weak, readonly) WMLNavigationNode *parent;

/**
 *  View controller corresponding with the current navigation item.
 */
@property (nonatomic) UIViewController *viewController;


/**
 *  If navigation item was created in response to URL navigation, 
 *  this property will contain all the provided parameters.
 */
@property (nonatomic, copy, readonly) NSDictionary *parameters;

@property (nonatomic, copy) NSString *nodeId;

- (instancetype)initWithNavigationParameters:(NSDictionary *)dictionary NS_DESIGNATED_INITIALIZER;

@end


@interface WMLNavigationNode (Hierarchy)

@property (nonatomic, readonly) BOOL isRootNode;

@property (nonatomic, readonly) WMLNavigationNode *root;

@property (nonatomic, readonly) WMLNavigationNode *leaf;

@end


typedef BOOL(^WMLNavigationNodeLogicalEqualityRule)(WMLNavigationNode *node1, WMLNavigationNode *node2);

@interface WMLNavigationNode (Hosting)

- (void)addIsDataEqualRule:(WMLNavigationNodeLogicalEqualityRule)rule;

- (BOOL)containsSameDataAsNode:(WMLNavigationNode *)node;

@end
