//
//  NSError+Vespucci.h
//  NavigationPlayground
//
//  Created by Sash Zats on 4/8/15.
//  Copyright (c) 2015 Sash Zats. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString *const VSPVespucciErrorDomain;


@interface NSError (Vespucci)

+ (instancetype)vsp_vespucciErrorWithCode:(NSUInteger)code message:(NSString *)message, ... NS_FORMAT_FUNCTION(2, 3);

@end
