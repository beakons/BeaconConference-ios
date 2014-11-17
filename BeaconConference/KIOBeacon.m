//
//  KIOBeacon.m
//  BeaconConference
//
//  Created by Kirill Osipov on 21.07.14.
//  Copyright (c) 2014 Kirill Osipov. All rights reserved.
//

NSString *const KIO_BEACON_X_KEY = @"x";
NSString *const KIO_BEACON_Y_KEY = @"y";
NSString *const KIO_BEACON_Z_KEY = @"floor_number";
NSString *const KIO_BEACON_DESCRIPTION_KEY = @"description";

NSString *const KIO_BEACON_KEY = @"beacon";
NSString *const KIO_BEACON__UUID_KEY = @"uuid";
NSString *const KIO_BEACON__MAJOR_KEY = @"major";
NSString *const KIO_BEACON__MINOR_KEY = @"minor";

NSString *const KIO_BEACON_OBJECT_KEY = @"object";
NSString *const KIO_BEACON_OBJECT__ID_KEY = @"id";
NSString *const KIO_BEACON_OBJECT__NAME_KEY = @"name";
NSString *const KIO_BEACON_OBJECT__DESCRIPTION_KEY = @"description";
NSString *const KIO_BEACON_OBJECT__PROXIMITY_NEAR_KEY = @"description_near";
NSString *const KIO_BEACON_OBJECT__PROXIMITY_FAR_KEY = @"description_far";
NSString *const KIO_BEACON_OBJECT__PROXIMITY_IMMEDIATE_KEY = @"description_immediate";

#import "KIOBeacon.h"

@implementation KIOBeacon

- (instancetype)initWithProximityUUID:(NSUUID *)proximityUUID major:(NSNumber *)major minor:(NSNumber *)minor;
{
    self = [super init];
    if (self) {
        
        self.proximityUUID = proximityUUID;
        self.major = major;
        self.minor = minor;

    }
    return self;
}

- (NSString *)description
{
    return self.beaconDescription;
}

- (NSString *)beaconID
{
    return [NSString stringWithFormat:@"mj%imn%i", [self.major intValue], [self.minor intValue]];
}

@end
