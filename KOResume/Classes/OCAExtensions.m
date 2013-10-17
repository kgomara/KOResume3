//
//  OCAExtensions.m
//  KOResume
//
//  Created by Kevin O'Mara on 3/13/11.
//  Copyright 2011-2013 O'Mara Consulting Associates. All rights reserved.
//

#import "OCAExtensions.h"
#import <QuartzCore/QuartzCore.h>

@interface OCAExtensions ()

+ (void)globalResignFirstResponder; 
+ (void)globalResignFirstResponderRec:(UIView*)view;

@end


@implementation UIImage (OCAExtensions)
// Categories added to UIImage

//----------------------------------------------------------------------------------------------------------
+ (void)beginImageContextWithSize:(CGSize)size
{
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        if ([[UIScreen mainScreen] scale] == 2.0) {
            UIGraphicsBeginImageContextWithOptions(size, YES, 2.0);
        } else {
            UIGraphicsBeginImageContext(size);
        }
    } else {
        UIGraphicsBeginImageContext(size);
    }
}


//----------------------------------------------------------------------------------------------------------
+ (void)endImageContext
{
    UIGraphicsEndImageContext();
}


//----------------------------------------------------------------------------------------------------------
+ (UIImage*)imageFromView:(UIView*)view
{
    [self beginImageContextWithSize:[view bounds].size];
    BOOL hidden = [view isHidden];
    [view setHidden:NO];
    [[view layer] renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    [self endImageContext];
    [view setHidden:hidden];
    
    return image;
}


//----------------------------------------------------------------------------------------------------------
+ (UIImage*)imageFromView:(UIView*)view
             scaledToSize:(CGSize)newSize
{
    UIImage *image = [self imageFromView:view];
    
    if ([view bounds].size.width  != newSize.width ||
        [view bounds].size.height != newSize.height) {
        image = [self imageWithImage:image scaledToSize:newSize];
    }
    
    return image;
}


//----------------------------------------------------------------------------------------------------------
+ (UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize
{
    [self beginImageContextWithSize:newSize];
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    [self endImageContext];
    return newImage;
}

@end

@implementation OCAExtensions


#pragma mark - Alert methods

/*!
 @method        (void)showAlertWithMessage:(NSString *)theMessage
 @abstract      Display an alert message for the user
 @discussion    OK is the only user option
 */
//----------------------------------------------------------------------------------------------------------
+ (void)showAlertWithMessageAndType:(NSString*)theMessage
                          alertType:(NSString*)theType
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:theType
                                                    message:theMessage
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                          otherButtonTitles:nil];
    [alert show];
}

/**
 @method        (void)showErrorWithMessage:(NSString *)theMessage
 @abstract      Display an alert message for the user indicating Error
 @discussion    OK is the only user option
 */
//----------------------------------------------------------------------------------------------------------
+ (void)showErrorWithMessage:(NSString*)theMessage
{
    [self showAlertWithMessageAndType:theMessage
                            alertType:NSLocalizedString(@"Error", nil)];
}

/**
 @method        (void)showErrorWithMessage:(NSString *)theMessage
 @abstract      Display an alert message for the user indicating Error
 @discussion    OK is the only user option
 */
//----------------------------------------------------------------------------------------------------------
+ (void)showWarningWithMessage:(NSString*)theMessage
{
    [self showAlertWithMessageAndType:theMessage
                            alertType:NSLocalizedString(@"Warning", nil)];
}

#pragma mark - Dismiss keyboard

//----------------------------------------------------------------------------------------------------------
+ (void)dismissKeyboard
{
    [self globalResignFirstResponder];
}


//----------------------------------------------------------------------------------------------------------
+ (void) globalResignFirstResponder
{
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    for (UIView *view in [window subviews]) {
        [self globalResignFirstResponderRec:view];
    }
}


//----------------------------------------------------------------------------------------------------------
+ (void) globalResignFirstResponderRec:(UIView*) view
{
    if ([view respondsToSelector:@selector(resignFirstResponder)]) {
        [view resignFirstResponder];
    }
    
    for (UIView *subview in [view subviews]) {
        [self globalResignFirstResponderRec:subview];
    }
}

@end

#pragma mark - UIView categories

@implementation UIView (OCAExtensions)

