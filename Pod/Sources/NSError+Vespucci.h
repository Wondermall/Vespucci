//
//  NSError+Vespucci.h
//  NavigationPlayground
//
//  Created by Sash Zats on 4/8/15.
//  Copyright (c) 2015 Sash Zats. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString *const WMLVespucciErrorDomain;


@interface NSError (Vespucci)

+ (instancetype)wml_vespuciErrorWithCode:(NSUInteger)code message:(NSString *)messsage, ... NS_FORMAT_FUNCTION(2, 3);

@end
