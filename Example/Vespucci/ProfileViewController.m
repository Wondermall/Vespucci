//
//  ProfileViewController.m
//  Vespucci
//
//  Created by Sash Zats on 4/8/15.
//  Copyright (c) 2015 Wondermall. All rights reserved.
//

#import "ProfileViewController.h"

#import <ReactiveCocoa/ReactiveCocoa.h>

@interface ProfileViewController ()
@property (weak, nonatomic) IBOutlet UILabel *userIdLabel;

@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    RAC(self.userIdLabel, text) = [RACObserve(self, navigationNode.parameters)
        map:^id(NSDictionary *dictionary) {
            return dictionary[@"userId"];
        }];
}

@end
