//
//  NotificationsViewController.m
//  Vespucci
//
//  Created by Sash Zats on 4/8/15.
//  Copyright (c) 2015 Sash Zats. All rights reserved.
//

#import "NotificationsViewController.h"
#import "NavigationService.h"


@interface NotificationsViewController ()

@end


@implementation NotificationsViewController

#pragma mark - Private

- (void)_openProfile {
    NSURL *url = [[NavigationService sharedService] profileURLForUser:@"Johny"];
    [[NavigationService sharedService] handleURL:url];
}

- (void)_openMessages {
    NSURL *url = [[NavigationService sharedService] messageURLForMessageId:[self _randomId]];
    [[NavigationService sharedService] handleURL:url];
}

- (void)_openPicture {
    NSURL *url = [[NavigationService sharedService] picturesURLForPictureId:[self _randomId]];
    [[NavigationService sharedService] handleURL:url];
}

- (NSString *)_randomId {
    return [NSString stringWithFormat:@"%X-%X", arc4random_uniform(0xFFFFFF), arc4random_uniform(0xFFFFFF)];
}

#pragma mark - UITableViewControllerDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0: {
            [self _openProfile];
            break;
        }
        case 1: {
            [self _openPicture];
            break;
        }
        case 2: {
            [self _openMessages];
            break;
        }
        default: {
            NSAssert(NO, @"Unexpected row: %tu", indexPath.row);
            break;
        }
    }
}

@end
