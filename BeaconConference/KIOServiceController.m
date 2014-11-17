//
//  KIOServiceController.m
//  BeaconConference
//
//  Created by Kirill Osipov on 24.07.14.
//  Copyright (c) 2014 Kirill Osipov. All rights reserved.
//

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
typedef NS_ENUM(NSUInteger, KIOLocalNotificationType){
    KIOLocalNotificationTypePost = 0,
    KIOLocalNotificationTypeDelete
};
    
- (void)localNotificationType:(KIOLocalNotificationType)localNotificationType
                 beaconRegion:(CLBeaconRegion *)beaconRegion
{
    UIApplication *application = [UIApplication sharedApplication];
    [application cancelAllLocalNotifications];
    
    if (localNotificationType == KIOLocalNotificationTypePost) {
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.alertBody = [NSString stringWithFormat:@"%@", [beaconRegion.proximityUUID UUIDString]];
        notification.soundName = UILocalNotificationDefaultSoundName;
        notification.userInfo = @{@"proximityUUID": [beaconRegion.proximityUUID UUIDString]};
        [application presentLocalNotificationNow:notification];
    }
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
        [self localNotificationType:KIOLocalNotificationTypeDelete beaconRegion:self.beaconRegion];
    }
}


#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        CLBeaconRegion *beaconRegion = (CLBeaconRegion *)region;
        if ([beaconRegion.proximityUUID isEqual:self.beaconRegion.proximityUUID]) {
            
            [self.locationManager startRangingBeaconsInRegion:beaconRegion];
            
            [self postNotificationName:kKIOServiceEnterBeaconRegionNotification userInfo:nil];
            [self localNotificationType:KIOLocalNotificationTypePost beaconRegion:beaconRegion];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        CLBeaconRegion *beaconRegion = (CLBeaconRegion *)region;
        if ([beaconRegion.proximityUUID isEqual:self.beaconRegion.proximityUUID]) {
            
            [self.locationManager stopRangingBeaconsInRegion:beaconRegion];
            
            [self postNotificationName:kKIOServiceExitBeaconRegionNotification userInfo:nil];
            [self localNotificationType:KIOLocalNotificationTypeDelete beaconRegion:beaconRegion];
        }
    }
}

// didRangeBeacons: is called once per second per beacon, and does not track changes in proximity!
- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    if (beacons.count > 0 && self.peripheralManager.state == CBPeripheralManagerStatePoweredOn) {
        if ([region.proximityUUID isEqual:self.beaconRegion.proximityUUID]) {

            [self postNotificationName:kKIOServiceBeaconsInRegionNotification userInfo:@{@"beacons": beacons}];
            
        }
    }
}

// didDetermineState: in background mode notification
- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        CLBeaconRegion *beaconRegion = (CLBeaconRegion *)region;

        if (state == CLRegionStateInside) {
            [self.locationManager startRangingBeaconsInRegion:beaconRegion];
        } else {
            [self.locationManager stopRangingBeaconsInRegion:beaconRegion];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    [self postNotificationName:kKIOServiceLocationErrorNotification userInfo:@{@"error": error}];
}

@end
