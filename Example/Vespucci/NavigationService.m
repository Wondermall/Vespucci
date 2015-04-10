//
// Created by Sash Zats on 4/8/15.
// Copyright (c) 2015 Sash Zats. All rights reserved.
//

#import "NavigationService.h"

#import "MessageViewController.h"
#import "MessagesListViewController.h"
#import "NotificationsViewController.h"

#import <Vespucci/Vespucci.h>
#import <ReactiveCocoa/RACSubject.h>
#import <ReactiveCocoa/RACEXTScope.h>


NSString *const RootNodeId = @"root";
NSString *const MessagesNodeId = @"root.messages";
NSString *const SingleMessageNodeId = @"root.messages.message";
NSString *const NotificationsNodeId = @"root.notification";
NSString *const ProfileNodeId = @"root.notifications.profile";
NSString *const BlockUserNodeId = @"root.notifications.profile.block";


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

- (void)setupDefaultRoutesWithRootViewController:(UITabBarController *)tabController {
    [self syncStateForRootController:tabController];
    [self _registerNodeRoutesForRootViewController:tabController];
}

- (BOOL)handleURL:(NSURL *)url {
    return [self.navigationManager handleURL:url];
}

#pragma mark - Private

- (void)_registerNodeRoutesForRootViewController:(UITabBarController *)rootViewController {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];

    
    // Message for id
    [self.navigationManager registerNavigationForRoute:[self messageForIdRoute] handler:^WMLNavigationNode *(NSDictionary *parameters) {
        WMLNavigationNode *message = [[WMLNavigationNode alloc] initWithNavigationParameters:parameters];
        message.nodeId = SingleMessageNodeId;
        message.viewController = [storyboard instantiateViewControllerWithIdentifier:@"MessageViewController"];
       
        WMLNavigationNode *currentRoot = [self.navigationManager.navigationRoot copy];
        currentRoot.leaf.child = message;
        
        return currentRoot;
    }];
    
    // Messages
    [self.navigationManager registerNavigationForRoute:[self messagesRoute] handler:^WMLNavigationNode *(NSDictionary *parameters) {
        WMLNavigationNode *messages = [[WMLNavigationNode alloc] initWithNavigationParameters:parameters];
        messages.nodeId = MessagesNodeId;
        messages.viewController = rootViewController.viewControllers[0];
        
        WMLNavigationNode *root = [[WMLNavigationNode alloc] initWithNavigationParameters:parameters];
        root.nodeId = RootNodeId;
        root.viewController = rootViewController;
        root.child = messages;

        return root;
    }];

    // Profile

    [self.navigationManager registerNavigationForRoute:[self profileForIdRoute] handler:^WMLNavigationNode *(NSDictionary *parameters) {
        // sample check for valid parameters
        if ([parameters[@"userId"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0) {
            // For debug purposes only!
            NSAssert(NO, @"Invalid user id: %@", parameters[@"userId"]);
            return nil;
        }
        WMLNavigationNode *profile = [[WMLNavigationNode alloc] initWithNavigationParameters:parameters];
        profile.nodeId = ProfileNodeId;
        profile.viewController = [storyboard instantiateViewControllerWithIdentifier:@"ProfileViewController"];

        WMLNavigationNode *notifications = [[WMLNavigationNode alloc] initWithNavigationParameters:nil];
        notifications.nodeId = NotificationsNodeId;
        notifications.viewController = rootViewController.viewControllers[1];
        notifications.child = profile;
        
        WMLNavigationNode *root = [[WMLNavigationNode alloc] initWithNavigationParameters:nil];
        root.nodeId = RootNodeId;
        root.viewController = rootViewController;
        root.child = notifications;

        return root;
    }];


    // Notifications -> Profile

    [self.navigationManager addRuleForHostNodeId:NotificationsNodeId childNodeId:ProfileNodeId mountBlock:^RACSignal *(UIViewController *parent, UIViewController *child, BOOL animated) {
        return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:child];
            navigationController.navigationBar.barStyle = UIBarStyleBlack;
            [parent presentViewController:navigationController animated:animated completion:^{
                [subscriber sendCompleted];
            }];
            return nil;
        }];
    } dismounBlock:^RACSignal *(UIViewController *parent, UIViewController *child, BOOL animated) {
        return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            [child dismissViewControllerAnimated:animated completion:^{
                [subscriber sendCompleted];
            }];
            return nil;
        }];
    }];
    
    
    // Notifications

    [self.navigationManager addRuleForHostNodeId:RootNodeId childNodeId:NotificationsNodeId mountBlock:^RACSignal *(UIViewController *parent, UIViewController *child, BOOL animated) {
        return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            ((UITabBarController *)parent).selectedIndex = 1;
            [subscriber sendCompleted];
            return nil;
        }];
    } dismounBlock:^RACSignal *(UIViewController *parent, UIViewController *child, BOOL animated) {
        // no-op
        return nil;
    }];

    [self.navigationManager registerNavigationForRoute:[self notificationsRoute] handler:^WMLNavigationNode *(NSDictionary *parameters) {
        WMLNavigationNode *node = [[WMLNavigationNode alloc] initWithNavigationParameters:parameters];
        node.nodeId = NotificationsNodeId;
        node.viewController = ((UITabBarController *)rootViewController).viewControllers[1];
        return node;
    }];
    

    // Messages

    [self.navigationManager addRuleForHostNodeId:RootNodeId childNodeId:MessagesNodeId mountBlock:^RACSignal *(UIViewController *parent, UIViewController *child, BOOL animated) {
        return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            ((UITabBarController *)parent).selectedIndex = 0;
            [subscriber sendCompleted];
            return nil;
        }];
    } dismounBlock:^RACSignal *(UIViewController *parent, UIViewController *child, BOOL animated) {
        return nil;
    }];

    // Root -> Messages

    [self.navigationManager registerNavigationForRoute:[self notificationsRoute] handler:^WMLNavigationNode *(NSDictionary *parameters) {
        WMLNavigationNode *node = [[WMLNavigationNode alloc] initWithNavigationParameters:parameters];
        node.nodeId = MessagesNodeId;
        node.viewController = ((UITabBarController *)rootViewController).viewControllers[0];
        return node;
    }];

    // Messages -> Single Message
    [self.navigationManager addRuleForHostNodeId:MessagesNodeId childNodeId:SingleMessageNodeId mountBlock:^RACSignal *(UIViewController *parent, UIViewController *child, BOOL animated) {
        return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:child];
            navigationController.navigationBar.barStyle = UIBarStyleBlack;
            [parent presentViewController:navigationController animated:animated completion:^{
                [subscriber sendCompleted];
            }];
            return nil;
        }];
    } dismounBlock:^RACSignal *(UIViewController *parent, UIViewController *child, BOOL animated) {
        return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            [child dismissViewControllerAnimated:animated completion:^{
                [subscriber sendCompleted];
            }];
            return nil;
        }];
    }];

    @weakify(self);
    [self.navigationManager addRuleForHostNodeId:ProfileNodeId childNodeId:BlockUserNodeId mountBlock:^RACSignal *(UIViewController *parent, UIViewController *child, BOOL animated) {
        return [RACSignal createSignal:^RACDisposable *(id <RACSubscriber> subscriber) {
            [parent presentViewController:child animated:animated completion:^{
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    @strongify(self);
                    [[UIApplication sharedApplication] openURL:[self messagesURL]];
                });
                [subscriber sendCompleted];
            }];
            return nil;
        }];
    } dismounBlock:^RACSignal *(UIViewController *parent, UIViewController *child, BOOL animated) {
        return [RACSignal createSignal:^RACDisposable *(id <RACSubscriber> subscriber) {
            [child dismissViewControllerAnimated:animated completion:^{
                [subscriber sendCompleted];
            }];
            return nil;
        }];
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

- (NSURL *)blockUserWithUserIdURL:(NSString *)userId {
    return [self _urlFromRoute:[self profileForIdRoute] parameters:@{
       @"userId": userId,
       @"action": @"block"
    }];
}

#pragma mark - Private

- (NSURL *)_urlFromRoute:(NSString *)route parameters:(NSDictionary *)parameters {
    // "animated=true" -> animate all the transitions
    NSMutableString *URLString = [NSMutableString stringWithFormat:@"%@://%@?animated=true", AppSpecificURLScheme, route];
    NSMutableDictionary *dictionary = [parameters mutableCopy];
    for (NSString *key in parameters) {
        NSString *normalizedKey = [NSString stringWithFormat:@":%@", key];
        NSUInteger numberOfOccurrences = [URLString replaceOccurrencesOfString:normalizedKey  withString:parameters[key] options:0 range:NSMakeRange(0, URLString.length)];
        if (numberOfOccurrences) {
            [dictionary removeObjectForKey:key];
        }
    }
    for (NSString *key in dictionary) {
        [URLString appendFormat:@"&%@=%@", key, dictionary[key]];
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


@implementation NavigationService (Compatibility)

- (void)syncStateForRootController:(UITabBarController *)tabController {
    UIViewController *selectedViewController = ((UINavigationController *)tabController.selectedViewController).viewControllers.firstObject;
    NSAssert(selectedViewController.childViewControllers.count == 0, @"Syncronization called in unexpected state");

    NSURL *URL;
    WMLNavigationNode *child = [WMLNavigationNode node];
    if ([selectedViewController isKindOfClass:[MessagesListViewController class]]) {
        URL = [self messagesURL];
        child.nodeId = MessagesNodeId;
    } else if ([selectedViewController isKindOfClass:[NotificationsViewController class]]) {
        URL = [self notificationsURL];
        child.nodeId = NotificationsNodeId;
    }
    child.viewController = tabController.selectedViewController;
    WMLNavigationNode *root = [WMLNavigationNode node];
    root.nodeId = RootNodeId;
    root.child = child;
    root.viewController = tabController;
    [self.navigationManager setNavigationRoot:root URL:URL];
}

// TODO: this should be replaced with navigation to -[URL URLByDeletingLastPathComponent]
- (void)syncStateByRemovingLastNode {
    NSURLComponents *components = [NSURLComponents componentsWithURL:self.navigationManager.URL resolvingAgainstBaseURL:NO];
    components.query = nil;
    components.path = [components.path stringByDeletingLastPathComponent];
    NSURL *URL = components.URL;
    WMLNavigationNode *node = [self.navigationManager.navigationRoot copy];
    // TODO: can make it nicer by adding -[WMLNavigationNode removeFromParent]
    node.leaf.parent.child = nil;
    [self.navigationManager setNavigationRoot:node URL:URL];
}

@end