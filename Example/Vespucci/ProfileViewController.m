//
//  ProfileViewController.m
//  Vespucci
//
//  Created by Sash Zats on 4/8/15.
//  Copyright (c) 2015 Wondermall. All rights reserved.
//

#import "ProfileViewController.h"

#import "NavigationService.h"
#import <ReactiveCocoa/ReactiveCocoa.h>


@interface ProfileViewController ()
@property (weak, nonatomic) IBOutlet UILabel *userIdLabel;
@property (nonatomic, copy) NSString *userId;
@end


@implementation ProfileViewController

#pragma mark - Actions

- (IBAction)_closeButtonAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        [[NavigationService sharedService] syncStateByRemovingLastNode];
    }];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    RAC(self, userId) = [RACObserve(self, navigationNode.parameters)
        map:^id(NSDictionary *dictionary) {
            return dictionary[@"userId"];
        }];
    
    RAC(self.userIdLabel, text) = RACObserve(self, userId);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([self.navigationNode.parameters[@"action"] isEqualToString:@"block"]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Block %@?", self.userId] message:nil delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Block", nil];
        [alertView show];
    }
}

@end
