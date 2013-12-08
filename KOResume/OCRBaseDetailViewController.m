//
//  OCRBaseDetailViewController.m
//  KOResume
//
//  Created by Kevin O'Mara on 7/14/13.
//  Copyright (c) 2013 O'Mara Consulting Associates. All rights reserved.
//

#import "OCRBaseDetailViewController.h"
#import "OCRAppDelegate.h"
#import "Resumes.h"

#define kSummaryTableCell   0
#define kResumeTableCell    1

@interface OCRBaseDetailViewController ()

@property (nonatomic, strong) UIPopoverController *masterPopoverController;

@end

@implementation OCRBaseDetailViewController

#pragma mark - Managing the detail item

//----------------------------------------------------------------------------------------------------------
- (void)setSelectedPackage:(Packages *)aSelectedPackage
{
    if (_selectedPackage != aSelectedPackage) {
        _selectedPackage = aSelectedPackage;
        
        // Update the view.
        [self configureView];
    }

    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }        
}

#pragma mark - View lifecycle

//----------------------------------------------------------------------------------------------------------
- (void)viewWillAppear:(BOOL)animated
{
    DLog();
    
    [super viewWillAppear: animated];
    
    self.navigationItem.leftBarButtonItem.title = _backButtonTitle;
    
    // Set an observer for iCloud changes
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(reloadFetchedResults:)
                                                 name: OCRApplicationDidMergeChangesFrom_iCloudNotification
                                               object: nil];
}


//----------------------------------------------------------------------------------------------------------
- (void)viewWillDisappear:(BOOL)animated
{
    DLog();
    
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    // Save any changes
    [kAppDelegate saveContext: [kAppDelegate managedObjectContext]];

    [super viewWillDisappear: animated];
}


//----------------------------------------------------------------------------------------------------------
- (void)didReceiveMemoryWarning
{
    ALog();
    
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}


//----------------------------------------------------------------------------------------------------------
- (void)configureView
{
    /*
     Subclasses must override this method
     */
    [NSException raise: @"Required method not implemented"
                format: @"configureView is required"];
}

//----------------------------------------------------------------------------------------------------------
- (void)reloadFetchedResults:(NSNotification*)note
{
    DLog();
    
    NSError *error = nil;
    
    if (![[self fetchedResultsController] performFetch: &error]) {
        ELog(error, @"Fetch failed!");
        NSString* msg = NSLocalizedString(@"Failed to reload data.", nil);
        [OCAExtensions showErrorWithMessage: msg];
    }
    /*
     Subclasses should override this method reload views as necessary. For example:
     [super reloadFetchedResults: note]
     [self.tblView reloadData];
     */
}

@end
