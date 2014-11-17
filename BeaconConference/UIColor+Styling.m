//
//  UIColor+Styling.m
//  BeaconConference
//
//  Created by Kirill Osipov on 20.09.14.
//  Copyright (c) 2014 Kirill Osipov. All rights reserved.
//

@import CoreLocation;
#import "UIColor+Styling.h"

@implementation UIColor (Styling)

+ (UIColor *)randomColor
{
    CGFloat r = (float)(arc4random() % 256) / 255.f;
    CGFloat g = (float)(arc4random() % 256) / 255.f;
    CGFloat b = (float)(arc4random() % 256) / 255.f;
    
    return [UIColor colorWithRed:r green:g blue:b alpha:1.f];
}

+ (UIColor *)proximityBeaconColor:(CLBeacon *)beacon withAlphaComponent:(CGFloat)alpha
{
    switch (beacon.proximity) {
        case CLProximityUnknown:    return [[UIColor lightGrayColor] colorWithAlphaComponent:alpha];
            break;
        case CLProximityImmediate:  return [[UIColor redColor] colorWithAlphaComponent:alpha];
            break;
        case CLProximityNear:       return [[UIColor greenColor] colorWithAlphaComponent:alpha];
            break;
        case CLProximityFar:        return [[UIColor yellowColor] colorWithAlphaComponent:alpha];
            break;
            
        default:                    return [UIColor clearColor];
            break;
    }
}


@end
