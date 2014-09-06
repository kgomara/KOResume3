//
//  NSString+KOResume.m
//  KOResume
//
//  Created by Kevin O'Mara on 9/5/14.
//  Copyright (c) 2014 O'Mara Consulting Associates. All rights reserved.
//

#import "NSString+KOResume.h"

@implementation NSString (KOResume)

//----------------------------------------------------------------------------------------------------------
- (NSString *)first30
{
    NSString *first30;
    if ([self length] > 30) {
        first30 = [NSString stringWithFormat:@"%@...", [self substringWithRange: NSMakeRange(0, 27)]];
    } else {
        first30 = self;
    }
    
    return first30;
}

@end
