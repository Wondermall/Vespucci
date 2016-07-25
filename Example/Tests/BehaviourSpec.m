//
//  VespucciTests.m
//  VespucciTests
//
//  Created by Sash Zats on 04/08/2015.
//  Copyright (c) 2014 Sash Zats. All rights reserved.
//

#import "TestHelpers.h"
#import "EXPMatchers+NodeQuality.h"
#import <Vespucci/Vespucci.h>

//
// Who can present what
//
//       +-> news-feed -> post
// root -|
//       +-> messages -> message
//
// any node -> profile
//

static NSString *const URLScheme = @"test";

static NSString *const RootNodeId = @"root";
static NSString *const NewsFeedNodeId = @"news-feed";
static NSString *const PostNodeId = @"post";
static NSString *const MessagesNodeId = @"messages";
static NSString *const MessageNodeId = @"message";
static NSString *const ProfileNodeId = @"profile";

static NSString *const NewsFeedRoute = @"news-feed";
static NSString *const PostRoute = @"news-feed/posts/:post_id";
static NSString *const MessagesRoute = @"messages";
static NSString *const MessageRoute = @"messages/:message_id";
static NSString *const ProfileRoute = @"profile/:user_id";


@interface TestNavigationManager : VSPNavigationManager;
- (void)addSimpleRuleForHostNodeId:(NSString *)hostNodeId childNodeId:(NSString *)childNodeId;
- (void)registerSimpleNavigationForRoute:(NSString *)route nodeId:(NSString *)nodeId, ... NS_REQUIRES_NIL_TERMINATION;
@end


SpecBegin(InitialSpecs)

