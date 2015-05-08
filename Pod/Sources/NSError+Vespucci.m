//
//  NSError+Vespucci.m
//  NavigationPlayground
//
//  Created by Sash Zats on 4/8/15.
//  Copyright (c) 2015 Sash Zats. All rights reserved.
//

#import "NSError+Vespucci.h"


NSString *const VSPVespucciErrorDomain = @"VSPVespucciErrorDomain";


@implementation NSError (Vespucci)

+ (instancetype)vsp_vespucciErrorWithCode:(NSUInteger)code message:(NSString *)message, ... {
    NSParameterAssert(message);
    va_list list;
    va_start(list, message);
    NSString *messageString = [[NSString alloc] initWithFormat:message arguments:list];
    va_end(list);
    return [NSError errorWithDomain:VSPVespucciErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey : messageString}];
}

@end
