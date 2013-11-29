//
//  OCRDetailViewController.m
//  KOResume
//
//  Created by Kevin O'Mara on 7/14/13.
//  Copyright (c) 2013 O'Mara Consulting Associates. All rights reserved.
//

#import "OCRDetailViewController.h"
#import "OCRAppDelegate.h"
//#import <CoreData/CoreData.h>
//#import "CoverLtrViewController.h"
//#import "ResumeViewController.h"
#import "Resumes.h"

#define kSummaryTableCell   0
#define kResumeTableCell    1

@interface OCRDetailViewController ()

@property (strong, nonatomic) UIPopoverController *masterPopoverController;

@end

@implementation OCRDetailViewController

#pragma mark SubstitutableDetailViewController

// -------------------------------------------------------------------------------
//        setNavigationPaneBarButtonItem:
//  Custom implementation for the navigationPaneBarButtonItem setter.
//  In addition to updating the _navigationPaneBarButtonItem ivar, it
//  reconfigures the toolbar to either show or hide the
//  navigationPaneBarButtonItem.
// -------------------------------------------------------------------------------
- (void)setNavigationPaneBarButtonItem:(UIBarButtonItem *)navigationPaneBarButtonItem
{
    if (navigationPaneBarButtonItem != _navigationPaneBarButtonItem) {
        self.titleLabel.text = self.title;
        _navigationPaneBarButtonItem = navigationPaneBarButtonItem;
    }
}

#pragma mark - Managing the detail item

//----------------------------------------------------------------------------------------------------------
- (void)setSelectedPackage:(Packages *)nuSelectedPackage
{
    if (_selectedPackage != nuSelectedPackage) {
        _selectedPackage = nuSelectedPackage;
        
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
#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController
     willHideViewController:(UIViewController *)viewController
          withBarButtonItem:(UIBarButtonItem *)barButtonItem
       forPopoverController:(UIPopoverController *)popoverController
{
    DLog();
    
    barButtonItem.title = _backButtonTitle;
    [self.navigationItem setLeftBarButtonItem:barButtonItem
                                     animated:YES];
    self.masterPopoverController = popoverController;
}

//----------------------------------------------------------------------------------------------------------
- (void)splitViewController:(UISplitViewController *)splitController
     willShowViewController:(UIViewController *)viewController
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    DLog();
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    barButtonItem.title = _backButtonTitle;
    [self.navigationItem setLeftBarButtonItem:nil
                                     animated:YES];
    self.masterPopoverController = nil;
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