describe(@"Navigation rules", ^{
    __block TestNavigationManager *manager;

    beforeAll(^{
        manager = [[TestNavigationManager alloc] initWithURLScheme:URLScheme];
        
        // Route <-> node id
        [manager registerSimpleNavigationForRoute:NewsFeedRoute nodeId:RootNodeId, NewsFeedNodeId, nil];
        [manager registerSimpleNavigationForRoute:PostRoute nodeId:RootNodeId, NewsFeedNodeId, PostNodeId, nil];
        [manager registerSimpleNavigationForRoute:MessagesRoute nodeId:RootNodeId, MessagesNodeId, nil];
        [manager registerSimpleNavigationForRoute:MessageRoute nodeId:RootNodeId, MessagesNodeId, MessageNodeId, nil];
        [manager registerSimpleNavigationForRoute:ProfileRoute nodeId:ProfileNodeId, nil];
        
        // Hosting rules
        [manager addSimpleRuleForHostNodeId:RootNodeId childNodeId:NewsFeedNodeId];
        [manager addSimpleRuleForHostNodeId:RootNodeId childNodeId:MessagesNodeId];
        [manager addSimpleRuleForHostNodeId:NewsFeedNodeId childNodeId:PostNodeId];
        [manager addSimpleRuleForHostNodeId:MessagesNodeId childNodeId:MessageNodeId];
        [manager addSimpleRuleForHostNodeId:VSPHostingRuleAnyNodeId childNodeId:ProfileNodeId];
        
    });
    
    beforeEach(^{
        VSPNavigationNode *root = [VSPNavigationNode node];
        root.nodeId = RootNodeId;
        root.viewController = [TestNodeViewController viewControllerForNodeId:RootNodeId];
        [manager setNavigationRoot:root];
    });
    
    context(@"Navigation", ^{
        context(@"Correct permutations", ^{
            it(@"should navigate to the immediate child", ^{
                NSURL *URL = [NSURL URLWithFormat:@"%@://%@", URLScheme, NewsFeedRoute];
                expect([manager handleURL:URL]).to.beTruthy();
                expect(manager.root).to.haveNodeIds(RootNodeId, NewsFeedNodeId);
            });
            
            it(@"should navigate to the grandchild", ^{
                NSURL *URL = [NSURL URLWithFormat:@"%@://%@", URLScheme, [PostRoute stringByReplacingKey:@"post_id" withValue:@"123"]];
                expect([manager handleURL:URL]).to.beTruthy();
                expect(manager.root).to.haveNodeIds(RootNodeId, NewsFeedNodeId, PostNodeId);
                expect(manager.root.child.child.parameters[@"post_id"]).to.equal(@"123");
            });
            
            context(@"should navigate to the wildcard-hosted child", ^{
                it(@"from the initial state", ^{
                    NSURL *URL = [NSURL URLWithFormat:@"%@://%@", URLScheme, [ProfileRoute stringByReplacingKey:@"user_id" withValue:@"abc"]];
                    expect([manager handleURL:URL]).to.beTruthy();
                    expect(manager.root).to.haveNodeIds(RootNodeId, ProfileNodeId);
                    expect(manager.root.child.parameters[@"user_id"]).to.equal(@"abc");
                });
                
                context(@"when children are already presented", ^{
                    it(@"should present on top of the existent hierarchy", ^{
                        NSURL *newsFeedURL = [NSURL URLWithFormat:@"%@://%@", URLScheme, [PostRoute stringByReplacingKey:@"post_id" withValue:@"123"]];
                        [manager handleURL:newsFeedURL];
                        NSURL *URL = [NSURL URLWithFormat:@"%@://%@", URLScheme, [ProfileRoute stringByReplacingKey:@"user_id" withValue:@"abc"]];
                        [manager handleURL:URL];
                        expect(manager.root).to.haveNodeIds(RootNodeId, NewsFeedNodeId, PostNodeId, ProfileNodeId);
                    });

                    it(@"nodes along the way should keep correct parameters", ^{
                        NSURL *newsFeedURL = [NSURL URLWithFormat:@"%@://%@", URLScheme, [PostRoute stringByReplacingKey:@"post_id" withValue:@"123"]];
                        [manager handleURL:newsFeedURL];
                        NSURL *URL = [NSURL URLWithFormat:@"%@://%@", URLScheme, [ProfileRoute stringByReplacingKey:@"user_id" withValue:@"abc"]];
                        [manager handleURL:URL];
                        expect(manager.root.child.child.parameters[@"post_id"]).to.equal(@"123");
                        expect(manager.root.child.child.child.parameters[@"user_id"]).to.equal(@"abc");
                    });
                });
            });
            
            context(@"navigation to the same route with differen parameters", ^{
                it(@"should update parameters", ^{
                    NSURL *URL1 = [NSURL URLWithFormat:@"%@://%@", URLScheme, [PostRoute stringByReplacingKey:@"post_id" withValue:@"abc"]];
                    [manager handleURL:URL1];
                    expect(manager.root.leaf.parameters[@"post_id"]).to.equal(@"abc");

                    NSURL *URL2 = [NSURL URLWithFormat:@"%@://%@", URLScheme, [PostRoute stringByReplacingKey:@"post_id" withValue:@"xyz"]];
                    [manager handleURL:URL2];
                    expect(manager.root.leaf.parameters[@"post_id"]).to.equal(@"xyz");
                });

                it(@"should not change the node", ^{
                    NSURL *URL1 = [NSURL URLWithFormat:@"%@://%@", URLScheme, [PostRoute stringByReplacingKey:@"post_id" withValue:@"abc"]];
                    [manager handleURL:URL1];
                    VSPNavigationNode *oldPostNode = manager.root.leaf;
                    NSURL *URL2 = [NSURL URLWithFormat:@"%@://%@", URLScheme, [PostRoute stringByReplacingKey:@"post_id" withValue:@"xyz"]];
                    [manager handleURL:URL2];
                    expect(manager.root.leaf).to.beIdenticalTo(oldPostNode);
                });
                
                it(@"should not change the node", ^{
                    NSURL *URL1 = [NSURL URLWithFormat:@"%@://%@", URLScheme, [PostRoute stringByReplacingKey:@"post_id" withValue:@"abc"]];
                    [manager handleURL:URL1];
                    VSPNavigationNode *oldPostNode = manager.root.leaf;
                    NSURL *URL2 = [NSURL URLWithFormat:@"%@://%@", URLScheme, [PostRoute stringByReplacingKey:@"post_id" withValue:@"xyz"]];
                    [manager handleURL:URL2];
                    expect(manager.root.leaf).to.beIdenticalTo(oldPostNode);
                });
                
                pending(@"Behaviour is unclear: we we must explicitly express parameters that this node is interested in");
                xit(@"shouldn't change parameters on unrelated nodes", ^{
                    NSURL *URL1 = [NSURL URLWithFormat:@"%@://%@", URLScheme, [PostRoute stringByReplacingKey:@"post_id" withValue:@"abc"]];
                    [manager handleURL:URL1];
                    NSDictionary *newFeedParamaters = manager.root.child.parameters;
                    NSURL *URL2 = [NSURL URLWithFormat:@"%@://%@", URLScheme, [PostRoute stringByReplacingKey:@"post_id" withValue:@"xyz"]];
                    [manager handleURL:URL2];
                    expect(manager.root.child.parameters).to.equal(newFeedParamaters);                    
                });
            });
        });
    });
    
    context(@"Notifications", ^{
       context(@"did finish navigation", ^{
           it(@"should post notification when navigation is complete", ^{
               expect(^{
                   NSURL *URL = [NSURL URLWithFormat:@"%@://%@", URLScheme, [ProfileRoute stringByReplacingKey:@"user_id" withValue:@"abc"]];
                   [manager handleURL:URL];
               }).will.postNotification(VSPNavigationManagerDidFinishNavigationNotification);
           });
           
           it(@"notification should point to the manager", ^{
               waitUntil(^(DoneCallback done) {
                   __block id observer = [[NSNotificationCenter defaultCenter] addObserverForName:VSPNavigationManagerDidFinishNavigationNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
                       [[NSNotificationCenter defaultCenter] removeObserver:observer];
                       expect(note.object).to.beIdenticalTo(manager);                       
                       done();
                   }];
                   
                   NSURL *URL = [NSURL URLWithFormat:@"%@://%@", URLScheme, [ProfileRoute stringByReplacingKey:@"user_id" withValue:@"abc"]];
                   [manager handleURL:URL];
               });
           });
           
           it(@"should contain both old and a new tree when navigation is complete", ^{
               waitUntil(^(DoneCallback done) {
                   __block VSPNavigationNode *oldTreeCopy = [manager.root copy];
                   
                   __block id observer = [[NSNotificationCenter defaultCenter] addObserverForName:VSPNavigationManagerDidFinishNavigationNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
                       [[NSNotificationCenter defaultCenter] removeObserver:observer];
                       
                       expect(note.userInfo[VSPNavigationManagerNotificationSourceNodeKey]).to.equal(oldTreeCopy);

                       expect(note.userInfo[VSPNavigationManagerNotificationDestinationNodeKey]).to.equal(manager.root);
                       
                       done();
                   }];
                   
                   NSURL *URL = [NSURL URLWithFormat:@"%@://%@", URLScheme, [ProfileRoute stringByReplacingKey:@"user_id" withValue:@"abc"]];
                   [manager handleURL:URL];
               });
           });
       });
    });
});

