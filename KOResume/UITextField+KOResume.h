//
//  UITextField+KOResume.h
//  KOResume
//
//  Created by Kevin O'Mara on 9/5/14.
//  Copyright (c) 2014 O'Mara Consulting Associates. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Category extensions for UITextField.
 */
@interface UITextField (KOResume)

//----------------------------------------------------------------------------------------------------------
/**
 Set a UITextField with text or placeholder.
 
 @param text            The text candidate.
 @param placeholder     The placeholder to use if candidate text is empty.
 */
- (void)setText: (NSString *)text
  orPlaceHolder: (NSString *)placeholder;

@end
