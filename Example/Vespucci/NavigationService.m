//
// Created by Sash Zats on 4/8/15.
// Copyright (c) 2015 Sash Zats. All rights reserved.
//

#import "NavigationService.h"

#import <Vespucci/Vespucci.h>
#import <ReactiveCocoa/RACSubject.h>


static NSString *const SingleMessageNodeId = @"root.messages.message";


@interface NavigationService ()

@property (nonatomic) WMLNavigationManager *navigationManager;

@end


@interface NavigationService (Routes)

- (NSString *)notificationsRoute;

- (NSString *)profileForIdRoute;

- (NSString *)messagesRoute;

- (NSString *)messageForIdRoute;

- (NSString *)pictureForIdRoute;
@end


@implementation NavigationService

#pragma mark - Lifecycle

+ (instancetype)sharedService {
    static NavigationService *instance;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
       instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.navigationManager = [[WMLNavigationManager alloc] initWithURLScheme:AppSpecificURLScheme];

    return self;
}

#pragma mark - Public

- (void)registerRoutesWithRootViewController:(UIViewController *)rootViewController {
    WMLNavigationNode *root = [[WMLNavigationNode alloc] init];
    root.nodeId = @"root";
    root.viewController = rootViewController;
    self.navigationManager.root = root;

    [self _registerNodeRoutes];
}

- (BOOL)handleURL:(NSURL *)url {
    return [self.navigationManager handleURL:url];
}

#pragma mark - Private

- (void)_registerNodeRoutes {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];

    // Message for id
    [self.navigationManager registerNavigationForRoute:[self messageForIdRoute] handler:^WMLNavigationNode *(NSDictionary *parameters) {
        WMLNavigationNode *node = [[WMLNavigationNode alloc] initWithNavigationParameters:parameters];
        node.nodeId = SingleMessageNodeId;
        node.viewController = [storyboard instantiateViewControllerWithIdentifier:@"MessageViewController"];
        return node;
    }];

    [self.navigationManager.root addHostingRuleForNodeId:SingleMessageNodeId mountingBlock:^RACSignal *(UIViewController *parent, UIViewController *child, BOOL animated) {
        RACSubject *subject = [RACSubject subject];
        [parent presentViewController:[[UINavigationController alloc] initWithRootViewController:child] animated:animated completion:^{
            [subject sendCompleted];
        }];
        return subject;
    } unmountingBlock:^RACSignal *(UIViewController *parent, UIViewController *child, BOOL animated) {
        RACSubject *subject = [RACSubject subject];
        [child dismissViewControllerAnimated:animated completion:^{
            [subject sendCompleted];
        }];
        return subject;
    }];
}


@end


@implementation NavigationService (URLBuilder)

#pragma mark - Public

- (NSURL *)messagesURL {
    return [self _urlFromRoute:[self messagesRoute] parameters:nil];
}

- (NSURL *)messageURLForMessageId:(NSString *)userId {
    return [self _urlFromRoute:[self messageForIdRoute] parameters:@{
        @"messageId": userId
    }];
}

- (NSURL *)picturesURLForPictureId:(NSString *)pictureId {
    return [self _urlFromRoute:[self pictureForIdRoute] parameters:@{
        @"pictureId": pictureId
    }];
}

- (NSURL *)profileURLForUser:(NSString *)userId {
    return [self _urlFromRoute:[self profileForIdRoute] parameters:@{
        @"userId": userId
    }];
}

- (NSURL *)notificationsURL {
    return [self _urlFromRoute:[self notificationsRoute] parameters:nil];
}

#pragma mark - Private

- (NSURL *)_urlFromRoute:(NSString *)route parameters:(NSDictionary *)parameters {
    NSMutableString *URLString = [NSMutableString stringWithFormat:@"%@://%@?animated=true", AppSpecificURLScheme, route];
    for (NSString *key in parameters) {
        NSString *normalizedKey = [NSString stringWithFormat:@":%@", key];
        [URLString replaceOccurrencesOfString:normalizedKey  withString:parameters[key] options:0 range:NSMakeRange(0, URLString.length)];
    }
    return [NSURL URLWithString:URLString];
}

@end


@implementation NavigationService (Routes)

- (NSString *)notificationsRoute {
    return @"/notifications";
}

- (NSString *)profileForIdRoute {
    return @"/notifications/users/:userId";
}

- (NSString *)messagesRoute {
    return @"/messages";
}

- (NSString *)messageForIdRoute {
    return @"/messages/:messageId";
}

- (NSString *)pictureForIdRoute {
    return @"/notifications/pictures/:pictureId";
}

@end
