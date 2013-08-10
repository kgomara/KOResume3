//
//  OCRPackagesCell.m
//  KOResume2
//
//  Created by Kevin O'Mara on 7/19/13.
//  Copyright (c) 2013 O'Mara Consulting Associates. All rights reserved.
//

#import "OCRPackagesCell.h"

@implementation OCRPackagesCell

@synthesize delegate        = _delegate;
@synthesize title           = _title;
@synthesize coverLtrButton  = _coverLtrButton;
@synthesize resumeButton    = _resumeButton;

// TODO - it appears initWithStyle:reuseIdentifier: is never called, but prepareForReuse is...
// this seems wrong, and I'm not sure what will happen if a cell gets reused a lot - will it register for and
// get multiple notifications?

//- (id)init
//{
//    if ((self = [super init]) == nil) {
//        return nil;
//    }
//    
//    [self calculateAndSetFonts];
//    
//    return self;
// 
//}
//
////----------------------------------------------------------------------------------------------------------
//- (id)initWithFrame:(CGRect)frame
//{
//    DLog();
//    
//    if ((self = [super initWithFrame:frame]) == nil) {
//        return nil;
//    }
//    
//    [self calculateAndSetFonts];
//    
//    return self;
//}
////----------------------------------------------------------------------------------------------------------
//- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
//{
//    DLog();
//    
//    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
//    if (self) {
//        [[NSNotificationCenter defaultCenter] addObserver: self
//                                                 selector: @selector(preferredContentSizeChanged:)
//                                                     name: UIContentSizeCategoryDidChangeNotification
//                                                   object: nil];
//        // Initialization code
//    }
//    return self;
//
//}

//----------------------------------------------------------------------------------------------------------
- (void)prepareForReuse
{
    DLog();
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(preferredContentSizeChanged:)
                                                 name: UIContentSizeCategoryDidChangeNotification
                                               object: nil];
}

//----------------------------------------------------------------------------------------------------------
- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

//----------------------------------------------------------------------------------------------------------
- (IBAction)coverLtrBtnTapped:(id)sender
{
    DLog();
    
    [_delegate coverLtrButtonTapped:(id)sender];
}

//----------------------------------------------------------------------------------------------------------
- (IBAction)resumeBtnTapped:(id)sender
{
    DLog();
    
    [_delegate resumeButtonTapped:(id)sender];
}

- (void)preferredContentSizeChanged:(NSNotification *)aNotification
{
    [self calculateAndSetFonts];
}

- (void) calculateAndSetFonts
{
    DLog();
    
    static const CGFloat cellTitleTextScaleFactor = 1.0f;
    static const CGFloat cellBodyTextScaleFactor = 1.0f;
    
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
}

@end
