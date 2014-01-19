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

/*
 The class is the base class which all details views subclass
 */
@interface OCRBaseDetailViewController ()

@end

@implementation OCRBaseDetailViewController

#pragma mark - Managing the detail item

//----------------------------------------------------------------------------------------------------------
/**
 Set the selectedPackage property
 
 If the new Packages property is different than the detail view is currently displaying, it will invoke the
 configureView method of the subclass
 
 @param aSelectedPackage    the Packages to set
 */
- (void)setSelectedPackage:(Packages *)aSelectedPackage
{
    DLog();
    
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
    
    [self invalidateRootPopoverButtonItem:_backButtonCached];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    // Save any changes
    [kAppDelegate saveContext: [kAppDelegate managedObjectContext]];

    [super viewWillDisappear: animated];
}

//----------------------------------------------------------------------------------------------------------
- (void)viewDidAppear:(BOOL)animated
{
    DLog();
    
    [super viewDidAppear:animated];
    
    [self showRootPopoverButtonItem:_backButtonCached
                     withController:_popoverControllerCached];
}


//----------------------------------------------------------------------------------------------------------
- (void)didReceiveMemoryWarning
{
    ALog();
    
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}


//----------------------------------------------------------------------------------------------------------
/**
 This is a required method for subclasses to implement.
 */
- (void)configureView
{
    /*
     Subclasses must override this method
     */
    [NSException raise: @"Required method not implemented"
                format: @"configureView is required"];
}

#pragma mark - SubstitutableDetailViewController protocols method

//----------------------------------------------------------------------------------------------------------
/**
 Sets the bar button item that will invoke the master view 
 
 @param aBarButtonItem  the bar button item to install
 @param aPopoverController  the popoverController of the master view
 */
- (void)showRootPopoverButtonItem:(UIBarButtonItem *)aBarButtonItem
                   withController:(UIPopoverController *)aPopoverController;
{
    DLog();
    
    self.backButtonCached   = aBarButtonItem;
    aBarButtonItem.title    = NSLocalizedString(@"Packages", @"Packages");      // TODO - seems like this doesn't belong in the base class
    [self.navigationItem setLeftBarButtonItem:aBarButtonItem
                                     animated:YES];
    self.popoverControllerCached = aPopoverController;
}


//----------------------------------------------------------------------------------------------------------
/**
 Hides the bar button item
 
 @param aBarButtonItem the bar button item to hide
 */
- (void)invalidateRootPopoverButtonItem:(UIBarButtonItem *)aBarButtonItem
{
    DLog();
    
    [self.navigationItem setLeftBarButtonItem:nil
                                     animated:YES];
    self.backButtonCached           = nil;
    self.popoverControllerCached    = nil;
}

//----------------------------------------------------------------------------------------------------------
/**
 Reloads the fetched results
 
 Invoke by notification that the underlying data objects may have changed
 
 @param aNote the NSNotification describing the changes (ignored)
 */
- (void)reloadFetchedResults:(NSNotification*)aNote
{
    DLog();
    
    NSError *error = nil;
    
    if (![[self fetchedResultsController] performFetch: &error]) {
        ELog(error, @"Fetch failed!");
        NSString* msg = NSLocalizedString(@"Failed to reload data.", nil);
        [OCAUtilities showErrorWithMessage: msg];
    }
    /*
     Subclasses should override this method reload views as necessary. For example:
     [super reloadFetchedResults: note]
     [self.tblView reloadData];
     */
}

@end
