//
//  VespucciTests.m
//  VespucciTests
//
//  Created by Sash Zats on 04/08/2015.
//  Copyright (c) 2014 Sash Zats. All rights reserved.
//

#import "VSPNavigationNode.h"
#import "VSPNavigationManager.h"
#import "VSPNavigatable.h"

@interface ViewController : UIViewController <VSPNavigatable>
@property (nonatomic, weak) VSPNavigationNode *navigationNode;
@end

@implementation ViewController
@end


SpecBegin(InitialSpecs)

describe(@"VSPNavigationNode", ^{
    context(@"isRootNode", ^{
        it(@"should return true if has no parent", ^{
            VSPNavigationNode *node = [VSPNavigationNode node];
            node.child = [VSPNavigationNode node];
            expect(node.isRootNode).to.beTruthy();
        });
        
        it(@"should be falsy has a parent", ^{
            VSPNavigationNode *node = [VSPNavigationNode node];
            node.child = [VSPNavigationNode node];
            expect(node.child.isRootNode).to.beFalsy();
        });
    });
    
    context(@"root", ^{
        it(@"should report itself if has no parent", ^{
            VSPNavigationNode *node = [VSPNavigationNode node];
            node.child = [VSPNavigationNode node];
            expect(node.root).to.beIdenticalTo(node);
        });
        
        it(@"should report its parent if it has no parent", ^{
            VSPNavigationNode *node = [VSPNavigationNode node];
            node.child = [VSPNavigationNode node];
            expect(node.child.root).to.beIdenticalTo(node);
        });
    });
    
    context(@"leaf", ^{
        it(@"should report itself if has no child", ^{
            VSPNavigationNode *node = [VSPNavigationNode node];
            expect(node.leaf).to.beIdenticalTo(node);
        });
        
        it(@"should report its furthest descent if has children", ^{
            VSPNavigationNode *node = [VSPNavigationNode node];
            node.child = [VSPNavigationNode node];
            expect(node.leaf).to.beIdenticalTo(node.child);
        });
    });
    
    context(@"viewController", ^{
        it(@"should set view controller's node if conforms VSPNavigationParametrizedViewController", ^{
            VSPNavigationNode *node = [VSPNavigationNode node];
            node.viewController = [ViewController new];
            expect(((ViewController *)node.viewController).navigationNode).to.beIdenticalTo(node);
        });
        
        it(@"should stil works for view controller not conforming VSPNavigationParametrizedViewController", ^{
            VSPNavigationNode *node = [VSPNavigationNode node];
            expect(^{
                node.viewController = [ViewController new];
            }).notTo.raiseAny();
        });
    });
});

describe(@"VSPNavigationManager", ^{
    __block VSPNavigationManager *manager;
    
    beforeEach(^{
        manager = [[VSPNavigationManager alloc] initWithURLScheme:@"test"];
    });
    
    context(@"initial state", ^{
        it(@"URL should contain just the scheme", ^{
            expect(manager.URL).to.equal([NSURL URLWithString:@"test://"]);
        });
        
        it(@"should have no URL and no navigation root", ^{
            expect(manager.root).to.beNil();
        });
        
        it(@"should set navigation root and URL correctly", ^{
            VSPNavigationNode *node = [VSPNavigationNode node];
            node.nodeId = @"my-node-id";
            NSURL *URL = [NSURL URLWithString:@"test://example/"];
            [manager setNavigationRoot:node URL:URL];
            expect(manager.URL).to.equal([NSURL URLWithString:@"test://example/"]);
            expect(manager.root).to.equal(node);
        });
    });
    
    context(@"Hosting", ^{
        describe(@"registering routes", ^{
            context(@"parameters", ^{
                it(@"should parse parameters correctly", ^{
                    [manager registerNavigationForRoute:@"/route/:route_id" handler:^VSPNavigationNode *(NSDictionary *parameters) {
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
                        VSPNavigationNode *node = [VSPNavigationNode node];
                        node.viewController = [UIViewController new];
                        [manager setNavigationRoot:node URL:[NSURL URLWithString:@"test://"]];
                    });
                    
                    it(@"should navigate successfully if route is registered and returns a node", ^{
                        [manager registerNavigationForRoute:@"/route/:route_id" handler:^VSPNavigationNode *(NSDictionary *parameters) {
                            VSPNavigationNode *node = [VSPNavigationNode nodeWithParameters:parameters];
                            node.viewController = [UIViewController new];
                            return node;
                        }];
                        expect([manager handleURL:[NSURL URLWithString:@"test://route/123"]]).to.beTruthy();
                    });
                    
                    it(@"should not navigate if route is registered but returns nil", ^{
                        [manager registerNavigationForRoute:@"/route/:route_id" handler:^VSPNavigationNode *(NSDictionary *parameters) {
                            return nil;
                        }];
                        expect([manager handleURL:[NSURL URLWithString:@"test://route/123"]]).to.beFalsy();
                    });
                    
                    it(@"should not navigate if route is not registered", ^{
                        [manager registerNavigationForRoute:@"/route/:route_id" handler:^VSPNavigationNode *(NSDictionary *parameters) {
                            VSPNavigationNode *node = [VSPNavigationNode nodeWithParameters:parameters];
                            node.viewController = [UIViewController new];
                            return node;
                        }];
                        expect([manager handleURL:[NSURL URLWithString:@"test://not-route/123"]]).to.beFalsy();
                    });
                    
                    it(@"should raise an exception if no view controller set on node for navigation", ^{
                        [manager registerNavigationForRoute:@"/route/:route_id" handler:^VSPNavigationNode *(NSDictionary *parameters) {
                            VSPNavigationNode *node = [VSPNavigationNode nodeWithParameters:parameters];
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
