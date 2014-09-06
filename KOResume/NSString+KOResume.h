//
//  NSString+KOResume.h
//  KOResume
//
//  Created by Kevin O'Mara on 9/5/14.
//  Copyright (c) 2014 O'Mara Consulting Associates. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (KOResume)

//----------------------------------------------------------------------------------------------------------
/**
 Returns the first30 characters of the receiver.
 
 If the given string is 30 characters or less, returns the string. If longer than 30 characters, returns the
 first 27 of the actual string concatenated with '...'.
 
 @return 30 characters (or fewer) representing the string
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *first30;


@end
