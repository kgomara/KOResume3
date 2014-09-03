//
//  OCRPackagesCell.m
//  KOResume2
//
//  Created by Kevin O'Mara on 7/19/13.
//  Copyright (c) 2013-2014 O'Mara Consulting Associates. All rights reserved.
//

#import "OCRPackagesCell.h"

@implementation OCRPackagesCell

CGFloat const kOCRPackagesCellWidth         = 150.0f;
CGFloat const kOCRPackagesCellHeight        = 135.0f;
CGFloat const kOCRPackagesCellWidthPadding  =  20.0f;

//----------------------------------------------------------------------------------------------------------
/**
 Prepares the receiver for service after it has been loaded from an Interface Builder archive, or nib file.
 
 The nib-loading infrastructure sends an awakeFromNib message to each object recreated from a nib archive, 
 but only after all the objects in the archive have been loaded and initialized. When an object receives an 
 awakeFromNib message, it is guaranteed to have all its outlet and action connections already established.
 You must call the super implementation of awakeFromNib to give parent classes the opportunity to perform any 
 additional initialization they require. Although the default implementation of this method does nothing, 
 many UIKit classes provide non-empty implementations. You may call the super implementation at any point 
 during your own awakeFromNib method.
 
 Note - During Interface Builder’s test mode, this message is also sent to objects instantiated from loaded 
 Interface Builder plug-ins. Because plug-ins link against the framework containing the object definition code, 
 Interface Builder is able to call their awakeFromNib method when present. The same is not true for custom 
 objects that you create for your Xcode projects. Interface Builder knows only about the defined outlets and 
 actions of those objects; it does not have access to the actual code for them.
 
 During the instantiation process, each object in the archive is unarchived and then initialized with the method 
 befitting its type. Objects that conform to the NSCoding protocol (including all subclasses of UIView and 
 UIViewController) are initialized using their initWithCoder: method. All objects that do not conform to the 
 NSCoding protocol are initialized using their init method. After all objects have been instantiated and 
 initialized, the nib-loading code reestablishes the outlet and action connections for all of those objects. 
 It then calls the awakeFromNib method of the objects. For more detailed information about the steps followed 
 during the nib-loading process, see “Nib Files” in Resource Programming Guide.
 
 Important - Because the order in which objects are instantiated from an archive is not guaranteed, your 
 initialization methods should not send messages to other objects in the hierarchy. Messages to other objects 
 can be sent safely from within an awakeFromNib method.
 
 Typically, you implement awakeFromNib for objects that require additional set up that cannot be done at 
 design time. For example, you might use this method to customize the default configuration of any controls 
 to match user preferences or the values in other controls. You might also use it to restore individual controls
 to some previous state of your application.
 */
- (void)awakeFromNib
{
    DLog();
    
    [super awakeFromNib];
    
    /*
     From http://spin.atomicobject.com/2014/03/05/uiscrollview-autolayout-ios/
     
     I feel this is a work-around to a poor implementation of autolayout with scrollview - perhaps Apple
     will come up with a better Storyboard/IB paradigm in a later Beta of Xcode 6.
     
     Bascially, the above post points out that the "content view" (contained in our scrollView) needs to
     be pinned to the scrollView's superview - which cannot be done in IB.
     
     The constant 16 is another work-around, as the UIScrollview really, really wants to have some kind
     of inset.
     */
//    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:self.contentView
//                                                                      attribute:NSLayoutAttributeLeading
//                                                                      relatedBy:NSLayoutRelationEqual
//                                                                         toItem:self.view
//                                                                      attribute:NSLayoutAttributeLeading
//                                                                     multiplier:1.0
//                                                                       constant:0];
//    [self.view addConstraint:leftConstraint];
//    
//    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:self.contentView
//                                                                       attribute:NSLayoutAttributeTrailing
//                                                                       relatedBy:NSLayoutRelationEqual
//                                                                          toItem:self.view
//                                                                       attribute:NSLayoutAttributeTrailing
//                                                                      multiplier:1.0
//                                                                        constant:0];
//    [self.view addConstraint:rightConstraint];

    
    // Register for notifications that the user changed text size preference for dynamic type
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(preferredContentSizeChanged:)
                                                 name: UIContentSizeCategoryDidChangeNotification
                                               object: nil];

    // ...and retrieve the current settings to set the actual font size of the UI elements in the cell
    [self calculateAndSetFonts];
}


