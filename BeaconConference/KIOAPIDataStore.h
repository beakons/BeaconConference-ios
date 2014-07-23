//
//  KIOShchigelskyAPI.h
//  BeaconConference
//
//  Created by Kirill Osipov on 07.07.14.
//  Copyright (c) 2014 Kirill Osipov. All rights reserved.
//

@class CLBeacon;
#import "KIOAPIConnection.h"

extern NSString *const kKIO_API_CASH_UUID_FILE;
extern NSString *const kKIO_API_CASH_DATA_FILE;

extern NSString *const kKIO_API_UUIDS_KEY;

@interface KIOAPIDataStore : NSObject

+ (instancetype)sharedInstance;

- (void)loadBeacon:(CLBeacon *)beacon reloadCash:(BOOL)update mainQueue:(RequestAPIData)block;
- (void)loadUUIDReloadCash:(BOOL)update mainQueue:(RequestAPIData)block;

- (BOOL)cashExists:(NSString *)fileName;
- (NSString *)pathDataFile:(NSString *)fileName;
- (void)deleteDataFile:(NSString *)fileName;

@end
