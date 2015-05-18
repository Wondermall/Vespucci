#import "TestHelpers.h"
#import <Vespucci/Vespucci.h>


SpecBegin(VSPNavigationNode)

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
            node.viewController = [TestNodeViewController new];
            expect(((TestNodeViewController *)node.viewController).navigationNode).to.beIdenticalTo(node);
        });
        
        it(@"should stil works for view controller not conforming VSPNavigationParametrizedViewController", ^{
            VSPNavigationNode *node = [VSPNavigationNode node];
            expect(^{
                node.viewController = [TestNodeViewController new];
            }).notTo.raiseAny();
        });
    });
});

SpecEnd
