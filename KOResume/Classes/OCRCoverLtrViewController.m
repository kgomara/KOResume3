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
    UIBarButtonItem     *doneBtn;
    
    /**
     Reference to the cancel button to facilitate swapping buttons between display and edit modes
     */
    UIBarButtonItem     *cancelBtn;
    
    /**
     A boolean flag to indicate whether the user is editing information or simply viewing.
     */
    BOOL                isEditing;
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
	
    // Set the default button title
    self.backButtonTitle        = NSLocalizedString(@"Packages", nil);
    
    // Set up button items
    backBtn     = self.navigationItem.leftBarButtonItem;
    editBtn     = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemEdit
                                                                target: self
                                                                action: @selector(didPressEditButton)];
    
    doneBtn     = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
                                                                target: self
                                                                action: @selector(didPressDoneButton)];
    
    cancelBtn   = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel
                                                                target: self
                                                                action: @selector(didPressCancelButton)];
    
    // Set editing off
    isEditing = NO;
    [self configureUIForEditing: NO];
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
 If a view controller is presented by a view controller inside of a popover, this method is not invoked on the 
 presenting view controller after the presented controller is dismissed.
 
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
                                             selector: @selector(keyboardDidShow:)
                                                 name: UIKeyboardDidShowNotification
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(keyboardWillBeHidden:)
                                                 name: UIKeyboardWillHideNotification
                                               object: nil];

    // ...add an observer for Dynamic Text size changes
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(userTextSizeDidChange:)
                                                 name: UIContentSizeCategoryDidChangeNotification
                                               object: nil];
    
    // ...and an observer for package object deletion
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(packageWasDeleted:)
                                                 name: kOCRMocDidDeletePackageNotification
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
    if ([(Packages *)self.selectedManagedObject cover_ltr])
    {
        // We have a selected object with data
        [_noSelectionView setHidden:YES];
        _coverLtrFld.text	= [(Packages *)self.selectedManagedObject cover_ltr];
    }
    else
    {
        if (self.selectedManagedObject)
        {
            // We have a selected object, but no data
            _noSelectionLabel.text = NSLocalizedString(@"Press Edit to enter text.", nil);
        }
        else
        {
            // Nothing is selected
            _noSelectionLabel.text = NSLocalizedString(@"Nothing selected.", nil);
        }
        [_noSelectionView setHidden:NO];
        [self.view bringSubviewToFront:_noSelectionView];
        _coverLtrFld.text	= @"";
    }
}


//----------------------------------------------------------------------------------------------------------
/**
 Enables or disables all the UI text fields for editing.
 
 As a resume app, a major Use Case is the user sharing his/her experience by passing the iOS device around.
 To avoid accidently changing information, the app defaults to non-editable and there is an explicit Edit
 button when the user wants to change information. This method sets the enabled state as appropriate and also
 changes the background color to make "edit mode" more visually distinct.
 
 @param editable    A BOOL that determines whether the fields should be enabled for editing - or not.
 */
- (void)setFieldsEditable: (BOOL)editable
{
    DLog();
    
    // Set all the text fields (and the text view as well) enable property
    [_coverLtrFld        setEditable: editable];
    
    // Set the background color for the text view on the editable param
    UIColor *backgroundColor = editable? [UIColor colorWithRed:1 green:0 blue:0 alpha:0.1f] /* [UIColor whiteColor] */ : [UIColor clearColor];
    
    // ...and set the background color
    [_coverLtrFld        setBackgroundColor: backgroundColor];
}


//----------------------------------------------------------------------------------------------------------
/**
 Configure the default items for the navigation bar.
 */
- (void)configureDefaultNavBar
{
    DLog();
    
    // Set the buttons.
    self.navigationItem.rightBarButtonItems = @[editBtn];
    if (self.selectedManagedObject && !self.selectedManagedObject.isDeleted)
    {
        // We have an object to work with - allow editing
        [editBtn setEnabled:YES];
    }
    else
    {
        // The object we were given has been deleted - can't edit "nothing"
        [editBtn setEnabled:NO];
    }
    
    // ...by default, the user cannot edit the text, make it un-editable until the user taps the edit button
    [self.coverLtrFld setEditable:NO];
}


//----------------------------------------------------------------------------------------------------------
/**
 Update internal state of the view controller when a package has been deleted.
 
 Invoked by notification posted by OCRPackagesViewController when it performs a package deletion.
 
 @param aNotification   The NSNotification object associated with the event.
 */
- (void)packageWasDeleted: (NSNotification *)aNotification
{
    DLog();
    
    if ( ![(Packages *)self.selectedManagedObject cover_ltr] ||
          [self.selectedManagedObject isDeleted])
    {
        self.selectedManagedObject = nil;
    }
}

