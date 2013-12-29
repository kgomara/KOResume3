//
//  OCAExtensions.h
//  KOResume
//
//  Created by Kevin O'Mara on 3/13/11.
//  Copyright 2011-2013 O'Mara Consulting Associates. All rights reserved.
//

#import <Foundation/Foundation.h>


// Categories added to UIImage
@interface UIImage (KOExtensions)

+ (UIImage*)imageFromView:(UIView*)view;
+ (UIImage*)imageFromView:(UIView*)view scaledToSize:(CGSize)newSize;
+ (UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize;

@end

// Categories added to UIView
@interface UIView (KOExtensions)

- (void)fadeSubViewIn:(UIView*)subView;
- (void)fadeSubViewOut:(UIView*)subView;

@end


@interface OCAExtensions : NSObject 

+ (void)showAlertWithMessageAndType:(NSString*)theMessage 
                          alertType:(NSString*)theType;
+ (void)showErrorWithMessage:(NSString*)theMessage;
+ (void)showWarningWithMessage:(NSString*)theMessage;
+ (void)dismissKeyboard;

@end

@interface NSIndexPath (KOExtensions)

-(NSString *)stringForCollection;

@end

@interface UIStoryboard (KOExtensions)

+ (UIStoryboard *)main_iPhoneStoryboard;
+ (UIStoryboard *)main_iPadStoryboard;

@end


/*
 These categories are taken from the TextKitDemo code provided by Apple
 and are covered by their license agreement, which follows:
 
 File: UIFont+TextKitDemo.h
 Abstract:
 Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 
 Copyright © 2013 Apple Inc. All rights reserved.
 WWDC 2013 License
 
 NOTE: This Apple Software was supplied by Apple as part of a WWDC 2013
 Session. Please refer to the applicable WWDC 2013 Session for further
 information.
 
 IMPORTANT: This Apple software is supplied to you by Apple Inc.
 ("Apple") in consideration of your agreement to the following terms, and
 your use, installation, modification or redistribution of this Apple
 software constitutes acceptance of these terms. If you do not agree with
 these terms, please do not use, install, modify or redistribute this
 Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a non-exclusive license, under
 Apple's copyrights in this original Apple software (the "Apple
 Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple. Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis. APPLE MAKES
 NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE
 IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 EA1002
 5/3/2013
 */

@interface UIFont (OCAExtensions)

+ (UIFont *)OCAPreferredFontWithTextStyle: (NSString *)aTextStyle
                                    scale: (CGFloat)aScale;

- (NSString *)OCATextStyle;

- (UIFont *)OCAFontWithScale:(CGFloat)fontScale;

@end

@interface UIFontDescriptor (OCAExtensions)

+ (UIFontDescriptor *)OCAPreferredFontDescriptorWithTextStyle: (NSString *)aTextStyle
                                                        scale: (CGFloat)aScale;

- (NSString *)OCATextStyle;

- (UIFontDescriptor *)OCAFontDescriptorWithScale: (CGFloat)aScale;

@end

@interface UITextView (OCAExtensions)

- (NSString *)OCATextStyle;

@end

@interface UILabel (OCAExtensions)

- (NSString *)OCATextStyle;

- (void)sizeToFitFixedWidth: (NSInteger)fixedWidth;

@end

@interface UITextField (OCAExtensions)

- (NSString *)OCATextStyle;

@end


/*
 End of TextKitDemo code from Apple
 */

