//
//  KIOGeonamesAPI.h
//  Osipov_K_A_LW8
//
//  Created by Kirill Osipov on 07.07.14.
//  Copyright (c) 2014 Kirill Osipov. All rights reserved.
//

@class CLBeacon;

extern NSString *const kKIOAPICashUUID;
extern NSString *const kKIOAPICashData;

@interface KIOShchigelskyAPI : NSObject

+ (instancetype)sharedInstance;

- (void)loadBeaconInfo:(CLBeacon *)beacon updateCash:(BOOL)isUpdate mainQueue:(void(^)(NSDictionary *dataFromAPI, BOOL isDone))block;
- (void)loadBeaconListWithUpdateCash:(BOOL)isUpdate mainQueue:(void(^)(BOOL isDone))block;

- (BOOL)cashExists:(NSString *)fileName;
- (NSString *)pathDataFile:(NSString *)fileName;
- (void)deleteDataFile:(NSString *)fileName;

@end
