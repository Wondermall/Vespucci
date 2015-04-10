//
//  MessageViewController.m
//  Vespucci
//
//  Created by Sash Zats on 4/8/15.
//  Copyright (c) 2015 Sash Zats. All rights reserved.
//

#import "MessageViewController.h"

#import "NavigationService.h"
#import <ReactiveCocoa/ReactiveCocoa.h>


@interface MessageViewController ()
@property (weak, nonatomic) IBOutlet UILabel *messageIdLabel;
@property (nonatomic) IBOutlet UIBarButtonItem *blockBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *profileBarButtonItem;
@property (nonatomic, copy) NSString *userId;
@end

@implementation MessageViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItems = @[ self.blockBarButtonItem, self.profileBarButtonItem ];
    
    RAC(self, userId) = [RACObserve(self, navigationNode)
        map:^id(WMLNavigationNode *node) {
            // this is just a demo, right?
            return node.parameters[@"messageId"];
        }];
    RAC(self.messageIdLabel, text) = RACObserve(self, userId);
}

#pragma mark - Actions

- (IBAction)_closeButtonAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        [[NavigationService sharedService] syncStateByRemovingLastNode];
    }];
}

- (IBAction)_profileButtonAction:(id)sender {
    NSURL *URL = [[NavigationService sharedService] profileURLForUser:self.userId];
    [[UIApplication sharedApplication] openURL:URL];
}

- (IBAction)_blockButtonAction:(id)sender {

}

@end
