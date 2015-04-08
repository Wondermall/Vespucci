//
//  MessageViewController.m
//  Vespucci
//
//  Created by Sash Zats on 4/8/15.
//  Copyright (c) 2015 Sash Zats. All rights reserved.
//

#import "MessageViewController.h"

#import <ReactiveCocoa/ReactiveCocoa.h>


@interface MessageViewController ()
@property (weak, nonatomic) IBOutlet UILabel *messageIdLabel;
@end

@implementation MessageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    RAC(self.messageIdLabel, text) = [RACObserve(self, navigationParameters)
        map:^id(NSDictionary *parameters) {
            return parameters[@"messageId"];
        }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
