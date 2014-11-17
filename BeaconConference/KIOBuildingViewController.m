//
//  KIOBuildingViewController.m
//  BeaconConference
//
//  Created by Kirill Osipov on 02.10.14.
//  Copyright (c) 2014 Kirill Osipov. All rights reserved.
//

#import "KIOBuildingViewController.h"
#import "KIOGridView.h"
#import "KIOAPIDataStore.h"
#import "KIOServiceController.h"
#import "KIOBeacon.h"

#import "CLBeacon+Helper.h"
#import "UIColor+Styling.h"


@interface KIOBuildingViewController ()

@property (weak, nonatomic) IBOutlet KIOGridView *drawingView;
@property (strong, nonatomic) NSArray *beaconsData;

@end

@implementation KIOBuildingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.drawingView.fieldSize = 8;
    
    [[KIOAPIDataStore dataStore]
     loadBeaconSuccessBlock:^(NSArray *beacons) {
         
         self.beaconsData = beacons;

    } errorBlock:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(notificationBeacons:)
               name:kKIOServiceBeaconsInRegionNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - NSNotification

- (void)notificationBeacons:(NSNotification *)notification
{
    NSArray *beacons = (NSArray *)notification.userInfo[@"beacons"];
    
    NSMutableDictionary *tempArray = [NSMutableDictionary dictionaryWithCapacity:beacons.count];
    for (CLBeacon *beacon in beacons) {
        if ([[KIOAPIDataStore dataStore] dataBeaconFrom:self.beaconsData forCLBeacon:beacon]) {
            
            KIOBeacon *beaconData = [[KIOAPIDataStore dataStore] dataBeaconFrom:self.beaconsData forCLBeacon:beacon];
            CGPoint beaconPoint = CGPointMake(beaconData.point.x, beaconData.point.y);
            [tempArray setObject:[UIColor proximityBeaconColor:beacon withAlphaComponent:.6f]
                          forKey:NSStringFromCGPoint(beaconPoint)];
        };
    }
    self.drawingView.beaconPointWithColor = tempArray;
    [self.drawingView setNeedsDisplay];
}

@end
