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


NSString *const kKIOBeaconTestUUID = @"f7826da6-4fa2-4e98-8024-bc5b71e0893e";


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
    
    // TODO: use beaconUUID from server
    // Naw using temp kKIOBeaconTestUUID
    
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:kKIOBeaconTestUUID];
    self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:@"ru.kirillosipov.testBeaconRegion"];
    self.beaconRegion.notifyEntryStateOnDisplay = YES;
    
    self.beaconPeripheralData = [self.beaconRegion peripheralDataWithMeasuredPower:nil];
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:nil];
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    [self.locationManager startMonitoringForRegion:self.beaconRegion];
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
    
    CLBeacon *beacon = self.beacons[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"minor: %@, major: %@", beacon.minor, beacon.major];
    cell.detailTextLabel.text = [self proximityString:beacon];
    cell.backgroundColor = [self proximityColor:beacon];
    
    return cell;
}


#pragma mark - Styling

- (NSString *)proximityString:(CLBeacon *)beacon
{
    switch (beacon.proximity) {
        case CLProximityUnknown:
            return NSLocalizedString(@"PROXIMITY_UNKNOWN", nil);
            break;
        case CLProximityImmediate:
            return NSLocalizedString(@"PROXIMITY_IMMEDIATE", nil);
            break;
        case CLProximityNear:
            return NSLocalizedString(@"PROXIMITY_NEAR", nil);
            break;
        case CLProximityFar:
            return NSLocalizedString(@"PROXIMITY_FAR", nil);
            break;
    }
}

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
        self.navigationItem.title = NSLocalizedString(@"BROADCASTING", nil);
        [self.peripheralManager startAdvertising:[self.beaconRegion peripheralDataWithMeasuredPower:nil]];
    }
    else if (peripheral.state == CBPeripheralManagerStatePoweredOff)
    {
        self.navigationItem.title = NSLocalizedString(@"BLUTOOTH_OFF", nil);
        [self.peripheralManager stopAdvertising];
    }
    else if (peripheral.state == CBPeripheralManagerStateUnsupported)
    {
        self.navigationItem.title = NSLocalizedString(@"UNSUPPORTED_BL", nil);
    }
}


#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager*)manager didEnterRegion:(CLRegion*)region
{
    if([region isKindOfClass:[CLBeaconRegion class]] && [region.identifier isEqualToString:self.beaconRegion.identifier]) {
        [self.locationManager startRangingBeaconsInRegion:(CLBeaconRegion*)region];
    }
//    self.labelNearStatus.text = NSLocalizedString(@"GO_IN_TO_REGION", nil);
}

- (void)locationManager:(CLLocationManager*)manager didExitRegion:(CLRegion*)region
{
    if([region isKindOfClass:[CLBeaconRegion class]] && [region.identifier isEqualToString:self.beaconRegion.identifier]) {
        [self.locationManager stopRangingBeaconsInRegion:(CLBeaconRegion*)region];
    }
//    self.labelNearStatus.text = NSLocalizedString(@"GO_OUT_FROM_REGION", nil);
}

- (void)locationManager:(CLLocationManager*)manager didRangeBeacons:(NSArray*)beacons inRegion:(CLBeaconRegion*)region
{
    self.beacons = beacons;
    [self.tableView reloadData];
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    NSLog(@"didDetermineState: %i for region: %@", (int)state, region.identifier);
    
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
                                message:@"Pleace check location service! Or coll support..."
                               delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}


@end
