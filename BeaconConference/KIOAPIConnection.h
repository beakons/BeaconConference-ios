//
//  KIOAPIConnection.h
//  BeaconConference
//
//  Created by Kirill Osipov on 21.07.14.
//  Copyright (c) 2014 Kirill Osipov. All rights reserved.
//

extern NSString *const kKIO_API_HOST;
extern NSString *const kKIO_API_ERROR_KEY;

typedef void (^RequestAPIData)(NSDictionary *dataFromAPI, BOOL success);


@interface KIOAPIConnection : NSObject

+ (instancetype)loadDataFrom:(NSURL *)dataURL mainQueue:(RequestAPIData)block;

@end
