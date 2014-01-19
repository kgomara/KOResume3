//
//  OCRPackagesCell.m
//  KOResume2
//
//  Created by Kevin O'Mara on 7/19/13.
//  Copyright (c) 2013 O'Mara Consulting Associates. All rights reserved.
//

#import "OCRPackagesCell.h"


@implementation OCRPackagesCell

CGFloat const kPackagesCellHeight   = 150.0f;
CGFloat const kPackagesCellWidth    = 150.0f;

//----------------------------------------------------------------------------------------------------------
- (void)awakeFromNib
{
    DLog();
    
    [super awakeFromNib];
    
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(preferredContentSizeChanged:)
                                                 name: UIContentSizeCategoryDidChangeNotification
                                               object: nil];
    
    [self calculateAndSetFonts];
}

//----------------------------------------------------------------------------------------------------------
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

//----------------------------------------------------------------------------------------------------------
- (void)setHighlighted: (BOOL)highlighted
{
    DLog(@"highlighted=%@", highlighted ? @"YES" : @"NO");
    
    // Set the highlighted property on the cell
    [super setHighlighted: highlighted];
    
    /*
     In our cell prototype we created a view inset a few pixels and set its background to white.
     Our highlight visual effect is acheived by changing the background color of the cell, which is
     occluded by our inset view, leaving a border of the background color.
     */
    if (highlighted) {
        [self setBackgroundColor:[UIColor redColor]];
    } else {
        [self setBackgroundColor:[UIColor darkGrayColor]];
    }
}


//----------------------------------------------------------------------------------------------------------
- (void)preferredContentSizeChanged: (NSNotification *)aNotification
{
    [self calculateAndSetFonts];
}

//----------------------------------------------------------------------------------------------------------
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
        
    // TODO - need to change the contentSize/tableCellHeight?
    [self invalidateIntrinsicContentSize];
}

@end
