//
//  NSError+Vespucci.h
//  NavigationPlayground
//
//  Created by Sash Zats on 4/8/15.
//  Copyright (c) 2015 Sash Zats. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString *const VSPVespucciErrorDomain;


typedef NS_ENUM(NSInteger, VSPErrorCode) {
    // There is antoher navigation is already in progress
    VSPErrorCodeAnotherNavigationInProgress = 1,
    
    // No host found to host the new child node
    VSPErrorCodeNoHostFound
};


@interface NSError (Vespucci)

+ (instancetype)vsp_vespucciErrorWithCode:(NSUInteger)code message:(NSString *)message, ... NS_FORMAT_FUNCTION(2, 3);

@end
