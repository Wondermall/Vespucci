//
//  TestHelpers.h
//  Vespucci
//
//  Created by Sash Zats on 5/18/15.
//  Copyright (c) 2015 Wondermall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Vespucci/Vespucci.h>


@interface NSURL (Testing)
+ (instancetype)URLWithFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1, 2);
@end


@interface NSString (Routing)
- (NSString *)stringByReplacingKey:(NSString *)key withValue:(NSString *)value;
@end


@interface VSPNavigationNode (Testing)
@property (nonatomic, readonly) NSUInteger depth;
@property (nonatomic, readonly) NSUInteger height;
@end


@interface TestNodeViewController : UIViewController <VSPNavigatable>
+ (instancetype)viewControllerForNodeId:(NSString *)nodeId;
@property (nonatomic, copy) NSString *nodeId;
@end
