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

@implementation OCRBaseDetailViewController

#pragma mark - Managing the detail item

//----------------------------------------------------------------------------------------------------------
/**
 Set the selectedManagedObject property
 
 If the new Packages property is different than what the detail view is currently displaying, it will invoke the
 configureView method of the subclass.
 
 @param aSelectedPackage    the Packages to set.
 */
- (void)setSelectedManagedObject: (Packages *)aSelectedPackage
{
    DLog();
    
    // Check to see if the new package is different than the current one
    if (_selectedManagedObject != aSelectedPackage) {
        _selectedManagedObject  = aSelectedPackage;
        // Update the view.
        [self configureView];
    }

    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated: YES];
    }        
}

#pragma mark - View lifecycle

//----------------------------------------------------------------------------------------------------------
/**
 Notifies the view controller that its view is about to be added to a view hierarchy.
 
 This method is called before the receiver’s view is about to be added to a view hierarchy and before any
 animations are configured for showing the view. You can override this method to perform custom tasks associated
 with displaying the view. For example, you might use this method to change the orientation or style of the
 status bar to coordinate with the orientation or style of the view being presented. If you override this method,
 you must call super at some point in your implementation.
 
 For more information about the how views are added to view hierarchies by a view controller, and the sequence of
 messages that occur, see “Responding to Display-Related Notifications”.
 
 Note
 If a view controller is presented by a view controller inside of a popover, this method is not invoked on the 
 presenting view controller after the presented controller is dismissed.
 
 @param animated        If YES, the view is being added to the window using an animation.
 */
- (void)viewWillAppear: (BOOL)animated
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
/**
 Notifies the view controller that its view was added to a view hierarchy.
 
 You can override this method to perform additional tasks associated with presenting the view. If you override 
 this method, you must call super at some point in your implementation.
 
 Note - If a view controller is presented by a view controller inside of a popover, this method is not invoked 
 on the presenting view controller after the presented controller is dismissed.
 
 @param animated        If YES, the disappearance of the view is being animated.
 */
- (void)viewDidAppear: (BOOL)animated
{
    DLog();
    
    [super viewDidAppear: animated];
    
    // Show the subclass' back button
    [self showRootPopoverButtonItem: _backButtonCached
                     withController: _popoverControllerCached];
}


//----------------------------------------------------------------------------------------------------------
/**
 Notifies the view controller that its view is about to be removed from a view hierarchy.
 
 This method is called in response to a view being removed from a view hierarchy. This method is called before
 the view is actually removed and before any animations are configured.
 
 Subclasses can override this method and use it to commit editing changes, resign the first responder status of
 the view, or perform other relevant tasks. For example, you might use this method to revert changes to the
 orientation or style of the status bar that were made in the viewDidDisappear: method when the view was first
 presented. If you override this method, you must call super at some point in your implementation.
 
 @param animated        If YES, the disappearance of the view is being animated.
 */
- (void)viewWillDisappear: (BOOL)animated
{
    DLog();
    
    // Hide the subclass' back button
    [self invalidateRootPopoverButtonItem: _backButtonCached];
    
    // Remove all observers
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    // ...and save any changes
    [kAppDelegate saveContext: [kAppDelegate managedObjectContext]];

    [super viewWillDisappear: animated];
}

//----------------------------------------------------------------------------------------------------------
/**
 Sent to the view controller when the app receives a memory warning.
 
 Your app never calls this method directly. Instead, this method is called when the system determines that the 
 amount of available memory is low.
 
 You can override this method to release any additional memory used by your view controller. If you do, your 
 implementation of this method must call the super implementation at some point.
 */
- (void)didReceiveMemoryWarning
{
    ALog();
    
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

//----------------------------------------------------------------------------------------------------------
/**
 Returns whether the view controller’s contents should auto rotate.
 
 In iOS 5 and earlier, the default return value was NO.
 
 @return           YES if the content should rotate, otherwise NO. Default value is YES.
 */
- (BOOL)shouldAutorotate
{
    // All view controllers support rotation
    return YES;
}

//----------------------------------------------------------------------------------------------------------
/**
 Returns all of the interface orientations that the view controller supports.
 
 When the user changes the device orientation, the system calls this method on the root view controller or the 
 topmost presented view controller that fills the window. If the view controller supports the new orientation, 
 the window and view controller are rotated to the new orientation. This method is only called if the view 
 controller’s shouldAutorotate method returns YES.
 
 Override this method to report all of the orientations that the view controller supports. The default values 
 for a view controller’s supported interface orientations is set to UIInterfaceOrientationMaskAll for the iPad 
 idiom and UIInterfaceOrientationMaskAllButUpsideDown for the iPhone idiom.
 
 The system intersects the view controller’s supported orientations with the app's supported orientations (as 
 determined by the Info.plist file or the app delegate's application:supportedInterfaceOrientationsForWindow: 
 method) to determine whether to rotate.
 
 @return           A bit mask specifying which orientations are supported. See UIInterfaceOrientationMask for 
                    valid bit-mask values. The value returned by this method must not be 0.
 */
- (NSUInteger)supportedInterfaceOrientations
{
    // All view controllers support all orientations
    return UIInterfaceOrientationMaskAll;
}


//----------------------------------------------------------------------------------------------------------
/**
 Configure the view.
 
 Subclasses are required to override this method. Therefore the base class throws an exception if called.
 */
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
- (void)showRootPopoverButtonItem: (UIBarButtonItem *)aBarButtonItem
                   withController: (UIPopoverController *)aPopoverController;
{
    DLog();
    
    // The detail view passes in the back button item to use
    self.backButtonCached   = aBarButtonItem;
    // In our case, the back button invokes the OCRPackagesViewController as master view
    aBarButtonItem.title    = NSLocalizedString(@"Packages", @"Packages");
    [self.navigationItem setLeftBarButtonItem: aBarButtonItem
                                     animated: YES];
    // Save the reference to the popoverController
    self.popoverControllerCached = aPopoverController;
}


//----------------------------------------------------------------------------------------------------------
/**
 Hides the bar button item.
 
 @param aBarButtonItem the bar button item to hide.
 */
- (void)invalidateRootPopoverButtonItem: (UIBarButtonItem *)aBarButtonItem
{
    DLog();
    
    // Hide (by removing the references) the back button
    [self.navigationItem setLeftBarButtonItem: nil
                                     animated: YES];
    // ...and properties set by the detail view
    self.backButtonCached           = nil;
    self.popoverControllerCached    = nil;
}

//----------------------------------------------------------------------------------------------------------
/**
 Reloads the fetched results.
 
 Invoked by notification whhen the underlying data objects may have changed.
 
 @param aNote the NSNotification describing the changes.
 */
- (void)reloadFetchedResults: (NSNotification*)aNote
{
    DLog();
    
    // Create an NSError object for the fetch
    NSError *error = nil;
    // ...and fetch the data
    if ( ![[self fetchedResultsController] performFetch: &error]) {
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
