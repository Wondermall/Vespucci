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
@interface WMLNavigationNode : NSObject

+ (instancetype)navigationNodeWithName:(NSString *)name;

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
 *  Model backing the current navigation item.
 */
@property (nonatomic) id model;

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


typedef BOOL(^WMLNavigationNodeFilterBlock)(WMLNavigationNode *parent, WMLNavigationNode *child);
typedef BOOL(^WMLNavigationNodeLogicalEqualityRule)(WMLNavigationNode *node1, WMLNavigationNode *node2);
typedef RACSignal *(^WMLNavigationNodeViewControllerMountHandler)(UIViewController *parent, UIViewController *child, BOOL animated);

@interface WMLNavigationNode (Hosting)

- (void)addIsDataEqualRule:(WMLNavigationNodeLogicalEqualityRule)rule;

/**
 *  <#Description#>
 *
 *  @param filterBlock     Describes how to distinguish interesting block being processed
 *  @param mountingBlock   How to mount view controller in animated and not fashion
 *  @param unmountingBlock How to dismount view controller in animated and not fashion
 *
 *  @example If I want to describe how to add node representing date:
 *  @code
 *
 *      [root addHostingRuleForNode:^BOOL(WMLNavigationNode *node1, WMLNavigationNode *node2) {
 *          return pnode2.model isKindOfClass:[NSDate class]];
 *      } mountingBlock:^RACSignal *(WMLPresentableViewController *parent, WMLPresentableViewController *child, BOOL animated) {
 *          // mount view controller
 *          return animated ? [[RACSignal empty] delay:5] : [RACSignal empty];
 *      } unmountingBlock:^RACSignal *(WMLPresentableViewController *parent, WMLPresentableViewController *child, BOOL animated) {
 *          // unmount view controller
 *      }];
 *
 */
- (void)addHostingRuleForNodeId:(NSString *)nodeId mountingBlock:(WMLNavigationNodeViewControllerMountHandler)mountingBlock unmountingBlock:(WMLNavigationNodeViewControllerMountHandler)unmountingBlock;

- (BOOL)canHostItem:(WMLNavigationNode *)node;

- (BOOL)getHost:(out WMLNavigationNode **)outParent forNode:(inout WMLNavigationNode **)child;

- (RACSignal *)hostNode:(WMLNavigationNode *)newChild animated:(BOOL)animated;

@end
