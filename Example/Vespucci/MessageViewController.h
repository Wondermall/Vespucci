//
//  MessageViewController.h
//  Vespucci
//
//  Created by Sash Zats on 4/8/15.
//  Copyright (c) 2015 Sash Zats. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Vespucci/Vespucci.h>


@interface MessageViewController : UIViewController <WMLNavigationParametrizedViewController>

@property (nonatomic, weak) WMLNavigationNode *navigationNode;

@end
