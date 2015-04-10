//
//  MessagesListViewController.m
//  Vespucci
//
//  Created by Sash Zats on 4/8/15.
//  Copyright (c) 2015 Sash Zats. All rights reserved.
//

#import "MessagesListViewController.h"
#import "NavigationService.h"

@interface MessagesListViewController ()
@property (nonatomic, copy) NSArray *userIds;
@end


@implementation MessagesListViewController

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (!self) {
        return nil;
    }
    self.userIds = @[ @"Stephany", @"Johny" ];
    return self;
}

#pragma mark - Private

- (void)_openConversationAtIndex:(NSUInteger)row {
    NSURL *URL = [[NavigationService sharedService] messageURLForMessageId:self.userIds[row]];
    [[UIApplication sharedApplication] openURL:URL];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self _openConversationAtIndex:indexPath.row];
}

@end
