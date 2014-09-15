//
//  KIOServiceController.m
//  BeaconConference
//
//  Created by Kirill Osipov on 24.07.14.
//  Copyright (c) 2014 Kirill Osipov. All rights reserved.
//

@import CoreLocation;
@import CoreBluetooth;

#import "KIOServiceController.h"


NSString *const kKIOServiceBluetoothONNotification = @"ru.kirillosipov.kKIOServiceBluetoothONNotification";
NSString *const kKIOServiceBluetoothOFFNotification = @"ru.kirillosipov.kKIOServiceBluetoothOFFNotification";

NSString *const kKIOServiceEnterBeaconRegionNotification = @"ru.kirillosipov.kKIOServiceEnterBeaconRegionNotification";
NSString *const kKIOServiceExitBeaconRegionNotification = @"ru.kirillosipov.kKIOServiceExitBeaconRegionNotification";
NSString *const kKIOServiceBeaconsInRegionNotification = @"ru.kirillosipov.kKIOServiceBeaconsInRegionNotification";

NSString *const kKIOServiceLocationErrorNotification = @"ru.kirillosipov.kKIOServiceLocationErrorNotification";


@interface KIOServiceController ()  <CBPeripheralManagerDelegate, CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) CLBeaconRegion *beaconRegion;
@end


@implementation KIOServiceController

+ (instancetype)startMonitoringBeaconWithUUID:(NSUUID *)uuid;
{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sharedInstance = [[self alloc] initWithUUID:uuid];
        
    });
    return sharedInstance;
}


#pragma mark - Privat

- (instancetype)initWithUUID:(NSUUID *)uuid
{
    self = [super init];
    if (self) {
        
        // Bluetooth
        self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
        
        // Location
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        
        // Beacon Region
        NSString *identifier = [NSString stringWithFormat:@"ru.beaconconference.%@", [uuid UUIDString]];
        self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:identifier];
        self.beaconRegion.notifyEntryStateOnDisplay = YES;
        self.beaconRegion.notifyOnEntry = YES;
        self.beaconRegion.notifyOnExit = YES;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.peripheralManager.state == CBPeripheralManagerStatePoweredOn) {
                [self.locationManager startMonitoringForRegion:self.beaconRegion];
            }
        });
    }
    
    return self;
}


#pragma mark - Notification

- (void)postNotificationName:(NSString *)name userInfo:(NSDictionary *)userInfo
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:name
                          object:nil
                        userInfo:userInfo];
}


// TODO: transfer Local Notification to another class

- (void)postLocalNotificationInsideBeaconRegion:(CLBeaconRegion *)beaconRegion
{
    UIApplication *application = [UIApplication sharedApplication];
    NSArray *localNotifications = [application scheduledLocalNotifications];
    
    for (UILocalNotification *localNotification in localNotifications) {
        if ([localNotification.userInfo[@"proximityUUID"] isEqualToString:[beaconRegion.proximityUUID UUIDString]] &&
            [localNotification.userInfo[@"minor"] isEqualToNumber:beaconRegion.minor] &&
            [localNotification.userInfo[@"major"] isEqualToNumber:beaconRegion.major]) {
            [application cancelLocalNotification:localNotification];
        }
    }
    
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = [NSString stringWithFormat:@"mi: %@, mj: %@", beaconRegion.minor, beaconRegion.major];
    notification.hasAction = NO;
    notification.soundName = UILocalNotificationDefaultSoundName;
    notification.timeZone = [NSTimeZone defaultTimeZone];
    notification.userInfo = @{@"proximityUUID": [beaconRegion.proximityUUID UUIDString],
                              @"minor": beaconRegion.minor,
                              @"major": beaconRegion.major};
    [application presentLocalNotificationNow:notification];
}


#pragma mark - CBPeripheralManagerDelegate

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    if (peripheral.state == CBPeripheralManagerStatePoweredOn) {

        [self postNotificationName:kKIOServiceBluetoothONNotification userInfo:nil];
        [self.locationManager startMonitoringForRegion:self.beaconRegion];

    } else {

        [self postNotificationName:kKIOServiceBluetoothOFFNotification userInfo:nil];
        [self.locationManager stopMonitoringForRegion:self.beaconRegion];
    }
}


#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        CLBeaconRegion *beaconRegion = (CLBeaconRegion *)region;
        if ([beaconRegion.proximityUUID isEqual:self.beaconRegion.proximityUUID]) {
            
            [self.locationManager startRangingBeaconsInRegion:beaconRegion];
            [self postNotificationName:kKIOServiceEnterBeaconRegionNotification
                              userInfo:nil];
            
            [self postLocalNotificationInsideBeaconRegion:beaconRegion];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        CLBeaconRegion *beaconRegion = (CLBeaconRegion *)region;
        if ([beaconRegion.proximityUUID isEqual:self.beaconRegion.proximityUUID]) {

        [self.locationManager stopRangingBeaconsInRegion:beaconRegion];
        [self postNotificationName:kKIOServiceExitBeaconRegionNotification
                          userInfo:nil];
            
        }
    }
}


- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    if (beacons.count > 0) {
        if ([region.proximityUUID isEqual:self.beaconRegion.proximityUUID]) {

            [self postNotificationName:kKIOServiceBeaconsInRegionNotification
                              userInfo:@{@"beacons": beacons}];
            
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        CLBeaconRegion *beaconRegion = (CLBeaconRegion *)region;

        switch (state) {
            case CLRegionStateInside: {
                [self.locationManager startRangingBeaconsInRegion:beaconRegion];
            }break;
                
            default: {
                [self.locationManager stopRangingBeaconsInRegion:beaconRegion];
            }break;
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    [self postNotificationName:kKIOServiceLocationErrorNotification
                      userInfo:@{@"error": error}];
}

@end
