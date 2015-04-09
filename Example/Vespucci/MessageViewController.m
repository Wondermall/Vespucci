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
@end

@implementation MessageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    RAC(self.messageIdLabel, text) = [RACObserve(self, navigationNode)
        map:^id(WMLNavigationNode *node) {
            return node.parameters[@"messageId"];
        }];
}

- (IBAction)_closeButtonAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        [[NavigationService sharedService] syncStateByRemovingLastNode];
    }];
}

- (IBAction)_profileButtonAction:(id)sender {
    NSString *messageId = self.navigationNode.parameters[@"messageId"];
    NSString *userId = [NSString stringWithFormat:@"user-%@",messageId];
    NSURL *URL = [[NavigationService sharedService] profileURLForUser:userId];
    [[UIApplication sharedApplication] openURL:URL];
}

@end
