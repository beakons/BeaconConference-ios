//
//  KIOServiceController.h
//  BeaconConference
//
//  Created by Kirill Osipov on 24.07.14.
//  Copyright (c) 2014 Kirill Osipov. All rights reserved.
//

extern NSString *const kKIOServiceBluetoothONNotification;
extern NSString *const kKIOServiceBluetoothOFFNotification;
extern NSString *const kKIOServiceEnterBeaconRegionNotification;
extern NSString *const kKIOServiceExitBeaconRegionNotification;
extern NSString *const kKIOServiceBeaconsInRegionNotification;
extern NSString *const kKIOServiceLocationErrorNotification;


@interface KIOServiceController : NSObject

+ (instancetype)startMonitoringBeaconWithUUID:(NSUUID *)uuid;

@end
