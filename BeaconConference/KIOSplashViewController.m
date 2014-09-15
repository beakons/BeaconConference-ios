//
//  KIOSplashViewController.m
//  BeaconConference
//
//  Created by Kirill Osipov on 15.07.14.
//  Copyright (c) 2014 Kirill Osipov. All rights reserved.
//

static NSString *const kKIOSplashSegueSuccess = @"successSegue";

#import "KIOSplashViewController.h"
#import "KIOAPIDataStore.h"

@interface KIOSplashViewController () <UIAlertViewDelegate>
@end


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
    [[KIOAPIDataStore dataStore] loadUUIDSuccessBlock:^(NSArray *uuids) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSThread sleepForTimeInterval:1.0];
            [self performSegueWithIdentifier:kKIOSplashSegueSuccess sender:self];
        });
        
    }
                                           errorBlock:^(NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Attantion code: %i", (int)error.code]
                                        message:error.userInfo[KIO_API_ERROR_DESCRIPTION_KEY]
                                       delegate:self
                              cancelButtonTitle:@"reload"
                              otherButtonTitles:@"exit", nil] show];
        });
        
    }
     ];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [self loadData];
    } else {
        [[UIApplication sharedApplication] performSelector:@selector(suspend)];
        [NSThread sleepForTimeInterval:1.0];
        exit(0);
    }
}


@end
