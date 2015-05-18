#import "TestHelpers.h"
#import <Vespucci/Vespucci.h>

SpecBegin(VSPNavigationManager)

describe(@"VSPNavigationManager", ^{
    __block VSPNavigationManager *manager;
    
    beforeEach(^{
        manager = [[VSPNavigationManager alloc] initWithURLScheme:@"test"];
    });
    
    context(@"initial state", ^{
        it(@"should have no URL and no navigation root", ^{
            expect(manager.root).to.beNil();
        });
        
        it(@"should set navigation root and URL correctly", ^{
            VSPNavigationNode *node = [VSPNavigationNode node];
            node.nodeId = @"my-node-id";
            [manager setNavigationRoot:node];
            expect(manager.root).to.equal(node);
        });
    });
    
    context(@"Hosting", ^{
        context(@"Registering routes", ^{
            it(@"should parse parameters correctly", ^{
                waitUntil(^(DoneCallback done) {
                    [manager registerNavigationForRoute:@"/route/:route_id" handler:^VSPNavigationNode *(NSDictionary *parameters) {
                        expect(parameters[@"route_id"]).to.equal(@"123");
                        done();
                        return nil;
                    }];
                    [manager handleURL:[NSURL URLWithString:@"test://route/123"]];
                });
            });
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
            
            pending(@"Navigation tests have to be rewritten");
            xcontext(@"navigation", ^{
                
                context(@"without root node set", ^{
                    it(@"should raise an exception", ^{
                        
                    });
                });
                context(@"with root node set", ^{
                    beforeEach(^{
                        VSPNavigationNode *node = [VSPNavigationNode node];
                        node.viewController = [UIViewController new];
                        [manager setNavigationRoot:node];
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