//----------------------------------------------------------------------------------------------------------
- (void)fadeSubViewIn:(UIView*)subView
{
    // fade a view into existence
    subView.alpha = 0.;
    [self addSubview:subView];
    [UIView animateWithDuration:3.0 
                     animations:^(void)
     {
         subView.alpha = 1.;
     }];
}


//----------------------------------------------------------------------------------------------------------
- (void)fadeSubViewOut:(UIView*)subView
{
    // fade a view out of existence
    [UIView animateWithDuration:3.0 
                     animations:^(void)
     { 
         subView.alpha = 0.;
     } 
                     completion:^(BOOL complete)     
     {
         [subView removeFromSuperview];
     }];
}


@end

@implementation NSIndexPath (StringForCollection)

//----------------------------------------------------------------------------------------------------------
-(NSString *)stringForCollection
{
    return [NSString stringWithFormat:@"%d-%d",self.section,self.row];
}

@end

@implementation UIStoryboard (KOExtensions)

//----------------------------------------------------------------------------------------------------------
+ (UIStoryboard *)main_iPhoneStoryboard
{
    return [UIStoryboard storyboardWithName: @"Main_iPhone"
                                     bundle: nil];
}

//----------------------------------------------------------------------------------------------------------
+ (UIStoryboard *)main_iPadStoryboard
{
    return [UIStoryboard storyboardWithName: @"Main_iPad"
                                     bundle: nil];
}

@end


@implementation UIFont (OCAExtensions)

//----------------------------------------------------------------------------------------------------------
+ (UIFont *)OCAPreferredFontWithTextStyle: (NSString *)aTextStyle
                                    scale: (CGFloat)aScale
{
    UIFontDescriptor *newFontDescriptor = [UIFontDescriptor OCAPreferredFontDescriptorWithTextStyle: aTextStyle
                                                                                              scale: aScale];
    
    return [UIFont fontWithDescriptor: newFontDescriptor
                                 size: newFontDescriptor.pointSize];
}

//----------------------------------------------------------------------------------------------------------
- (NSString *)OCATextStyle
{
    return [self.fontDescriptor OCATextStyle];
}

//----------------------------------------------------------------------------------------------------------
- (UIFont *)OCAFontWithScale: (CGFloat)aScale
{
    return [self fontWithSize: lrint(self.pointSize * aScale)];
}

@end

@implementation UIFontDescriptor (OCAExtensions)

//----------------------------------------------------------------------------------------------------------
+ (UIFontDescriptor *)OCAPreferredFontDescriptorWithTextStyle: (NSString *)aTextStyle
                                                        scale: (CGFloat)aScale
{
    UIFontDescriptor *newBaseDescriptor = [self preferredFontDescriptorWithTextStyle: aTextStyle];
    
    return [newBaseDescriptor fontDescriptorWithSize: lrint([newBaseDescriptor pointSize] * aScale)];
}

//----------------------------------------------------------------------------------------------------------
- (NSString *)OCATextStyle
{
    return [self objectForKey: @"NSCTFontUIUsageAttribute"];
}

//----------------------------------------------------------------------------------------------------------
- (UIFontDescriptor *)OCAFontDescriptorWithScale:(CGFloat)aScale
{
    return [self fontDescriptorWithSize: lrint(self.pointSize * aScale)];
}

@end

@implementation UITextView (OCAExtensions)

//----------------------------------------------------------------------------------------------------------
- (NSString *)OCATextStyle
{
    return [self.font OCATextStyle];
}

@end

@implementation UILabel (OCAExtensions)

//----------------------------------------------------------------------------------------------------------
- (NSString *)OCATextStyle
{
    return [self.font OCATextStyle];
}

//----------------------------------------------------------------------------------------------------------
- (void)sizeToFitFixedWidth:(NSInteger)fixedWidth
{
    self.frame          = CGRectMake(self.frame.origin.x, self.frame.origin.y, fixedWidth, 0);
    self.lineBreakMode  = NSLineBreakByWordWrapping;
    self.numberOfLines  = 0;
    [self sizeToFit];
}

@end

@implementation UITextField (OCAExtensions)

//----------------------------------------------------------------------------------------------------------
- (NSString *)OCATextStyle
{
    return [self.font OCATextStyle];
}
@end


