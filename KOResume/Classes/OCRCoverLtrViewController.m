//
//  OCRCoverLtrViewController.m
//  KOResume
//
//  Created by Kevin O'Mara on 8/11/13.
//  Copyright (c) 2013 O'Mara Consulting Associates. All rights reserved.
//

#import "OCRCoverLtrViewController.h"
#import "OCRAppDelegate.h"

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
    
    // Set up btn items
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
    
    [self configureDefaultNavBar];
    [self configureView];
    [self updateDataFields];
    
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
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


//----------------------------------------------------------------------------------------------------------
/**
 Configure the view items
 */
- (void)configureView
{
    DLog();
    
    self.navigationItem.title = NSLocalizedString(@"Cover Letter", nil);
}


//----------------------------------------------------------------------------------------------------------
/**
 Update the data fields of the view - the cover letter
 */
- (void)updateDataFields
{
    DLog();
    
    // get the cover letter into the view
    if (self.selectedPackage.cover_ltr) {
        self.coverLtrFld.text	= self.selectedPackage.cover_ltr;
    } else {
        self.coverLtrFld.text	= @"";
//        [self didPressEditButton];
    }
}


//----------------------------------------------------------------------------------------------------------
/**
 Configure the default items for the navigation bar
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

#pragma mark - UI handlers

//----------------------------------------------------------------------------------------------------------
/**
 Invoked when the user taps the Edit button
 
 * Setup the navigation bar for editing
 * Enable editable fields
 * Start an undo group on the NSManagedObjectContext
 
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
    [self.coverLtrFld becomeFirstResponder];
}


//----------------------------------------------------------------------------------------------------------
/**
 Invoked when the user taps the Save button
 
 * Save the changes to the NSManagedObjectContext
 * Cleanup the undo group on the NSManagedObjectContext
 * Reset the navigation bar to its default state
 
 */
- (void)didPressSaveButton
{
    DLog();
    
    // Save the changes
    self.selectedPackage.cover_ltr = self.coverLtrFld.text;
    
    [[[kAppDelegate managedObjectContext] undoManager] endUndoGrouping];
    
    [kAppDelegate saveContext: [self.fetchedResultsController managedObjectContext]];
    
    // Cleanup the undoManager
    [[[kAppDelegate managedObjectContext] undoManager] removeAllActionsWithTarget:self];
    // ...and reset the UI defaults
    [self configureDefaultNavBar];
    [self resetView];
}


//----------------------------------------------------------------------------------------------------------
/**
 Invoked when the user taps the Cancel button
 
 * End the undo group on the NSManagedObjectContext
 * If the undoManager has changes it canUndo, undo them
 * Cleanup the undoManager
 * Reset the UI to its default state
 
 */
- (void)didPressCancelButton
{
    DLog();
    
    // Undo any changes the user has made
    [[[kAppDelegate managedObjectContext] undoManager] setActionName:OCRUndoActionName];
    [[[kAppDelegate managedObjectContext] undoManager] endUndoGrouping];
    
    if ([[[kAppDelegate managedObjectContext] undoManager] canUndo]) {
        [[[kAppDelegate managedObjectContext] undoManager] undoNestedGroup];
    }
    
    // Cleanup the undoManager
    [[[kAppDelegate managedObjectContext] undoManager] removeAllActionsWithTarget: self];
    // ...and reset the UI defaults
    self.coverLtrFld.text    = self.selectedPackage.cover_ltr;
    [self updateDataFields];
    [self configureDefaultNavBar];
    [self resetView];
}

#pragma mark - Keyboard handlers

//----------------------------------------------------------------------------------------------------------
/**
 Invoked when the keyboard is about to show
 
 Scroll the content to ensure the active field is visible
 
 @param aNotification   the NSNotification containing information about the keyboard
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
 Invoked when the keyboard is about to be hidden
 
 Reset the contentInsets to "zero"
 
 @param aNotification   the NSNotification containing information about the keyboard
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
 Reset the view to it default state
 */
- (void)resetView
{
    DLog();
    
    [self.scrollView setContentOffset: CGPointZero
                             animated: YES];
}


//----------------------------------------------------------------------------------------------------------
/**
 Reloads the fetched results
 
 Invoke by notification that the underlying data objects may have changed
 
 @param aNote the NSNotification describing the changes (ignored)
 */
- (void)reloadFetchedResults:(NSNotification*)aNote                          // TODO - base class also registers for this notification
{
    DLog();
    
    [super reloadFetchedResults: aNote];                                     // TODO - base class does performBlock...is it async?
    [self updateDataFields];
}

@end
