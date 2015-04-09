//
//  RootViewController.m
//  Vespucci
//
//  Created by Sash Zats on 04/08/2015.
//  Copyright (c) 2014 Sash Zats. All rights reserved.
//

#import "RootViewController.h"

#import "NavigationService.h"
#import <ReactiveCocoa/ReactiveCocoa.h>


@interface RootViewController () <UITabBarControllerDelegate>

@end


@implementation RootViewController

#pragma mark - Private

- (void)_addRestGesture {
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] init];
    gesture.numberOfTapsRequired = 2;
    [self rac_liftSelector:@selector(_reset:) withSignals:gesture.rac_gestureSignal, nil];
    [self.view addGestureRecognizer:gesture];
}

- (void)_reset:(id)sender {
    [[NavigationService sharedService] setupDefaultRoutesWithRootViewController:self];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[NavigationService sharedService] setupDefaultRoutesWithRootViewController:self];
    });

    [self _addRestGesture];
}

#pragma mark - UITabBarControllerDelegate


- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    [[NavigationService sharedService] syncStateForRootController:self];
}

@end
