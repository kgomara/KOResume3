//
//  OCRCoverLtrViewController.m
//  KOResume
//
//  Created by Kevin O'Mara on 3/15/11.
//  Copyright (c) 2011-2014 O'Mara Consulting Associates. All rights reserved.
//

#import "OCRCoverLtrViewController.h"
#import "OCRAppDelegate.h"
#import "Packages.h"

@interface OCRCoverLtrViewController ()
{
@private
    /**
     Reference to the back button to facilitate swapping buttons between display and edit modes
     */
    UIBarButtonItem     *backBtn;
    
    /**
     Reference to the edit button to facilitate swapping buttons between display and edit modes
     */
    UIBarButtonItem     *editBtn;
    
    /**
     Reference to the save button to facilitate swapping buttons between display and edit modes
     */
    UIBarButtonItem     *saveBtn;
    
    /**
     Reference to the cancel button to facilitate swapping buttons between display and edit modes
     */
    UIBarButtonItem     *cancelBtn;
}

@end

@implementation OCRCoverLtrViewController

#pragma mark - Life Cycle methods

//----------------------------------------------------------------------------------------------------------
/**
 Called after the controller’s view is loaded into memory.
 
 This method is called after the view controller has loaded its view hierarchy into memory. This method is
 called regardless of whether the view hierarchy was loaded from a nib file or created programmatically in
 the loadView method. You usually override this method to perform additional initialization on views that
 were loaded from nib files.
 */
- (void)viewDidLoad
{
    DLog();
    
    [super viewDidLoad];
	
	self.view.backgroundColor   = [UIColor clearColor];
    // Set the default button title
    self.backButtonTitle        = NSLocalizedString(@"Packages", nil);
    
    // Set up button items
    backBtn     = self.navigationItem.leftBarButtonItem;
    editBtn     = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemEdit
                                                                target: self
                                                                action: @selector(didPressEditButton)];
    saveBtn     = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemSave
                                                                target: self
                                                                action: @selector(didPressSaveButton)];
    cancelBtn   = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel
                                                                target: self
                                                                action: @selector(didPressCancelButton)];
    
}


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
 If a view controller is presented by a view controller inside of a popover, this method is not invoked on the presenting view controller after the presented controller is dismissed.
 
 @param animated        If YES, the view is being added to the window using an animation.
 */
- (void)viewWillAppear: (BOOL)animated
{
    DLog();
    [super viewWillAppear: animated];
    
    // Set up the navigation bar items
    [self configureDefaultNavBar];
    // ...and configure the view
    [self configureView];
    
    // Register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(keyboardWillShow:)
                                                 name: UIKeyboardWillShowNotification
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(keyboardWillBeHidden:)
                                                 name: UIKeyboardWillHideNotification
                                               object: nil];
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
    
    /*
     removeObserver is handled in super class
     */
    
    self.scrollView             = nil;
    self.coverLtrFld            = nil;
    
    [super viewWillDisappear: animated];
}


//----------------------------------------------------------------------------------------------------------
/**
 Update the text fields of the view from the selected cover_ltr.
 */
- (void)loadViewFromSelectedObject
{
    DLog();
    
    // Load the cover letter into the view
    if ([(Packages *)self.selectedManagedObject cover_ltr]) {
        self.coverLtrFld.text	= [(Packages *)self.selectedManagedObject cover_ltr];
    } else {
        self.coverLtrFld.text	= @"";
    }
}


//----------------------------------------------------------------------------------------------------------
/**
 Configure the default items for the navigation bar.
 */
- (void)configureDefaultNavBar
{
    DLog();
    
    // Set the buttons.
    self.navigationItem.rightBarButtonItem = editBtn;
    self.navigationItem.leftBarButtonItem  = backBtn;
    
    // ...by default, the user cannot edit the text, make it un-editable until the user taps the edit button
    [self.coverLtrFld setEditable:NO];
}

#pragma mark - OCRDetailViewProtocol delegates

//----------------------------------------------------------------------------------------------------------
/**
 Configure the view items. 
 
 This method is called when the selectedManagedObject changes.
 */
- (void)configureView
{
    DLog();
    
    /*
     The navigation bar title is set here rather configureDefaultNavBar to be consistent with this delegate
     method in other OCRBaseDetailViewController subclasses where the title may change if he selected object
     changes.
     */

    // Set the title in the navigation bar.
    self.navigationItem.title = NSLocalizedString(@"Cover Letter", nil);
    // ...and load the data fields with updated data from the selected object.
    [self loadViewFromSelectedObject];
}


#pragma mark - UI handlers

//----------------------------------------------------------------------------------------------------------
/**
 Invoked when the user taps the Edit button.
 
 * Setup the navigation bar for editing.
 * Enable editable fields.
 * Start an undo group on the NSManagedObjectContext.
 
 */
- (void)didPressEditButton
{
    DLog();
    
    // Set up the navigation item and save button
    self.navigationItem.leftBarButtonItem  = cancelBtn;
    self.navigationItem.rightBarButtonItem = saveBtn;
    
    // Enable the fields for editing
    [self.coverLtrFld setEditable: YES];
    
    // Start an undo group...it will either be commited in didPressSaveButton or
    //    undone in didPressCancelButton
    [[[kAppDelegate managedObjectContext] undoManager] beginUndoGrouping];
    // ...and bring the keyboard onscreen with the cursor in coverLtrFld
    [self.coverLtrFld becomeFirstResponder];
}


