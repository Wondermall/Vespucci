//
//  VSPNavigationManager+Internal.h
//  Pods
//
//  Created by Sash Zats on 6/10/15.
//
//

#import "VSPNavigationManager.h"


@interface VSPNavigationManager (Internal)

- (VSPViewControllerFactory)viewControllerFactoryForNodeId:(NSString *)nodeId;

@end
