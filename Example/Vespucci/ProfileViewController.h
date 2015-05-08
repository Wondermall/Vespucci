//
//  ProfileViewController.h
//  Vespucci
//
//  Created by Sash Zats on 4/8/15.
//  Copyright (c) 2015 Wondermall. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Vespucci/Vespucci.h>


@interface ProfileViewController : UIViewController <VSPNavigatable>
@property (nonatomic, weak) VSPNavigationNode *navigationNode;
@end
