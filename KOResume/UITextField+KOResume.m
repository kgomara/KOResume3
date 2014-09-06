//
//  UITextField+KOResume.m
//  KOResume
//
//  Created by Kevin O'Mara on 9/5/14.
//  Copyright (c) 2014 O'Mara Consulting Associates. All rights reserved.
//

#import "UITextField+KOResume.h"

@implementation UITextField (KOResume)

//----------------------------------------------------------------------------------------------------------
- (void)setText: (NSString *)text
  orPlaceHolder: (NSString *)placeholder
{
    DLog();
    
    // Check if the text candidate is null or "empty"
    if ([text length] > 0) {
        // There is something in the text candidate - use it
        self.text          =  text;
    } else {
        // Nothing in text, set the textField.text to an empty string
        self.text          = @"";
        // ...and use the placeholder instead
        self.placeholder   = placeholder;
    }
}

@end