#pragma mark - UITextKit handlers

//----------------------------------------------------------------------------------------------------------
/**
 Called when the user changes the size of dynamic text.
 
 @param aNotification   The notification sent with the UIContentSizeCategoryDidChangeNotification notification
 */
- (void)userTextSizeDidChange: (NSNotification *)aNotification
{
    DLog();
    
    // Reload the table view, which in turn causes the tableView cells to update their fonts
    _coverLtrFld.font = [UIFont preferredFontForTextStyle: UIFontTextStyleBody];
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
     method in other OCRBaseDetailViewController subclasses. In other classes, the title may change if the 
     selected object changes.
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
    
    // Turn on editing in the UI
    [self configureUIForEditing: YES];
    
    // Start an undo group...it will either be commited in didPressSaveButton or
    //    undone in didPressCancelButton
    [[[kAppDelegate managedObjectContext] undoManager] beginUndoGrouping];
    
    // ...and bring the keyboard onscreen with the cursor in coverLtrFld
    [_coverLtrFld becomeFirstResponder];
}


//----------------------------------------------------------------------------------------------------------
/**
 Invoked when the user taps the Done button.
 
 * Save the changes to the NSManagedObjectContext.
 * Cleanup the undo group on the NSManagedObjectContext.
 * Reset the navigation bar to its default state.
 
 */
- (void)didPressDoneButton
{
    DLog();
    
    // Save the changes from the textView into the selected cover letter
    [(Packages *)self.selectedManagedObject setCover_ltr: self.coverLtrFld.text];
    
    // ...end the undo group
    [[[kAppDelegate managedObjectContext] undoManager] endUndoGrouping];
    
    // ...save changes to the database
    [kAppDelegate saveContext: [self.fetchedResultsController managedObjectContext]];
    
    // ...cleanup the undoManager
    [[[kAppDelegate managedObjectContext] undoManager] removeAllActionsWithTarget:self];
    
    // ...and reset the UI defaults
    [self configureUIForEditing: NO];
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
    
    if ([[[kAppDelegate managedObjectContext] undoManager] canUndo])
    {
        // Changes were made - discard them
        [[[kAppDelegate managedObjectContext] undoManager] undoNestedGroup];
    }
    
    // Cleanup the undoManager
    [[[kAppDelegate managedObjectContext] undoManager] removeAllActionsWithTarget: self];
    
    // ...re-load the view with the data from the (unchanged) cover letter
    [self loadViewFromSelectedObject];
    
    // ...and reset the UI defaults
    [self configureUIForEditing: NO];
    [self resetView];
}


//----------------------------------------------------------------------------------------------------------
/**
 Set the UI for for editing enabled or disabled.
 
 Called when the user presses the Edit, Done, or Cancel buttons.
 
 @param isEditingMode   YES if we are going into edit mode, NO otherwise.
 */
- (void)configureUIForEditing: (BOOL)isEditingMode
{
    DLog();
    
    // Update editing flag
    isEditing = isEditingMode;
    
    // Hide the noSelectedView
    [self.noSelectionView setHidden:YES];
    
    // ...enable/disable resume fields
    [self setFieldsEditable: isEditingMode];
    
    if (isEditingMode)
    {
        // Set up the navigation items and save/cancel buttons
        self.navigationItem.rightBarButtonItems = @[doneBtn, cancelBtn];
    }
    else
    {
        // Reset the nav bar defaults
        [self configureDefaultNavBar];
    }
}

#pragma mark - Keyboard handlers

//----------------------------------------------------------------------------------------------------------
/**
 Invoked when the keyboard is about to show.
 
 Adjust the scrollview contentInsets to ensure the content of the textView can be scrolled by the user to
 wherever they wish to edit the text.
 
 @param aNotification   the NSNotification containing information about the keyboard.
 */
- (void)keyboardDidShow: (NSNotification*)aNotification
{
    DLog();
    
    // Get the size of the keyboard
    NSDictionary *info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    // ...and adjust the contentInset for its height
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    
    self.coverLtrFld.contentInset           = contentInsets;
    self.coverLtrFld.scrollIndicatorInsets  = contentInsets;
    
    /*
     In the case of the coverletter, the textView is the only editable object and it is not clear
     where - or even if -- we should scroll the textView. In other view controllers we would
     send the scrollRectToVisible to the scrollView here. For example, see OCRResumeOverviewViewController.
     */
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
 @return               YES if an editing session should be initiated; otherwise, NO to disallow editing.
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
 
 @param aNote       the NSNotification describing the changes.
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
