//
//  WMLNavigationManager.m
//  Wondermall
//
//  Created by Sash Zats on 3/30/15.
//  Copyright (c) 2015 Wondermall Inc. All rights reserved.
//

#import "WMLNavigationManager.h"

#import "WMLNavigationNode.h"
#import "JLRoutes.h"
#import "RACEXTScope.h"


@interface WMLNavigationManager ()

@property (nonatomic) JLRoutes *router;
@property (nonatomic) NSURL *URL;

@end

@implementation WMLNavigationManager

#pragma mark - Lifecycle

- (instancetype)initWithURLScheme:(NSString *)URLScheme {
    NSParameterAssert(URLScheme);
    self = [super init];
    if (!self) {
        return nil;
    }

    // just in case
    JLRoutes *router = [JLRoutes routesForScheme:URLScheme];
    [router removeAllRoutes];
    self.router = router;

    self.URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://", URLScheme]];

    return self;
}

- (instancetype)init {
    return [self initWithURLScheme:nil];
}

#pragma mark - Public

- (BOOL)handleURL:(NSURL *)URL {
    URL = [self _fullyQualifiedURLForURL:URL];
    if ([self.URL isEqual:URL]) {
        return NO;
    }
    BOOL didNavigate = [self.router routeURL:URL];
    if (didNavigate) {
        self.URL = URL;
    }
    return didNavigate;
}

- (void)registerNavigationForRoute:(NSString *)route handler:(WMLNavigationNode *(^)(NSDictionary *))handler {
    @weakify(self);
    [self.router addRoute:route handler:^BOOL(NSDictionary *parameters) {
        WMLNavigationNode *node = handler(parameters);
        if (!node) {
            return NO;
        }
        @strongify(self);
        NSAssert(node.viewController, @"No view controller provided, this can't be good!");
        [self _navigationHandlerForNode:node parameters:parameters];
        return YES;
    }];
}

#pragma mark - Private

- (NSURL *)_fullyQualifiedURLForURL:(NSURL *)URL {
    // TODO: Add logic
    return URL;
}

- (void)_navigationHandlerForNode:(WMLNavigationNode *)node parameters:(NSDictionary *)parameters {
    NSAssert(self.root, @"No root node installed");
    BOOL animated = NO;
    if (parameters[@"animated"]) {
        NSString *aniamtedString = [parameters[@"animated"] lowercaseString];
        animated = [aniamtedString isEqual:@"true"] || [aniamtedString isEqual:@"yes"] || [aniamtedString isEqual:@"1"];
    }
    [self.root hostNode:node animated:animated];
}

@end

