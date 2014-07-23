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
#import "KIOAPIDataStore.h"
#import "KIOBeacon.h"


typedef NS_ENUM(NSUInteger, TableViewDataStyle){
    TableViewDataStyleServer,
    TableViewDataStyleBeacon
};

@interface KIOBeaconListViewController () <CBPeripheralManagerDelegate, CLLocationManagerDelegate>

@property (nonatomic, weak) IBOutlet UIBarButtonItem *dataStyleButton;
@property (nonatomic, assign) TableViewDataStyle tableViewDataStyle;

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
    
    id uuids = [NSDictionary dictionaryWithContentsOfFile:[[KIOAPIDataStore sharedInstance] pathDataFile:kKIO_API_CASH_UUID_FILE]];
    NSString *beaconUUID = [[uuids valueForKey:kKIO_API_UUIDS_KEY] firstObject];
    NSLog(@"beaconUUID: %@", beaconUUID);
    
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:beaconUUID];
    self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:@"ru.kirillosipov.testBeaconRegion"];
    self.beaconRegion.notifyEntryStateOnDisplay = YES;
    self.beaconRegion.notifyOnEntry = YES;

    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];

    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;

    [[KIOAPIDataStore sharedInstance] deleteDataFile:kKIO_API_CASH_DATA_FILE];
    
    self.tableViewDataStyle = TableViewDataStyleBeacon;
    
    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(reload) forControlEvents:UIControlEventValueChanged];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Action

- (void)reload
{
    self.beacons = nil;
    [[KIOAPIDataStore sharedInstance] deleteDataFile:kKIO_API_CASH_DATA_FILE];
    
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

- (IBAction)chengeTableViewDataStyle:(UIBarButtonItem *)sender
{
    switch (self.tableViewDataStyle) {
        case TableViewDataStyleServer: {
            [self.dataStyleButton setImage:[UIImage imageNamed:@"ic_nav_server_str"]];
            self.tableViewDataStyle = TableViewDataStyleBeacon;
        }break;
            
        case TableViewDataStyleBeacon: {
            [self.dataStyleButton setImage:[UIImage imageNamed:@"ic_nav_tehno_str"]];
            self.tableViewDataStyle = TableViewDataStyleServer;
        }break;
    }
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.beacons.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    if (self.beacons.count > 0) {

        CLBeacon *beacon = self.beacons[indexPath.row];

        switch (self.tableViewDataStyle) {
                
            case TableViewDataStyleBeacon: {
                cell = [tableView dequeueReusableCellWithIdentifier:@"CellDataStyleBeacon" forIndexPath:indexPath];
                cell.textLabel.text = [NSString stringWithFormat:@"minor: %@, major: %@", beacon.minor, beacon.major];
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%.2f", beacon.accuracy];
            }break;
                
            case TableViewDataStyleServer: {
                cell = [tableView dequeueReusableCellWithIdentifier:@"CellDataStyleServer" forIndexPath:indexPath];
                NSDictionary *bdata = [NSDictionary dictionaryWithContentsOfFile:[[KIOAPIDataStore sharedInstance] pathDataFile:kKIO_API_CASH_DATA_FILE]];
                NSString *beaconID = [NSString stringWithFormat:@"%@-%@-%@", [beacon.proximityUUID.UUIDString lowercaseString], beacon.major, beacon.minor];
                cell.textLabel.text = (NSString *)bdata[beaconID][@"description"] ? bdata[beaconID][@"description"] : nil;
                cell.detailTextLabel.text = [self proximityData:beacon];
            }break;
        }
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

- (NSString *)proximityData:(CLBeacon *)beacon
{
    NSDictionary *bdata = [NSDictionary dictionaryWithContentsOfFile:[[KIOAPIDataStore sharedInstance] pathDataFile:kKIO_API_CASH_DATA_FILE]];
    NSString *beaconID = [NSString stringWithFormat:@"%@-%@-%@", [beacon.proximityUUID.UUIDString lowercaseString], beacon.major, beacon.minor];

    switch (beacon.proximity) {
        case CLProximityUnknown:
            return nil;
            break;
        case CLProximityImmediate:
            return bdata[beaconID][@"description_immediate"];
            break;
        case CLProximityNear:
            return bdata[beaconID][@"description_near"];
            break;
        case CLProximityFar:
            return bdata[beaconID][@"description_far"];
            break;
    }
}

#pragma mark - CBPeripheralManagerDelegate

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    if (peripheral.state == CBPeripheralManagerStatePoweredOn)
    {
        self.navigationItem.title = @"BLUTOOTH_ON";
        [self.locationManager startMonitoringForRegion:self.beaconRegion];
        [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
        [self.tableView reloadData];
    }
    else if (peripheral.state == CBPeripheralManagerStatePoweredOff)
    {
        self.navigationItem.title = @"BLUTOOTH_OFF";
        [self.locationManager stopMonitoringForRegion:self.beaconRegion];
        [self.locationManager stopRangingBeaconsInRegion:self.beaconRegion];
        self.beacons = nil;
        [self.tableView reloadData];
    }
    else if (peripheral.state == CBPeripheralManagerStateUnsupported)
    {
        self.navigationItem.title = @"UNSUPPORTED_BL";
        [self.locationManager stopRangingBeaconsInRegion:self.beaconRegion];
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
        self.beacons = nil;
        [self.locationManager stopMonitoringForRegion:self.beaconRegion];
//        [self.locationManager stopRangingBeaconsInRegion:(CLBeaconRegion*)region];
    }
}

- (void)locationManager:(CLLocationManager*)manager didRangeBeacons:(NSArray*)beacons inRegion:(CLBeaconRegion*)region
{
    self.beacons = beacons;
    if ([[KIOAPIDataStore sharedInstance] cashExists:kKIO_API_CASH_DATA_FILE] == NO) {
        for (CLBeacon *beacon in beacons) {
            [[KIOAPIDataStore sharedInstance] loadBeacon:beacon reloadCash:NO mainQueue:nil];
        }
    } else {
        [self.tableView reloadData];
    }
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    if([region isKindOfClass:[CLBeaconRegion class]] && [region.identifier isEqualToString:self.beaconRegion.identifier]) {

//        UILocalNotification *localNotification = [[UILocalNotification alloc] init];

        CLBeaconRegion *beaconRegion = (CLBeaconRegion *)region;
        if (state == CLRegionStateInside) {
//            localNotification.alertBody = [NSString stringWithFormat:@"You are inside region %@", region.identifier];
//            localNotification.soundName = UILocalNotificationDefaultSoundName;
//            [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];

            [self.locationManager startRangingBeaconsInRegion:beaconRegion];
        } else {
            [self.locationManager stopRangingBeaconsInRegion:beaconRegion];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    [[[UIAlertView alloc] initWithTitle:@"Location not avalible"
                                message:@"Pleace check location service! Or call support..."
                               delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}


@end