//----------------------------------------------------------------------------------------------------------
/**
 Invoked when the user taps the Save button.
 
 * Save the changes to the NSManagedObjectContext.
 * Cleanup the undo group on the NSManagedObjectContext.
 * Reset the navigation bar to its default state.
 
 */
- (void)didPressSaveButton
{
    DLog();
    
    // Save the changes from the textView into the selected cover letter
    [(Packages *)self.selectedManagedObject setCover_ltr: self.coverLtrFld.text];
    
    // We've complete editing, "close" the undo group
    [[[kAppDelegate managedObjectContext] undoManager] endUndoGrouping];
    
    // ...commit the changes
    [kAppDelegate saveContext: [self.fetchedResultsController managedObjectContext]];
    
    // Cleanup the undoManager
    [[[kAppDelegate managedObjectContext] undoManager] removeAllActionsWithTarget:self];
    // ...and reset the UI defaults
    [self configureDefaultNavBar];
    [self resetView];
}


//----------------------------------------------------------------------------------------------------------
/**
 Invoked when the user taps the Cancel button.
 
 * End the undo group on the NSManagedObjectContext.
 * If the undoManager has changes it canUndo, undo them.
 * Cleanup the undoManager.
 * Reset the UI to its default state.
 
 */
- (void)didPressCancelButton
{
    DLog();
    
    // Undo any changes the user has made
    [[[kAppDelegate managedObjectContext] undoManager] setActionName:kOCRUndoActionName];
    [[[kAppDelegate managedObjectContext] undoManager] endUndoGrouping];
    
    if ([[[kAppDelegate managedObjectContext] undoManager] canUndo]) {
        [[[kAppDelegate managedObjectContext] undoManager] undoNestedGroup];
    }
    
    // Cleanup the undoManager
    [[[kAppDelegate managedObjectContext] undoManager] removeAllActionsWithTarget: self];
    // ...re-load the view with the data from the (unchanged) cover letter
    [self loadViewFromSelectedObject];
    // ...and reset the UI defaults
    [self configureDefaultNavBar];
    [self resetView];
}

#pragma mark - Keyboard handlers

//----------------------------------------------------------------------------------------------------------
/**
 Invoked when the keyboard is about to show.
 
 Scroll the content to ensure the active field is visible.
 
 @param aNotification   the NSNotification containing information about the keyboard.
 */
- (void)keyboardWillShow: (NSNotification*)aNotification
{
    DLog();
    
    // Get the size of the keyboard
    NSDictionary *info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey: UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    // ...and adjust the contentInset for its height
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    
    self.coverLtrFld.contentInset           = contentInsets;
    self.coverLtrFld.scrollIndicatorInsets  = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, self.coverLtrFld.frame.origin)) {
        // calculate the contentOffset for the scroller
        CGPoint scrollPoint = CGPointMake(0.0, self.coverLtrFld.frame.origin.y - kbSize.height);
        [self.coverLtrFld setContentOffset: scrollPoint
                                  animated: YES];
    }
}


//----------------------------------------------------------------------------------------------------------
/**
 Invoked when the keyboard is about to be hidden.
 
 Reset the contentInsets to "zero".
 
 @param aNotification   the NSNotification containing information about the keyboard.
 */
- (void)keyboardWillBeHidden: (NSNotification*)aNotification
{
    DLog();
    
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    
    self.coverLtrFld.contentInset          = contentInsets;
    self.coverLtrFld.scrollIndicatorInsets = contentInsets;
}

#pragma mark - UITextView delegate methods

//----------------------------------------------------------------------------------------------------------
/**
 Asks the delegate if editing should begin in the specified text view.
 
 When the user performs an action that would normally initiate an editing session, the text view calls this
 method first to see if editing should actually proceed. In most circumstances, you would simply return YES
 from this method to allow editing to proceed.
 
 Implementation of this method by the delegate is optional. If it is not present, editing proceeds as if this
 method had returned YES.
 
 @param textView        The text view for which editing is about to begin.
 @returns               YES if an editing session should be initiated; otherwise, NO to disallow editing.
 */
- (BOOL)textViewShouldBeginEditing: (UITextView *)textView
{
    DLog();
    
    return YES;
}


//----------------------------------------------------------------------------------------------------------
/**
 Tells the delegate that editing of the specified text view has ended.
 
 Implementation of this method is optional. A text view sends this message to its delegate after it closes out
 any pending edits and resigns its first responder status. You can use this method to tear down any data structures
 or change any state information that you set when editing began.
 
 @param textView The text view in which editing ended.
 */
- (void)textViewDidEndEditing: (UITextView *)textView
{
    DLog();;
}


//----------------------------------------------------------------------------------------------------------
/**
 Reset the view to it default state.
 */
- (void)resetView
{
    DLog();
    
    [self.scrollView setContentOffset: CGPointZero
                             animated: YES];
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
    
    // Invoke super to fetch the object(s)
    [super reloadFetchedResults: aNote];
    // ...and update the view with the new data
    [self loadViewFromSelectedObject];
}

@end
