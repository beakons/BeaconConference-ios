//
//  KIOBeaconListViewController.m
//  BeaconConference
//
//  Created by Kirill Osipov on 15.07.14.
//  Copyright (c) 2014 Kirill Osipov. All rights reserved.
//

@import CoreLocation;
@import CoreBluetooth;

#import "KIOBeaconListViewController.h"
#import "KIOShchigelskyAPI.h"


@interface KIOBeaconListViewController () <CBPeripheralManagerDelegate, CLLocationManagerDelegate>

@property (nonatomic, strong) CLBeaconRegion *beaconRegion;
@property (strong, nonatomic) NSDictionary *beaconPeripheralData;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;

@property (nonatomic, strong) NSArray *beacons;

@end


@implementation KIOBeaconListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *beaconUUID = [[NSArray arrayWithContentsOfFile:[[KIOShchigelskyAPI sharedInstance] pathDataFile:kKIOAPICashUUID]] firstObject];
    NSLog(@"beaconUUID: %@", beaconUUID);
    
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:beaconUUID];
    self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:@"ru.kirillosipov.testBeaconRegion"];
    self.beaconRegion.notifyEntryStateOnDisplay = YES;

    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:nil];

    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;

    [self.locationManager startMonitoringForRegion:self.beaconRegion];
    
    [[KIOShchigelskyAPI sharedInstance] deleteDataFile:kKIOAPICashData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.beacons.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    if (self.beacons.count > 0) {
        CLBeacon *beacon = self.beacons[indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"minor: %@, major: %@", beacon.minor, beacon.major];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%.2f", beacon.accuracy];
        cell.backgroundColor = [self proximityColor:beacon];
    }
    
    return cell;
}


#pragma mark - Styling

- (UIColor *)proximityColor:(CLBeacon *)beacon
{
    switch (beacon.proximity) {
        case CLProximityUnknown:
            return [UIColor whiteColor];
            break;
        case CLProximityImmediate:
            return [UIColor redColor];
            break;
        case CLProximityNear:
            return [UIColor greenColor];
            break;
        case CLProximityFar:
            return [UIColor yellowColor];
            break;
    }
}


#pragma mark - CBPeripheralManagerDelegate

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    if (peripheral.state == CBPeripheralManagerStatePoweredOn)
    {
        self.navigationItem.title = @"BLUTOOTH_ON";
        [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
    }
    else if (peripheral.state == CBPeripheralManagerStatePoweredOff)
    {
        self.navigationItem.title = @"BLUTOOTH_OFF";
        [self.locationManager stopRangingBeaconsInRegion:self.beaconRegion];
        self.beacons = nil;
        [self.tableView reloadData];
    }
    else if (peripheral.state == CBPeripheralManagerStateUnsupported)
    {
        self.navigationItem.title = @"UNSUPPORTED_BL";
    }
}


#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager*)manager didEnterRegion:(CLRegion*)region
{
    if([region isKindOfClass:[CLBeaconRegion class]] && [region.identifier isEqualToString:self.beaconRegion.identifier]) {
        [self.locationManager startRangingBeaconsInRegion:(CLBeaconRegion*)region];
    }
}

- (void)locationManager:(CLLocationManager*)manager didExitRegion:(CLRegion*)region
{
    if([region isKindOfClass:[CLBeaconRegion class]] && [region.identifier isEqualToString:self.beaconRegion.identifier]) {
        [self.locationManager stopRangingBeaconsInRegion:(CLBeaconRegion*)region];
    }
}

- (void)locationManager:(CLLocationManager*)manager didRangeBeacons:(NSArray*)beacons inRegion:(CLBeaconRegion*)region
{
    self.beacons = beacons;
    if ([[KIOShchigelskyAPI sharedInstance] cashExists:kKIOAPICashData] == NO) {
        for (CLBeacon *beacon in beacons) {
            [[KIOShchigelskyAPI sharedInstance] loadBeaconInfo:beacon updateCash:NO mainQueue:nil];
        }
    }
    [self.tableView reloadData];
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    if([region isKindOfClass:[CLBeaconRegion class]] && [region.identifier isEqualToString:self.beaconRegion.identifier]) {

        CLBeaconRegion *beaconRegion = (CLBeaconRegion *)region;
        if(state == CLRegionStateInside)
            [self.locationManager startRangingBeaconsInRegion:beaconRegion];
        else
            [self.locationManager stopRangingBeaconsInRegion:beaconRegion];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    [[[UIAlertView alloc] initWithTitle:@"Location not avalible"
                                message:@"Pleace check location service! Or call support..."
                               delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}


@end
