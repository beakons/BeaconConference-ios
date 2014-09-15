//
//  KIOUtils.h
//  BeaconConference
//
//  Created by Kirill Osipov on 14.08.14.
//  Copyright (c) 2014 Kirill Osipov. All rights reserved.
//

//#define KIOLOG_DEDUG 1
#define KIOLOG_DEDUG_NOTIFICATION 0

extern NSString *const kKIOLogNotification;
extern NSString *const kKIOLogNotificationUserInfo;

void KIOLog(NSString *format, ...);