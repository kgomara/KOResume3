//
//  OCRPackagesCell.m
//  KOResume2
//
//  Created by Kevin O'Mara on 7/19/13.
//  Copyright (c) 2013 O'Mara Consulting Associates. All rights reserved.
//

#import "OCRPackagesCell.h"
#import "OCRReorderableLayoutAttributes.h"

#define MARGIN 2

@implementation OCRPackagesCell

@synthesize delegate        = _delegate;
@synthesize title           = _title;
@synthesize coverLtrButton  = _coverLtrButton;
@synthesize resumeButton    = _resumeButton;
@synthesize deleteButton    = _deleteButton;

static UIImage *deleteButtonImg;

//----------------------------------------------------------------------------------------------------------
- (void)awakeFromNib
{
    DLog();
    
    [super awakeFromNib];
    
    self.backgroundColor = [UIColor darkGrayColor];
    
    self.layer.cornerRadius = 5.0f;
    self.viewForBaselineLayout.layer.cornerRadius = 2.0f;
    
    self.deleteButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
    if (!deleteButtonImg)
    {
        CGRect buttonFrame  = self.deleteButton.frame;
        UIGraphicsBeginImageContext(buttonFrame.size);
        CGFloat sz          = MIN(buttonFrame.size.width, buttonFrame.size.height);
        UIBezierPath *path  = [UIBezierPath bezierPathWithArcCenter: CGPointMake(buttonFrame.size.width/2, buttonFrame.size.height/2)
                                                             radius: sz/2-MARGIN
                                                         startAngle: 0
                                                           endAngle: M_PI * 2
                                                          clockwise: YES];
        [path moveToPoint:CGPointMake(MARGIN, MARGIN)];
        [path addLineToPoint:CGPointMake(sz-MARGIN, sz-MARGIN)];
        [path moveToPoint:CGPointMake(MARGIN, sz-MARGIN)];
        [path addLineToPoint:CGPointMake(sz-MARGIN, MARGIN)];
        [[UIColor redColor] setFill];
        [[UIColor whiteColor] setStroke];
        [path setLineWidth: 3.0];
        [path fill];
        [path stroke];
        deleteButtonImg = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    [self.deleteButton setImage: deleteButtonImg
                       forState: UIControlStateNormal];
    [self.deleteButton addTarget: self
                          action: @selector(deleteBtnTapped:)
                forControlEvents: UIControlEventTouchUpInside];
    [self.deleteButton setHidden: YES];
    
    [self.contentView addSubview: self.deleteButton];
    
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
- (void)startQuivering
{
    DLog();
    
    CABasicAnimation *quiverAnim = [CABasicAnimation animationWithKeyPath: @"transform.rotation"];
    
    float startAngle    = (-2) * M_PI/180.0;
    float stopAngle     = -startAngle;
    
    quiverAnim.fromValue    = [NSNumber numberWithFloat:startAngle];
    quiverAnim.toValue      = [NSNumber numberWithFloat:3 * stopAngle];
    quiverAnim.autoreverses = YES;
    quiverAnim.duration     = 0.2;
    quiverAnim.repeatCount  = HUGE_VALF;
    float timeOffset        = (float)(arc4random() % 100)/100 - 0.50;
    quiverAnim.timeOffset   = timeOffset;
    CALayer *layer          = self.layer;
    
    [layer addAnimation: quiverAnim
                 forKey: @"quivering"];
}


//----------------------------------------------------------------------------------------------------------
- (void)stopQuivering
{
    CALayer *layer = self.layer;
    [layer removeAnimationForKey:@"quivering"];
}

//----------------------------------------------------------------------------------------------------------
//- (void)prepareForReuse
//{
//    DLog();
//    
//    self.backgroundColor = [UIColor lightGrayColor];
//    
//    self.layer.cornerRadius = 5.;
////    self.viewForBaselineLayout.layer.cornerRadius = 2.;
//    
//}

//----------------------------------------------------------------------------------------------------------
//- (void)setSelected:(BOOL)selected animated:(BOOL)animated
//{
//    [super setSelected:selected animated:animated];
//
//    // Configure the view for the selected state
//}

//----------------------------------------------------------------------------------------------------------
- (IBAction)coverLtrBtnTapped:(id)sender
{
    DLog();
    
    [_delegate coverLtrButtonTapped: self];
}

//----------------------------------------------------------------------------------------------------------
- (IBAction)resumeBtnTapped:(id)sender
{
    DLog();
    
    [_delegate resumeButtonTapped: self];
}

//----------------------------------------------------------------------------------------------------------
- (IBAction)deleteBtnTapped:(id)sender
{
    DLog();
    
    [_delegate deleteButtonTapped: self];
}

//----------------------------------------------------------------------------------------------------------
- (void)preferredContentSizeChanged:(NSNotification *)aNotification
{
    [self calculateAndSetFonts];
}

//----------------------------------------------------------------------------------------------------------
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

//----------------------------------------------------------------------------------------------------------
- (void)applyLayoutAttributes:(OCRReorderableLayoutAttributes *)layoutAttributes
{
    DLog(@"isDeleteButtonHidden=%@", layoutAttributes.isDeleteButtonHidden ? @"YES" : @"NO");
    
    if (layoutAttributes.isDeleteButtonHidden) {
        self.deleteButton.layer.opacity = 0.0;
        [self stopQuivering];
    } else {
        self.deleteButton.layer.opacity = 1.0;
        [self startQuivering];
    }
}

@end
