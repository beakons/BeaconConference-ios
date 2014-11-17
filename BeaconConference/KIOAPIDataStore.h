//
//  KIOShchigelskyAPI.h
//  BeaconConference
//
//  Created by Kirill Osipov on 07.07.14.
//  Copyright (c) 2014 Kirill Osipov. All rights reserved.
//

@class KIOBeacon;
@class KIOAPIConnection;
@class CLBeacon;

extern NSString *const KIO_API_CASH_UUID_FILE;
extern NSString *const KIO_API_CASH_DATA_FILE;

@interface KIOAPIDataStore : NSObject

+ (instancetype)dataStore;

- (void)loadBeaconSuccessBlock:(void(^)(NSArray *beacons))successBlock errorBlock:(void(^)(NSError *error))errorBlock;
- (void)loadUUIDSuccessBlock:(void(^)(NSArray *uuids))successBlock errorBlock:(void(^)(NSError *error))errorBlock;

- (BOOL)cashExists:(NSString *)fileName;
- (NSString *)pathDataFile:(NSString *)fileName;
- (void)deleteDataFile:(NSString *)fileName;
- (NSDate *)dateModificationCashFile:(NSString *)fileName;

- (KIOBeacon *)dataBeaconFrom:(NSArray *)beacons forCLBeacon:(CLBeacon *)beacon;

@end
