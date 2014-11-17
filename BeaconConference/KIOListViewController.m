//
//  KIOBeaconListViewController.m
//  BeaconConference
//
//  Created by Kirill Osipov on 15.07.14.
//  Copyright (c) 2014 Kirill Osipov. All rights reserved.
//

#import "UIColor+Styling.h"

#import "KIOListViewController.h"
#import "KIOAPIDataStore.h"
#import "KIOServiceController.h"
#import "KIOAPIConnection.h"
#import "KIOBeacon.h"


@interface KIOListViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) UIImageView *bluetoothStateImageView;
@property (strong, nonatomic) NSArray *beacons;

@end


@implementation KIOListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    /*
    int iOSVersion = [[[UIDevice currentDevice].systemVersion substringToIndex:1] intValue];
    if (iOSVersion < 8) {
        CGRect statusBarRect = [UIApplication sharedApplication].statusBarFrame;
        CGRect navBarRect = self.navigationController ? self.navigationController.navigationBar.frame : CGRectZero;
        CGRect tabBarRect = self.tabBarController ? self.tabBarController.tabBar.frame : CGRectZero;
        
        self.tableView.contentInset = UIEdgeInsetsMake(CGRectGetHeight(statusBarRect) +
                                                       CGRectGetHeight(navBarRect), 0,
                                                       CGRectGetHeight(tabBarRect), 0);
    }
    */
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(actionRefresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];
    
    self.bluetoothStateImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
    self.bluetoothStateImageView.center = self.navigationController.navigationItem.titleView.center;
    self.navigationItem.titleView = self.bluetoothStateImageView;
    
    [self setupAPIData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(notificationBlutoothState:) name:kKIOServiceBluetoothONNotification object:nil];
    [nc addObserver:self selector:@selector(notificationBlutoothState:) name:kKIOServiceBluetoothOFFNotification object:nil];
    [nc addObserver:self selector:@selector(notificationError:) name:kKIOServiceLocationErrorNotification object:nil];
    [nc addObserver:self selector:@selector(notificationBeacons:) name:kKIOServiceBeaconsInRegionNotification object:nil];
}

- (void)setupAPIData
{
    [[KIOAPIDataStore dataStore] loadBeaconSuccessBlock:^(NSArray *beacons) {
        
        for (KIOBeacon *beacon in beacons) {
            KIOLog(@"%@ - %@", [beacon.proximityUUID UUIDString], beacon);
        }
        
        NSUUID *testUUID_1 = [[NSUUID alloc] initWithUUIDString:@"ebefd083-70a2-47c8-9837-e7b5634df524"];
//        NSUUID *testUUID_2 = [[NSUUID alloc] initWithUUIDString:@"f7826da6-4fa2-4e98-8024-bc5b71e0893e"];
        
        [KIOServiceController startMonitoringBeaconWithUUID:testUUID_1]; //[(KIOBeacon *)[beacons lastObject] proximityUUID]];
        
    }
                                             errorBlock:^(NSError *error) {
        
            [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Attantion code: %i", (int)error.code]
                                        message:error.userInfo[KIO_API_ERROR_DESCRIPTION_KEY]
                                       delegate:nil
                              cancelButtonTitle:@"ok"
                              otherButtonTitles:nil] show];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - NSNotification

- (void)notificationBlutoothState:(NSNotification *)notification
{
    NSString *state = notification.name;
    UIImage *image = [[UIImage imageNamed:@"nav_bluetooth"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
    if ([state isEqualToString:kKIOServiceBluetoothONNotification]) {
        self.bluetoothStateImageView.image = image;
        self.bluetoothStateImageView.tintColor = [UIColor blueColor];
    }
    
    else if ([state isEqualToString:kKIOServiceBluetoothOFFNotification]) {
        self.bluetoothStateImageView.image = image;
        self.bluetoothStateImageView.tintColor = [UIColor redColor];
        self.beacons = @[];
    }
    
    [self.tableView reloadData];
}

- (void)notificationBeacons:(NSNotification *)notification
{
    self.beacons = (NSArray *)notification.userInfo[@"beacons"];
    [self.tableView reloadData];
}

- (void)notificationError:(NSNotification *)notification
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

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BeaconCell" forIndexPath:indexPath];
    cell.textLabel.text = [NSString stringWithFormat:@"mi:%@, mj:%@", beacon.minor, beacon.major];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"ac:%2.1f, rs:%2.1f", beacon.accuracy, (float)beacon.rssi];
    cell.backgroundColor = [UIColor proximityBeaconColor:beacon withAlphaComponent:.6f];
    
    return cell;
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return tableView.rowHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CGRect frame = CGRectMake(0, 0, CGRectGetWidth(tableView.frame), tableView.rowHeight);
    UIView *view = [[UIView alloc] initWithFrame:frame];
    view.backgroundColor = [UIColor clearColor];
    return view;
}

@end
