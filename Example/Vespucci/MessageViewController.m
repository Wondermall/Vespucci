//
//  MessageViewController.m
//  Vespucci
//
//  Created by Sash Zats on 4/8/15.
//  Copyright (c) 2015 Sash Zats. All rights reserved.
//

#import "MessageViewController.h"

#import "NavigationService.h"


@interface MessageViewController ()
@property (weak, nonatomic) IBOutlet UILabel *messageIdLabel;
@property (nonatomic) IBOutlet UIBarButtonItem *blockBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *profileBarButtonItem;
@property (nonatomic, copy) NSString *messageId;
@end

@implementation MessageViewController

#pragma mark - Lifecycle

- (void)setNavigationNode:(VSPNavigationNode *)navigationNode {
    _navigationNode = navigationNode;
    self.messageId = navigationNode.parameters[@"messageId"];
    self.messageIdLabel.text = self.messageId;
}

#pragma mark - Actions

- (IBAction)_closeButtonAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        [[NavigationService sharedService] syncStateByRemovingLastNode];
    }];
}

- (IBAction)_profileButtonAction:(id)sender {
    NSURL *url = [[NavigationService sharedService] profileURLForUser:self.messageId];
    [[NavigationService sharedService] handleURL:url];
}

- (IBAction)_blockButtonAction:(id)sender {
    NSURL *url = [[NavigationService sharedService] blockUserWithUserIdURL:self.messageId];
    [[NavigationService sharedService] handleURL:url];
}

@end
