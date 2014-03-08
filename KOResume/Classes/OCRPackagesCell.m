//
//  OCRPackagesCell.m
//  KOResume2
//
//  Created by Kevin O'Mara on 7/19/13.
//  Copyright (c) 2013-2014 O'Mara Consulting Associates. All rights reserved.
//

#import "OCRPackagesCell.h"

@implementation OCRPackagesCell

CGFloat const kOCRPackagesCellHeight        = 132.0f;
CGFloat const kOCRPackagesCellWidthPadding  =  20.0f;

//----------------------------------------------------------------------------------------------------------
- (void)awakeFromNib
{
    DLog();
    
    [super awakeFromNib];
    
    // Register for notifications that the user changed text size preference for dynamic type
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(preferredContentSizeChanged:)
                                                 name: UIContentSizeCategoryDidChangeNotification
                                               object: nil];

    // ...and retrieve the current settings to set the actual font size of the UI elements in the cell
    [self calculateAndSetFonts];
}

//----------------------------------------------------------------------------------------------------------
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
- (void)setHighlighted: (BOOL)highlighted
{
    DLog(@"highlighted=%@", highlighted ? @"YES" : @"NO");
    
    // Set the highlighted property on the cell
    [super setHighlighted: highlighted];
    

    // Update the UI to manifest the highlight effect
    if (highlighted) {
        [self setBackgroundColor:[UIColor redColor]];
    } else {
        [self setBackgroundColor:[UIColor darkGrayColor]];
    }
}


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
        
#warning TODO - need to change the contentSize/tableCellHeight?
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
+ (NSString *)detailFont
/**
 Getter method for the detailFont.
 
 @return the UIFontTextStyle of the title.
 */
{
    return UIFontTextStyleBody;
}

@end
