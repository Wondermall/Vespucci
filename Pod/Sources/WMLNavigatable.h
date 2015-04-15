//
//  WMLNavigatable.h
//  Pods
//
//  Created by Sash Zats on 4/14/15.
//
//

#import <Foundation/Foundation.h>


@class WMLNavigationNode;

/**
 *  Marker protocol, lets @c WMLNavigationManager know that receiver is 
 *  interested in receiving navigationNode.
 */
@protocol WMLNavigatable <NSObject>

@property (nonatomic, weak) WMLNavigationNode *navigationNode;

@end
