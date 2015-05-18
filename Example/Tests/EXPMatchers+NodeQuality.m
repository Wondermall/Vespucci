#import "EXPMatchers+NodeQuality.h"
#import <Vespucci/Vespucci.h>


EXPMatcherImplementationBegin(_haveNodeIds, (id expected)) {
    BOOL actualIsCompatible = [actual isKindOfClass:[VSPNavigationNode class]];
    BOOL expectedIsNil = (expected == nil);

    prerequisite(^BOOL{
        return actualIsCompatible && !expectedIsNil;
    });

    match(^BOOL{
        if(actualIsCompatible) {
            if([actual isKindOfClass:[VSPNavigationNode class]]) {
                VSPNavigationNode *node = actual;
                for (NSString *nodeId in expected) {
                    if (![node.nodeId isEqualToString:nodeId]) {
                        return NO;
                    }
                    node = node.child;
                }
                if (node.child != nil) {
                    return NO;
                }
                return YES;
            }
        }
        return NO;
    });
    
    failureMessageForTo(^NSString *{
        if(!actualIsCompatible) return [NSString stringWithFormat:@"%@ is not an instance of VSPNavigationNode", EXPDescribeObject(actual)];
        if(expectedIsNil) return @"the expected value is nil/null";
        return [NSString stringWithFormat:@"expected %@ to contain %@", EXPDescribeObject(actual), EXPDescribeObject(expected)];
    });
    
    failureMessageForNotTo(^NSString *{
        if(!actualIsCompatible) return [NSString stringWithFormat:@"%@ is not an instance of NSString or NSFastEnumeration", EXPDescribeObject(actual)];
        if(expectedIsNil) return @"the expected value is nil/null";
        return [NSString stringWithFormat:@"expected %@ not to contain %@", EXPDescribeObject(actual), EXPDescribeObject(expected)];
    });
}
EXPMatcherImplementationEnd
