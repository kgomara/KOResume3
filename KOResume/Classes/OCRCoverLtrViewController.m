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
     reference to the back button to facilitate swapping buttons between display and edit modes
     */
    UIBarButtonItem     *backBtn;
    
    /**
     reference to the edit button to facilitate swapping buttons between display and edit modes
     */
    UIBarButtonItem     *editBtn;
    
    /**
     reference to the save button to facilitate swapping buttons between display and edit modes
     */
    UIBarButtonItem     *saveBtn;
    
    /**
     reference to the cancel button to facilitate swapping buttons between display and edit modes
     */
    UIBarButtonItem     *cancelBtn;
}

@end

@implementation OCRCoverLtrViewController

#pragma mark - Life Cycle methods

//----------------------------------------------------------------------------------------------------------
- (void)viewDidLoad
{
    DLog();
    
    [super viewDidLoad];
	
	self.view.backgroundColor = [UIColor clearColor];
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
- (void)viewWillAppear:(BOOL)animated
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
- (void)viewWillDisappear:(BOOL)animated
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
    [(Packages *)self.selectedManagedObject setCover_ltr:self.coverLtrFld.text];
    
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
- (void)keyboardWillShow:(NSNotification*)aNotification
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
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    DLog();
    
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    
    self.coverLtrFld.contentInset          = contentInsets;
    self.coverLtrFld.scrollIndicatorInsets = contentInsets;
}

#pragma mark - UITextView delegate methods

//----------------------------------------------------------------------------------------------------------
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    DLog();
    
    return YES;
}


//----------------------------------------------------------------------------------------------------------
- (void)textViewDidEndEditing:(UITextView *)textView
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
- (void)reloadFetchedResults:(NSNotification*)aNote
{
    DLog();
    
    // Invoke super to fetch the object(s)
    [super reloadFetchedResults: aNote];
    // ...and update the view with the new data
    [self loadViewFromSelectedObject];
}

@end