SpecEnd


@implementation TestNavigationManager
- (void)addSimpleRuleForHostNodeId:(NSString *)hostNodeId childNodeId:(NSString *)childNodeId {
    [self addRuleForHostNodeId:hostNodeId childNodeId:childNodeId mountBlock:^(VSPNavigationNode *parent, VSPNavigationNode *child, VSPNavigatonTransitionCompletion completion) {
        UIViewController *parentController = parent.viewController;
        UIViewController *childController = child.viewController;
        [parentController addChildViewController:childController];
        childController.view.frame = parentController.view.bounds;
        childController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [parentController.view addSubview:childController.view];
        [childController didMoveToParentViewController:parentController];
        completion(YES);
    } unmounBlock:^(VSPNavigationNode *parent, VSPNavigationNode *child, VSPNavigatonTransitionCompletion completion) {
        [child.viewController willMoveToParentViewController:nil];
        [child.viewController.view removeFromSuperview];
        [child.viewController removeFromParentViewController];
        completion(YES);
    }];
}
- (void)registerSimpleNavigationForRoute:(NSString *)route nodeId:(NSString *)nodeId, ... {
    NSMutableArray *nodeIds = [NSMutableArray arrayWithObject:nodeId];
    va_list list;
    va_start(list, nodeId);
    NSString *currentNodeId;
    while ((currentNodeId = va_arg(list, NSString *))) {
        [nodeIds addObject:currentNodeId];
    };
    va_end(list);

    [self registerNavigationForRoute:route handler:^VSPNavigationNode *(NSDictionary *parameters) {
        VSPNavigationNode *root, *node;
        for (NSString *nodeId in nodeIds) {
            node = [VSPNavigationNode nodeWithParameters:parameters];
            node.nodeId = nodeId;
            node.viewController = [TestNodeViewController viewControllerForNodeId:nodeId];
            if (!root) {
                root = node;
            } else {
                root.leaf.child = node;
            }
        }
        return root;
    }];
}
@end
