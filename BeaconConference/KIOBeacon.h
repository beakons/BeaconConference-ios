//
//  KIOBeacon.h
//  BeaconConference
//
//  Created by Kirill Osipov on 21.07.14.
//  Copyright (c) 2014 Kirill Osipov. All rights reserved.
//

/*
 
 http://54.85.60.100:80/places/1/points/

 {
    "x": 0,
    "y": 2,
    "floor_number": 0,
    "description": "Стол Кирилла",
    "object": {
        "id": 1,
        "name": "Стол Кирилла",
        "description": "Стол Кирилла в офисе на крыше",
        "description_near": "БЛИЗКО от стола Кирилла",
        "description_far": "ДАЛЕКО от стола Кирилла",
        "description_immediate": "НА столе Кирилла"
    },
    "beacon": {
        "uuid": "f7826da6-4fa2-4e98-8024-bc5b71e0893e",
        "major": 64955,
        "minor": 17705
    }
 }
 
*/

// TODO: normal parser

extern NSString *const KIO_BEACON_X_KEY;
extern NSString *const KIO_BEACON_Y_KEY;
extern NSString *const KIO_BEACON_Z_KEY;
extern NSString *const KIO_BEACON_DESCRIPTION_KEY;

extern NSString *const KIO_BEACON_KEY;
extern NSString *const KIO_BEACON__UUID_KEY;
extern NSString *const KIO_BEACON__MAJOR_KEY;
extern NSString *const KIO_BEACON__MINOR_KEY;

extern NSString *const KIO_BEACON_OBJECT_KEY;
extern NSString *const KIO_BEACON_OBJECT__ID_KEY;
extern NSString *const KIO_BEACON_OBJECT__NAME_KEY;
extern NSString *const KIO_BEACON_OBJECT__DESCRIPTION_KEY;
extern NSString *const KIO_BEACON_OBJECT__PROXIMITY_NEAR_KEY;
extern NSString *const KIO_BEACON_OBJECT__PROXIMITY_FAR_KEY;
extern NSString *const KIO_BEACON_OBJECT__PROXIMITY_IMMEDIATE_KEY;


typedef struct KIOBeaconPoint {
    int x;
    int y;
    int z;
} KIOBeaconPoint;

static inline KIOBeaconPoint
KIOBeaconPointMake (int x, int y, int z) {
    KIOBeaconPoint point;
    point.x = x;
    point.y = y;
    point.z = z;
    return point;
}

@interface KIOBeacon : NSObject

@property (assign, nonatomic) KIOBeaconPoint point;
@property (strong, nonatomic) NSString *description;

@property (strong, nonatomic) NSUUID *proximityUUID;
@property (strong, nonatomic) NSNumber *major;
@property (strong, nonatomic) NSNumber *minor;

@property (strong, nonatomic) NSString *objectID;
@property (strong, nonatomic) NSString *objectName;
@property (strong, nonatomic) NSString *objectDescription;
@property (strong, nonatomic) NSString *proximityImmediateDescription;
@property (strong, nonatomic) NSString *proximityNearDescription;
@property (strong, nonatomic) NSString *proximityFarDescription;

- (instancetype)initWithProximityUUID:(NSUUID *)proximityUUID
                                major:(NSNumber *)major
                                minor:(NSNumber *)minor;


@end
