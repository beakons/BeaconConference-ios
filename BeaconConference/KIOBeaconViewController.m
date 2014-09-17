//
//  KIOBeaconListViewController.m
//  BeaconConference
//
//  Created by Kirill Osipov on 15.07.14.
//  Copyright (c) 2014 Kirill Osipov. All rights reserved.
//

@import CoreLocation;

#import "KIOBeaconViewController.h"
#import "KIOAPIDataStore.h"
#import "KIOServiceController.h"
#import "KIOBeacon.h"


@interface KIOBeaconViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) UIImageView *bluetoothStateImageView;
@property (strong, nonatomic) NSArray *beacons;

@end


@implementation KIOBeaconViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(actionRefresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];
    
    self.bluetoothStateImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
    self.bluetoothStateImageView.center = self.view.center;
    [self.view addSubview:self.bluetoothStateImageView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(blutoothStateNotification:) name:kKIOServiceBluetoothONNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(blutoothStateNotification:) name:kKIOServiceBluetoothOFFNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(errorNotification:) name:kKIOServiceLocationErrorNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(beaconNotification:) name:kKIOServiceBeaconsInRegionNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setupAPIData];
}

- (void)setupAPIData
{
    [[KIOAPIDataStore dataStore] loadBeaconSuccessBlock:^(NSArray *beacons) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            for (KIOBeacon *beacon in beacons) {
                KIOLog(@"%@ - %@", [beacon.proximityUUID UUIDString], beacon);
            }
            [KIOServiceController startMonitoringBeaconWithUUID:[(KIOBeacon *)[beacons firstObject] proximityUUID]];
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

- (void)blutoothStateNotification:(NSNotification *)notification
{
    NSString *state = notification.name;
    
    if ([state isEqualToString:kKIOServiceBluetoothONNotification]) {
        UIImage *image = [[UIImage imageNamed:@"ic_bluetooth_on"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.bluetoothStateImageView.alpha = 0.3f;
        self.bluetoothStateImageView.image = image;
        self.bluetoothStateImageView.tintColor = [UIColor blueColor];
    }
    
    else if ([state isEqualToString:kKIOServiceBluetoothOFFNotification]) {
        UIImage *image = [[UIImage imageNamed:@"ic_bluetooth_off"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.bluetoothStateImageView.alpha = 0.3f;
        self.bluetoothStateImageView.image = image;
        self.bluetoothStateImageView.tintColor = [UIColor redColor];
        self.beacons = nil;
    }
    
    [self.tableView reloadData];
}

- (void)beaconNotification:(NSNotification *)notification
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

- (void)actionRefresh:(UIRefreshControl *)refreshControl
{
    [[KIOAPIDataStore dataStore] deleteDataFile:KIO_API_CASH_DATA_FILE];
    
    [self setupAPIData];
    [self.tableView reloadData];

    [refreshControl endRefreshing];
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.beacons.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CLBeacon *beacon = self.beacons[indexPath.row];

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellDataStyleBeacon" forIndexPath:indexPath];
    cell.textLabel.text = [NSString stringWithFormat:@"mi:%@, mj:%@", beacon.minor, beacon.major];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"ac:%2.1f, rs:%2.1f", beacon.accuracy, (float)beacon.rssi];
    cell.backgroundColor = [self proximityColor:beacon];
    
    return cell;
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGRect rect = [UIApplication sharedApplication].statusBarFrame;
    return CGRectGetHeight(rect);
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CGRect rect = [UIApplication sharedApplication].statusBarFrame;
    CGRect frame = CGRectMake(0, 0, CGRectGetWidth(rect), CGRectGetHeight(rect));
    UIView *view = [[UIView alloc] initWithFrame:frame];
    view.backgroundColor = [UIColor clearColor];
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    CGRect rect = [UIApplication sharedApplication].statusBarFrame;
    return CGRectGetHeight(rect)*4;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    CGRect rect = [UIApplication sharedApplication].statusBarFrame;
    CGRect frame = CGRectMake(0, 0, CGRectGetWidth(rect), CGRectGetHeight(rect)*4);
    UIView *view = [[UIView alloc] initWithFrame:frame];
    view.backgroundColor = [UIColor clearColor];
    
    self.bluetoothStateImageView.center = view.center;
    [view addSubview:self.bluetoothStateImageView];
    return view;
}


#pragma mark - Styling

- (UIColor *)proximityColor:(CLBeacon *)beacon
{
    switch (beacon.proximity) {
        case CLProximityUnknown:
            return [UIColor lightGrayColor];
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

@end
