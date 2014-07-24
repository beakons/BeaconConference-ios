//
//  KIOShchigelskyAPI.m
//  BeaconConference
//
//  Created by Kirill Osipov on 07.07.14.
//  Copyright (c) 2014 Kirill Osipov. All rights reserved.
//

#define kKIO_SHOULD_PRINT_FLAG 1

NSString *const kKIO_API_CASH_UUID_FILE = @"uuid_list.plist";
NSString *const kKIO_API_CASH_DATA_FILE = @"uuid_data.plist";

NSString *const kKIO_API_UUIDS_KEY = @"uuids";

@import CoreLocation;
#import "KIOAPIDataStore.h"


@implementation KIOAPIDataStore

+ (instancetype)sharedInstance
{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    
    return sharedInstance;
}


#pragma mark - Publish

/*!
 * @discussion load Beacon UUIDs
 *
 * @param reloadCash BOOL
 *
 */
- (void)loadUUIDReloadCash:(BOOL)update mainQueue:(RequestAPIData)block
{
    NSString *cashFilePath = [self pathDataFile:kKIO_API_CASH_UUID_FILE];
    
    if (update == NO && [[NSFileManager defaultManager] fileExistsAtPath:cashFilePath]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            block([NSDictionary dictionaryWithContentsOfFile:cashFilePath], YES);
        });
        
    } else {

        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/beaconsapp/uuids", kKIO_API_HOST]];
        [KIOAPIConnection loadDataFrom:url mainQueue:^(NSDictionary *dataFromAPI, BOOL success) {
            
            if (success) {
                [dataFromAPI writeToFile:cashFilePath atomically:YES];
            }
            if (block) {
                block(dataFromAPI, success);
            }
        }];
    }
}

/*!
 * @discussion load Beacon 1 by 1
 *
 * @param beacon CLBeacon
 * @param reloadCash BOOL
 *
 */
- (void)loadBeacon:(CLBeacon *)beacon reloadCash:(BOOL)update mainQueue:(RequestAPIData)block
{
    NSString *cashFilePath = [self pathDataFile:kKIO_API_CASH_DATA_FILE];
    
    if (update == NO && [[NSFileManager defaultManager] fileExistsAtPath:cashFilePath]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            block([NSDictionary dictionaryWithContentsOfFile:cashFilePath], YES);
        });
        
    } else {
        
        NSURL *url = [self URLBeacon:beacon];
        [KIOAPIConnection loadDataFrom:url mainQueue:^(NSDictionary *dataFromAPI, BOOL success) {
            
            if (success) {
                NSString *beaconID = [NSString stringWithFormat:@"%@-%@-%@", [beacon.proximityUUID.UUIDString lowercaseString], beacon.major, beacon.minor];
                
                if ([[NSFileManager defaultManager] fileExistsAtPath:cashFilePath]) {
                    NSMutableDictionary *tempDict = [NSDictionary dictionaryWithContentsOfFile:cashFilePath];
                    [tempDict setObject:dataFromAPI forKey:beaconID];
                    [tempDict writeToFile:cashFilePath atomically:YES];
                } else {
                    [@{beaconID : dataFromAPI} writeToFile:cashFilePath atomically:YES];
                }
            }
            if (block) {
                block(dataFromAPI, success);
            }
        }];
    }
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

- (NSString *)pathDataFile:(NSString *)fileName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [[paths firstObject] stringByAppendingPathComponent:fileName];
    return documentsPath;
}


#pragma mark - Privat

- (NSURL *)URLBeacon:(CLBeacon *)beacon
{
    NSString *hostAPI = [NSString stringWithFormat:@"http://%@/beaconsapp", kKIO_API_HOST];
    NSString *stringURL = [NSString stringWithFormat:@"%@/object/%@/%@/%@", hostAPI, [beacon.proximityUUID.UUIDString lowercaseString], beacon.major, beacon.minor];
#if kKIO_SHOULD_PRINT_FLAG
    NSLog(@"B_URL: %@", stringURL);
#endif
    return [NSURL URLWithString:stringURL];
}


@end
