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


NSString *const kKIOServiceBluetoothONNotification = @"kKIOServiceBluetoothONNotification";
NSString *const kKIOServiceBluetoothOFFNotification = @"kKIOServiceBluetoothOFFNotification";
NSString *const kKIOServiceEnterBeaconRegionNotification = @"kKIOServiceEnterBeaconRegionNotification";
NSString *const kKIOServiceExitBeaconRegionNotification = @"kKIOServiceExitBeaconRegionNotification";
NSString *const kKIOServiceBeaconsInRegionNotification = @"kKIOServiceBeaconsInRegionNotification";

NSString *const kKIOServiceLocationErrorNotification = @"kKIOServiceLocationErrorNotification";


@interface KIOServiceController ()  <CBPeripheralManagerDelegate, CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;

@property (nonatomic, strong) CLBeaconRegion *beaconRegion;

@end


@implementation KIOServiceController

+ (instancetype)sharedService
{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    
    return sharedInstance;
}


#pragma mark - Privat

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        // Bluetooth
        self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
        
        // Location
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        
    }
    return self;
}

- (void)startMonitoringBeaconsWithUUID:(NSUUID *)uuid
{
    self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:@"ru.beaconconference.beacon"];
    self.beaconRegion.notifyEntryStateOnDisplay = YES;
}

#pragma mark - CBPeripheralManagerDelegate

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    if (peripheral.state == CBPeripheralManagerStatePoweredOn) {

        [[NSNotificationCenter defaultCenter] postNotificationName:kKIOServiceBluetoothONNotification object:nil];
        
        [self.locationManager startMonitoringForRegion:self.beaconRegion];
    } else {

        [[NSNotificationCenter defaultCenter] postNotificationName:kKIOServiceBluetoothOFFNotification object:nil];

        [self.locationManager stopMonitoringForRegion:self.beaconRegion];
        [self.locationManager stopRangingBeaconsInRegion:(CLBeaconRegion *)self.beaconRegion];
    }
}


#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    if([region isKindOfClass:[CLBeaconRegion class]] && [region.identifier isEqualToString:self.beaconRegion.identifier]) {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kKIOServiceEnterBeaconRegionNotification object:nil];

        [self.locationManager startRangingBeaconsInRegion:(CLBeaconRegion*)region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    if([region isKindOfClass:[CLBeaconRegion class]] && [region.identifier isEqualToString:self.beaconRegion.identifier]) {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kKIOServiceExitBeaconRegionNotification object:nil];
        
        [self.locationManager stopMonitoringForRegion:(CLBeaconRegion*)region];
        [self.locationManager stopRangingBeaconsInRegion:(CLBeaconRegion*)region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kKIOServiceBeaconsInRegionNotification object:beacons];
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    if([region isKindOfClass:[CLBeaconRegion class]] && [region.identifier isEqualToString:self.beaconRegion.identifier]) {
        
        switch (state) {
            case CLRegionStateInside:
                [self.locationManager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
                break;
                
            default:
                [self.locationManager stopRangingBeaconsInRegion:(CLBeaconRegion *)region];
                break;
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kKIOServiceLocationErrorNotification object:error];
}

@end
