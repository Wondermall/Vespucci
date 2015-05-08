//
//  VSPNavigatable.h
//  Pods
//
//  Created by Sash Zats on 4/14/15.
//
//

#import <Foundation/Foundation.h>


@class VSPNavigationNode;

/**
 *  Lets @c VSPNavigationManager know that receiver is
 *  interested in receiving navigationNode.
 */
@protocol VSPNavigatable <NSObject>

@property (nonatomic, weak) VSPNavigationNode *navigationNode;

@end
