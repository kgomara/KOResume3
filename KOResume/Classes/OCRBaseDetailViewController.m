//
//  OCRBaseDetailViewController.m
//  KOResume
//
//  Created by Kevin O'Mara on 7/14/13.
//  Copyright (c) 2013-2014 O'Mara Consulting Associates. All rights reserved.
//

#import "OCRBaseDetailViewController.h"
#import "OCRAppDelegate.h"
#import "Resumes.h"

#define kSummaryTableCell   0
#define kResumeTableCell    1

/*
 This class is the base class which all details view controllers subclass
 */
@implementation OCRBaseDetailViewController

#pragma mark - Managing the detail item

//----------------------------------------------------------------------------------------------------------
/**
 Set the selectedManagedObject property
 
 If the new Packages property is different than what the detail view is currently displaying, it will invoke the
 configureView method of the subclass.
 
 @param aSelectedPackage    the Packages to set.
 */
- (void)setSelectedManagedObject:(Packages *)aSelectedPackage
{
    DLog();
    
    // Check to see if the new package is different than the current one
    if (_selectedManagedObject != aSelectedPackage) {
        _selectedManagedObject  = aSelectedPackage;
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
    
    // Set the back button from the cached back button title
    self.navigationItem.leftBarButtonItem.title = _backButtonTitle;
    
    // Set an observer for iCloud changes
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(reloadFetchedResults:)
                                                 name: kOCRApplicationDidMergeChangesFrom_iCloudNotification
                                               object: nil];
}


//----------------------------------------------------------------------------------------------------------
- (void)viewWillDisappear:(BOOL)animated
{
    DLog();
    
    // Hide the subclass' back button
    [self invalidateRootPopoverButtonItem:_backButtonCached];
    
    // Remove all observers
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    // ...and save any changes
    [kAppDelegate saveContext: [kAppDelegate managedObjectContext]];

    [super viewWillDisappear: animated];
}

//----------------------------------------------------------------------------------------------------------
- (void)viewDidAppear:(BOOL)animated
{
    DLog();
    
    [super viewDidAppear:animated];
    
    // Show the subclass' back button
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
- (BOOL)shouldAutorotate
{
    // All view controllers support rotation
    return YES;
}

//----------------------------------------------------------------------------------------------------------
- (NSUInteger)supportedInterfaceOrientations
{
    // All view controllers support all orientations
    return UIInterfaceOrientationMaskAll;
}


//----------------------------------------------------------------------------------------------------------
- (void)configureView
{
    /*
     Subclasses must override this method, throw and exception if this base method is called.
     */
    [NSException raise: @"Required method not implemented"
                format: @"configureView is required"];
}

#pragma mark - SubstitutableDetailViewController protocols

//----------------------------------------------------------------------------------------------------------
/**
 Sets the bar button item that will invoke the master view.
 
 @param aBarButtonItem  the bar button item to install.
 @param aPopoverController  the popoverController of the master view.
 */
- (void)showRootPopoverButtonItem:(UIBarButtonItem *)aBarButtonItem
                   withController:(UIPopoverController *)aPopoverController;
{
    DLog();
    
    // The detail view passes in the back button item to use
    self.backButtonCached   = aBarButtonItem;
    // In our case, the back button invokes the OCRPackagesViewController as master view
    aBarButtonItem.title    = NSLocalizedString(@"Packages", @"Packages");
    [self.navigationItem setLeftBarButtonItem:aBarButtonItem
                                     animated:YES];
    // Save the reference to the popoverController
    self.popoverControllerCached = aPopoverController;
}


//----------------------------------------------------------------------------------------------------------
/**
 Hides the bar button item.
 
 @param aBarButtonItem the bar button item to hide.
 */
- (void)invalidateRootPopoverButtonItem:(UIBarButtonItem *)aBarButtonItem
{
    DLog();
    
    // Hide (by removing the references) the back button
    [self.navigationItem setLeftBarButtonItem:nil
                                     animated:YES];
    // ...and properties set by the detail view
    self.backButtonCached           = nil;
    self.popoverControllerCached    = nil;
}

//----------------------------------------------------------------------------------------------------------
/**
 Reloads the fetched results.
 
 Invoked by notification when the underlying data objects may have changed.
 
 @param aNote the NSNotification describing the changes.
 */
- (void)reloadFetchedResults:(NSNotification*)aNote
{
    DLog();
    
    // Create an NSError object for the fetch
    NSError *error = nil;
    // ...and fetch the data
    if (![[self fetchedResultsController] performFetch: &error]) {
        ELog(error, @"Fetch failed!");
        NSString* msg = NSLocalizedString(@"Failed to reload data.", nil);
        [OCAUtilities showErrorWithMessage: msg];
    }
    /*
     Subclasses should override this method to reload views as necessary. For example:
     [super reloadFetchedResults: note]
     [self.tblView reloadData];
     */
}

@end
