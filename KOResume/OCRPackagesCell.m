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


//----------------------------------------------------------------------------------------------------------
- (void)awakeFromNib
{
    DLog();
    
    [super awakeFromNib];
    
    self.backgroundColor = [UIColor darkGrayColor];
    
    self.layer.cornerRadius = 5.0f;
    self.viewForBaselineLayout.layer.cornerRadius = 2.0f;
    
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
    
    [_delegate coverLtrButtonTapped:self];
}

//----------------------------------------------------------------------------------------------------------
- (IBAction)resumeBtnTapped:(id)sender
{
    DLog();
    
    [_delegate resumeButtonTapped:self];
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

#pragma mark - Seque handling

//----------------------------------------------------------------------------------------------------------
- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender
{
    DLog();
    
//    if ([[segue identifier] isEqualToString: @"OCACoverLtrID"]) {
//        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
//        /*
//         See the comment in - configureCell:atIndexPath: to understand why we are only using the section with fetchedResultsController
//         */
//        id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:indexPath.section];
//        Packages *aPackage  = (Packages *) [sectionInfo.objects objectAtIndex:0];
//        
//        [[segue destinationViewController] setSelectedPackage:aPackage];
//        [[segue destinationViewController] setManagedObjectContext: self.managedObjectContext];
//        [[segue destinationViewController] setFetchedResultsController: self.fetchedResultsController];
//    }
}

@end
