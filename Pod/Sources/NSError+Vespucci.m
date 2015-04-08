//
//  NSError+Vespucci.m
//  NavigationPlayground
//
//  Created by Sash Zats on 4/8/15.
//  Copyright (c) 2015 Sash Zats. All rights reserved.
//

#import "NSError+Vespucci.h"


NSString *const WMLVespucciErrorDomain = @"WMLVespucciErrorDomain";


@implementation NSError (Vespucci)

+ (instancetype)wml_vespuciErrorWithCode:(NSUInteger)code message:(NSString *)format, ... {
    NSParameterAssert(format);
    va_list list;
    va_start(list, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:list];
    va_end(list);
    return [NSError errorWithDomain:WMLVespucciErrorDomain code:code userInfo:@{ NSLocalizedDescriptionKey: message }];
}

@end
