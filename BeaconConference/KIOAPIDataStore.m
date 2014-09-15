//
//  KIOShchigelskyAPI.m
//  BeaconConference
//
//  Created by Kirill Osipov on 07.07.14.
//  Copyright (c) 2014 Kirill Osipov. All rights reserved.
//

NSString *const KIO_API_CASH_UUID_FILE = @"uuid_list.plist";
NSString *const KIO_API_CASH_DATA_FILE = @"uuid_data.plist";
NSString *const kKIO_API_UUIDS_KEY = @"uuids";


#import "KIOAPIDataStore.h"
#import "KIOBeacon.h"


@implementation KIOAPIDataStore

+ (instancetype)dataStore
{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    
    return sharedInstance;
}


#pragma mark - Publish

- (void)loadBeaconSuccessBlock:(void(^)(NSArray *beacons))successBlock
                    errorBlock:(void(^)(NSError *error))errorBlock
{
    if ([self cashExists:KIO_API_CASH_DATA_FILE] &&
        [[self dateModificationCashFile:KIO_API_CASH_DATA_FILE] timeIntervalSinceNow] < 60*60*24) {
        
        NSArray *array = [self parsedBeaconDataFile];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            successBlock(array);
        });
        
    } else {
        
        NSString *urlString = [NSString stringWithFormat:@"http://%@/places/1/points/", KIO_API_HOST];

        [KIOAPIConnection performRequestWithURL:[NSURL URLWithString:urlString]
                             withLastUpdateTime:nil
                                   successBlock:^(NSData *data) {
                                       
                                       NSArray *beacons = [NSJSONSerialization JSONObjectWithData:data
                                                                                          options:NSJSONReadingMutableLeaves
                                                                                            error:nil];
                                       
                                       [beacons writeToFile:[self pathDataFile:KIO_API_CASH_DATA_FILE] atomically:YES];
                                       NSArray *array = [self parsedBeaconDataFile];
                                       
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           successBlock(array);
                                       });
                                       
                                   }
                                     errorBlock:^(NSError *error) {
                                         
                                         dispatch_async(dispatch_get_main_queue(), ^{
                                             errorBlock(error);
                                             KIOLog(@"%error: @\n", error);
                                         });
                                         
                                     }
         ];
    }
}

- (void)loadUUIDSuccessBlock:(void(^)(NSArray *uuids))successBlock
                  errorBlock:(void(^)(NSError *error))errorBlock
{
    if ([self cashExists:KIO_API_CASH_UUID_FILE] &&
        [[self dateModificationCashFile:KIO_API_CASH_UUID_FILE] timeIntervalSinceNow] < 60*60*24) {
        
        NSArray *array = [self parsedUUIDDataFile];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            successBlock(array);
        });
        
    } else {
        
        NSString *urlString = [NSString stringWithFormat:@"http://%@/beaconsapp/uuids", KIO_API_HOST];
        [KIOAPIConnection performRequestWithURL:[NSURL URLWithString:urlString]
                             withLastUpdateTime:nil
                                   successBlock:^(NSData *data) {
                                       
                                       NSDictionary *uuids =
                                       [NSJSONSerialization JSONObjectWithData:data
                                                                       options:NSJSONReadingMutableLeaves
                                                                         error:nil];
                                       [uuids writeToFile:[self pathDataFile:KIO_API_CASH_UUID_FILE] atomically:YES];
                                       NSArray *array = [self parsedUUIDDataFile];
                                       
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           successBlock(array);
                                       });
                                       
                                   }
                                     errorBlock:^(NSError *error) {
                                         
                                         dispatch_async(dispatch_get_main_queue(), ^{
                                             errorBlock(error);
                                             KIOLog(@"%error: @\n", error);
                                         });
                                         
                                     }
         ];
    }
}


#pragma mark - Parser

- (NSArray *)parsedUUIDDataFile
{
    NSDictionary *dataBase = [NSDictionary dictionaryWithContentsOfFile:[self pathDataFile:KIO_API_CASH_UUID_FILE]];
    return dataBase[kKIO_API_UUIDS_KEY];
}


- (NSArray *)parsedBeaconDataFile
{
    NSMutableArray *array = [NSMutableArray array];
    NSArray *dataBase = [NSArray arrayWithContentsOfFile:[self pathDataFile:KIO_API_CASH_DATA_FILE]];
    for (NSDictionary *dict in dataBase) {
        
        NSString *uuid = dict[KIO_BEACON_KEY][KIO_BEACON__UUID_KEY];
        int major = [dict[KIO_BEACON_KEY][KIO_BEACON__MAJOR_KEY] intValue];
        int minor = [dict[KIO_BEACON_KEY][KIO_BEACON__MINOR_KEY] intValue];
        
        KIOBeacon *beacon = [[KIOBeacon alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:uuid]
                                                               major:[NSNumber numberWithInt:major]
                                                               minor:[NSNumber numberWithInt:minor]];
        
        beacon.point = KIOBeaconPointMake([dict[KIO_BEACON_X_KEY] intValue],
                                          [dict[KIO_BEACON_Y_KEY] intValue],
                                          [dict[KIO_BEACON_Z_KEY] intValue]);
        
        beacon.description = dict[KIO_BEACON_DESCRIPTION_KEY];
        
        beacon.objectID = dict[KIO_BEACON_OBJECT_KEY][KIO_BEACON_OBJECT__ID_KEY];
        beacon.objectName = dict[KIO_BEACON_OBJECT_KEY][KIO_BEACON_OBJECT__NAME_KEY];
        beacon.objectDescription = dict[KIO_BEACON_OBJECT_KEY][KIO_BEACON_OBJECT__DESCRIPTION_KEY];
        
        beacon.proximityFarDescription = dict[KIO_BEACON_OBJECT_KEY][KIO_BEACON_OBJECT__PROXIMITY_FAR_KEY];
        beacon.proximityImmediateDescription = dict[KIO_BEACON_OBJECT_KEY][KIO_BEACON_OBJECT__PROXIMITY_IMMEDIATE_KEY];
        beacon.proximityNearDescription = dict[KIO_BEACON_OBJECT_KEY][KIO_BEACON_OBJECT__PROXIMITY_NEAR_KEY];
        
        [array addObject:beacon];
    }
    return array;
}


#pragma mark - Work with cash file

- (NSString *)pathDataFile:(NSString *)fileName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [[paths firstObject] stringByAppendingPathComponent:fileName];
    return documentsPath;
}

- (void)deleteDataFile:(NSString *)fileName
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self pathDataFile:fileName]]) {
        [[NSFileManager defaultManager] removeItemAtPath:[self pathDataFile:fileName] error:nil];
    }
}

- (BOOL)cashExists:(NSString *)fileName
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[self pathDataFile:fileName]];
}

- (NSDate *)dateModificationCashFile:(NSString *)fileName
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDictionary *fileAttributes = [fileManager attributesOfFileSystemForPath:[self pathDataFile:fileName] error:nil];
    
    return [fileAttributes fileModificationDate];
}

@end
