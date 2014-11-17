//
//  UIColor+Styling.h
//  BeaconConference
//
//  Created by Kirill Osipov on 20.09.14.
//  Copyright (c) 2014 Kirill Osipov. All rights reserved.
//

@class CLBeacon;

#import <UIKit/UIKit.h>

@interface UIColor (Styling)

+ (UIColor *)randomColor;
+ (UIColor *)proximityBeaconColor:(CLBeacon *)beacon withAlphaComponent:(CGFloat)alpha;

@end
