//
//  VespucciTests.m
//  VespucciTests
//
//  Created by Sash Zats on 04/08/2015.
//  Copyright (c) 2014 Sash Zats. All rights reserved.
//

#import "WMLNavigationNode.h"
#import "WMLNavigationManager.h"
#import "WMLNavigatable.h"

@interface ViewController : UIViewController <WMLNavigatable>
@property (nonatomic, weak) WMLNavigationNode *navigationNode;
@end

@implementation ViewController
@end


SpecBegin(InitialSpecs)

describe(@"WMLNavigationNode", ^{
    context(@"isRootNode", ^{
        it(@"should return true if has no parent", ^{
            WMLNavigationNode *node = [WMLNavigationNode node];
            node.child = [WMLNavigationNode node];
            expect(node.isRootNode).to.beTruthy();
        });
        
        it(@"should be falsy has a parent", ^{
            WMLNavigationNode *node = [WMLNavigationNode node];
            node.child = [WMLNavigationNode node];
            expect(node.child.isRootNode).to.beFalsy();
        });
    });
    
    context(@"root", ^{
        it(@"should report itself if has no parent", ^{
            WMLNavigationNode *node = [WMLNavigationNode node];
            node.child = [WMLNavigationNode node];
            expect(node.root).to.beIdenticalTo(node);
        });
        
        it(@"should report its parent if it has no parent", ^{
            WMLNavigationNode *node = [WMLNavigationNode node];
            node.child = [WMLNavigationNode node];
            expect(node.child.root).to.beIdenticalTo(node);
        });
    });
    
    context(@"leaf", ^{
        it(@"should report itself if has no child", ^{
            WMLNavigationNode *node = [WMLNavigationNode node];
            expect(node.leaf).to.beIdenticalTo(node);
        });
        
        it(@"should report its furthest descent if has children", ^{
            WMLNavigationNode *node = [WMLNavigationNode node];
            node.child = [WMLNavigationNode node];
            expect(node.leaf).to.beIdenticalTo(node.child);
        });
    });
    
    context(@"viewController", ^{
        it(@"should set view controller's node if conforms WMLNavigationParametrizedViewController", ^{
            WMLNavigationNode *node = [WMLNavigationNode node];
            node.viewController = [ViewController new];
            expect(((ViewController *)node.viewController).navigationNode).to.beIdenticalTo(node);
        });
        
        it(@"should stil works for view controller not conforming WMLNavigationParametrizedViewController", ^{
            WMLNavigationNode *node = [WMLNavigationNode node];
            expect(^{
                node.viewController = [ViewController new];
            }).notTo.raiseAny();
        });
    });
});

describe(@"WMLNavigationManager", ^{
    __block WMLNavigationManager *manager;
    
    beforeEach(^{
        manager = [[WMLNavigationManager alloc] initWithURLScheme:@"test"];
    });
    
    context(@"initial state", ^{
        it(@"URL should contain just the scheme", ^{
            expect(manager.URL).to.equal([NSURL URLWithString:@"test://"]);
        });
        
        it(@"should have no URL and no navigation root", ^{
            expect(manager.navigationRoot).to.beNil();
        });
        
        it(@"should set navigation root and URL correctly", ^{
            WMLNavigationNode *node = [WMLNavigationNode node];
            node.nodeId = @"my-node-id";
            NSURL *URL = [NSURL URLWithString:@"test://example/"];
            [manager setNavigationRoot:node URL:URL];
            expect(manager.URL).to.equal([NSURL URLWithString:@"test://example/"]);
            expect(manager.navigationRoot).to.equal(node);
        });
    });
    
    context(@"Hosting", ^{
        describe(@"registering routes", ^{
            context(@"parameters", ^{
                it(@"should parse parameters correctly", ^{
                    [manager registerNavigationForRoute:@"/route/:route_id" handler:^WMLNavigationNode *(NSDictionary *parameters) {
                        expect(parameters[@"route_id"]).to.equal(@"123");
                        return nil;
                    }];
                    [manager handleURL:[NSURL URLWithString:@"test://route/123"]];
                });
            });
            
            context(@"navigation", ^{
                context(@"without root node set", ^{
                    it(@"should raise an exception", ^{
                        
                    });
                });
                context(@"with root node set", ^{
                    beforeEach(^{
                        WMLNavigationNode *node = [WMLNavigationNode node];
                        node.viewController = [UIViewController new];
                        [manager setNavigationRoot:node URL:[NSURL URLWithString:@"test://"]];
                    });
                    
                    it(@"should navigate successfully if route is registered and returns a node", ^{
                        [manager registerNavigationForRoute:@"/route/:route_id" handler:^WMLNavigationNode *(NSDictionary *parameters) {
                            WMLNavigationNode *node = [WMLNavigationNode nodeWithParameters:parameters];
                            node.viewController = [UIViewController new];
                            return node;
                        }];
                        expect([manager handleURL:[NSURL URLWithString:@"test://route/123"]]).to.beTruthy();
                    });
                    
                    it(@"should not navigate if route is registered but returns nil", ^{
                        [manager registerNavigationForRoute:@"/route/:route_id" handler:^WMLNavigationNode *(NSDictionary *parameters) {
                            return nil;
                        }];
                        expect([manager handleURL:[NSURL URLWithString:@"test://route/123"]]).to.beFalsy();
                    });
                    
                    it(@"should not navigate if route is not registered", ^{
                        [manager registerNavigationForRoute:@"/route/:route_id" handler:^WMLNavigationNode *(NSDictionary *parameters) {
                            WMLNavigationNode *node = [WMLNavigationNode nodeWithParameters:parameters];
                            node.viewController = [UIViewController new];
                            return node;
                        }];
                        expect([manager handleURL:[NSURL URLWithString:@"test://not-route/123"]]).to.beFalsy();
                    });
                    
                    it(@"should raise an exception if no view controller set on node for navigation", ^{
                        [manager registerNavigationForRoute:@"/route/:route_id" handler:^WMLNavigationNode *(NSDictionary *parameters) {
                            WMLNavigationNode *node = [WMLNavigationNode nodeWithParameters:parameters];
                            return node;
                        }];
                        expect(^{
                            [manager handleURL:[NSURL URLWithString:@"test://route/123"]];
                        }).to.raiseAny();
                        
                    });
                });
            });
        });
    });
});


SpecEnd
