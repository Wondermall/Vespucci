//
//  VespucciTests.m
//  VespucciTests
//
//  Created by Sash Zats on 04/08/2015.
//  Copyright (c) 2014 Sash Zats. All rights reserved.
//

#import "WMLNavigationNode.h"


@interface ViewController : UIViewController <WMLNavigationParametrizedViewController>
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


SpecEnd