//----------------------------------------------------------------------------------------------------------
/**
 Deallocates the memory occupied by the receiver.
 
 Subsequent messages to the receiver may generate an error indicating that a message was sent to a deallocated 
 object (provided the deallocated memory hasn’t been reused yet).
 
 You override this method to dispose of resources other than the object’s instance variables, for example:
 
    - (void)dealloc {
        free(myBigBlockOfMemory);
    }
 
 In an implementation of dealloc, do not invoke the superclass’s implementation. You should try to avoid managing 
 the lifetime of limited resources such as file descriptors using dealloc.
 
 You never send a dealloc message directly. Instead, an object’s dealloc method is invoked by the runtime. See
 Advanced Memory Management Programming Guide for more details.
 
 When not using ARC, your implementation of dealloc must invoke the superclass’s implementation as its last 
 instruction.
 */
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


//----------------------------------------------------------------------------------------------------------
/**
 Called to change the cell's highlighted property.
 
 In our cell prototype we created a view inset of a few pixels and set its background to white.
 Our highlight visual effect is acheived by changing the background color of the cell, which is
 occluded by our inset view, leaving a border of the background color.
 
 @param highlighted YES to show the cell in its highlighted state, NO to show it "normal"
 */
//- (void)setHighlighted: (BOOL)highlighted
//{
//    DLog(@"highlighted=%@", highlighted ? @"YES" : @"NO");
//    
//    // Set the highlighted property on the cell
//    [super setHighlighted: highlighted];
//    
//
//    // Update the UI to manifest the highlight effect
//    [self setBackgroundColor: highlighted ? [UIColor redColor] : [UIColor darkGrayColor]];
//}


//----------------------------------------------------------------------------------------------------------
/**
 Update the UI when the user changes their preference of text size.
 
 @param aNotification the notifcation object.
 */
- (void)preferredContentSizeChanged: (NSNotification *)aNotification
{
    DLog();
    
    // The user changed their preference for dynamic type size. Update the font size of the UI elements in the cell
    [self calculateAndSetFonts];
}

//----------------------------------------------------------------------------------------------------------
/**
 Set the Dynamic Text style currently in effect on the cell's UI elements.
 */
- (void) calculateAndSetFonts
{
    DLog();
    
    static const CGFloat cellTitleTextScaleFactor = 1.0f;
    static const CGFloat cellBodyTextScaleFactor  = 1.0f;
    
    NSString *cellTitleTextStyle    = [self.title OCATextStyle];
    UIFont *cellTitleFont           = [UIFont OCAPreferredFontWithTextStyle: cellTitleTextStyle
                                                                      scale: cellTitleTextScaleFactor];
    
    NSString *cellBodyTextStyle = [self.coverLtrButton.titleLabel OCATextStyle];
    UIFont *cellBodyFont        = [UIFont OCAPreferredFontWithTextStyle: cellBodyTextStyle
                                                                  scale: cellBodyTextScaleFactor];
    
    self.title.font                     = cellTitleFont;
    self.coverLtrButton.titleLabel.font = cellBodyFont;
    self.resumeButton.titleLabel.font   = cellBodyFont;
        
    [self invalidateIntrinsicContentSize];
}

//----------------------------------------------------------------------------------------------------------
/**
 Getter method for the titleFont.
 
 @return the UIFontTextStyle of the title.
 */
+ (NSString *)titleFont
{
    return UIFontTextStyleHeadline;
}

//----------------------------------------------------------------------------------------------------------
/**
 Getter method for the detailFont.
 
 @return the UIFontTextStyle of the title.
 */
+ (NSString *)detailFont
{
    return UIFontTextStyleBody;
}

@end
