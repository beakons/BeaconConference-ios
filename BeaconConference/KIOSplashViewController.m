//
//  KIOSplashViewController.m
//  BeaconConference
//
//  Created by Kirill Osipov on 15.07.14.
//  Copyright (c) 2014 Kirill Osipov. All rights reserved.
//

static NSString *const kKIOSplashSegueSuccess = @"successSegue";
static NSString *const kKIOSplashSegueError = @"errorSeque";


#import "KIOSplashViewController.h"
#import "KIOShchigelskyAPI.h"


@implementation KIOSplashViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self loadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Load Data

- (void)loadData
{
    [[KIOShchigelskyAPI sharedInstance] loadBeaconListWithUpdateCash:YES mainQueue:^(BOOL isDone) {
        if (isDone == YES) {
            [NSThread sleepForTimeInterval:1.0];
            [self performSegueWithIdentifier:kKIOSplashSegueSuccess sender:self];
        } else {
            [[[UIAlertView alloc] initWithTitle:nil message:@"No conection to api.shchigelsky or internet is swith off"
                                       delegate:self cancelButtonTitle:@"reload" otherButtonTitles:@"exit", nil] show];
        }
    }];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [self loadData];
    } else {
        [[UIApplication sharedApplication] performSelector:@selector(suspend)];
        [NSThread sleepForTimeInterval:2.0];
        exit(0);
    }
}


@end
