//
//  KIOBeaconListViewController.m
//  BeaconConference
//
//  Created by Kirill Osipov on 15.07.14.
//  Copyright (c) 2014 Kirill Osipov. All rights reserved.
//

@import CoreLocation;

#import "KIOBeaconListViewController.h"
#import "KIOAPIDataStore.h"
#import "KIOServiceController.h"
#import "KIOBeacon.h"

typedef NS_ENUM(NSUInteger, TableViewDataStyle){
    TableViewDataStyleServer,
    TableViewDataStyleBeacon
};

@interface KIOBeaconListViewController ()

@property (nonatomic, weak) IBOutlet UIBarButtonItem *dataStyleButton;
@property (nonatomic, assign) TableViewDataStyle tableViewDataStyle;
@property (nonatomic, strong) NSArray *beacons;

@end


@implementation KIOBeaconListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupServices];
    [self setupAPIData];
    
    self.tableViewDataStyle = TableViewDataStyleBeacon;
    
    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self
                            action:@selector(reloadPullToRefresh)
                  forControlEvents:UIControlEventValueChanged];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(blutoothState:) name:kKIOServiceBluetoothONNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(blutoothState:) name:kKIOServiceBluetoothOFFNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(blutoothState:) name:kKIOServiceExitBeaconRegionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(blutoothState:) name:kKIOServiceEnterBeaconRegionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(errorNotification:) name:kKIOServiceLocationErrorNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(beaconsCome:) name:kKIOServiceBeaconsInRegionNotification object:nil];
}


#pragma mark - Setup data

- (void)setupServices
{
    [[KIOAPIDataStore dataStore] loadUUIDSuccessBlock:^(NSArray *uuids) {
        
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:[uuids firstObject]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [KIOServiceController startMonitoringBeaconWithUUID:uuid];
            KIOLog(@"%@", uuids);
        });
        
    }
                                           errorBlock:^(NSError *error) {
                                               
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Attantion code: %i", (int)error.code]
                                        message:error.userInfo[KIO_API_ERROR_DESCRIPTION_KEY]
                                       delegate:nil
                              cancelButtonTitle:@"ok"
                              otherButtonTitles:nil] show];
        });
    }];
}

- (void)setupAPIData
{
    [[KIOAPIDataStore dataStore] loadBeaconSuccessBlock:^(NSArray *beacons) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            for (KIOBeacon *beacon in beacons) {
                KIOLog(@"%@", beacon);
            }
        });
        
    }
                                             errorBlock:^(NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Attantion code: %i", (int)error.code]
                                        message:error.userInfo[KIO_API_ERROR_DESCRIPTION_KEY]
                                       delegate:nil
                              cancelButtonTitle:@"ok"
                              otherButtonTitles:nil] show];
        });
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - NSNotification

- (void)blutoothState:(NSNotification *)notification
{
    NSString *state = notification.name;
    
    if ([state isEqualToString:kKIOServiceBluetoothONNotification]) {
        self.navigationItem.title = @"BLUTOOTH_ON";
        [self.tableView reloadData];
    }
    else if ([state isEqualToString:kKIOServiceEnterBeaconRegionNotification]) {
        [self.tableView reloadData];
    }
    
    else if ([state isEqualToString:kKIOServiceBluetoothOFFNotification]) {
        self.beacons = nil;
        self.navigationItem.title = @"BLUTOOTH_OFF";
        [self.tableView reloadData];
    }
    else if ([state isEqualToString:kKIOServiceExitBeaconRegionNotification]) {
        self.beacons = nil;
        [self.tableView reloadData];
    }
}

- (void)beaconsCome:(NSNotification *)notification
{
    self.beacons = (NSArray *)notification.userInfo[@"beacons"];
    [self.tableView reloadData];
}

- (void)errorNotification:(NSNotification *)notification
{
    [[[UIAlertView alloc] initWithTitle:@"Location not avalible"
                                message:@"Pleace check location service! Or call support..."
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}


#pragma mark - Action

- (void)reloadPullToRefresh
{
    self.beacons = nil;
    [[KIOAPIDataStore dataStore] deleteDataFile:KIO_API_CASH_DATA_FILE];
    
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
    
    CLBeacon *beacon = self.beacons[indexPath.row];
    
    switch (self.tableViewDataStyle) {
            
        case TableViewDataStyleBeacon: {
            cell = [tableView dequeueReusableCellWithIdentifier:@"CellDataStyleBeacon" forIndexPath:indexPath];
            cell.textLabel.text = [NSString stringWithFormat:@"mi:%@, mj:%@", beacon.minor, beacon.major];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"ac:%2.1f, rs:%2.1f", beacon.accuracy, (float)beacon.rssi];
        }break;
            
        case TableViewDataStyleServer: {
            cell = [tableView dequeueReusableCellWithIdentifier:@"CellDataStyleServer" forIndexPath:indexPath];
            NSDictionary *bdata = [NSDictionary dictionaryWithContentsOfFile:[[KIOAPIDataStore dataStore] pathDataFile:KIO_API_CASH_DATA_FILE]];
            NSString *beaconID = [NSString stringWithFormat:@"%@-%@-%@", [beacon.proximityUUID.UUIDString lowercaseString], beacon.major, beacon.minor];
            cell.textLabel.text = (NSString *)bdata[beaconID][@"description"] ? bdata[beaconID][@"description"] : nil;
            cell.detailTextLabel.text = [self proximityData:beacon];
        }break;
    }
    cell.backgroundColor = [self proximityColor:beacon];
    
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
    NSDictionary *bdata = [NSDictionary dictionaryWithContentsOfFile:[[KIOAPIDataStore dataStore] pathDataFile:KIO_API_CASH_DATA_FILE]];
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


@end
