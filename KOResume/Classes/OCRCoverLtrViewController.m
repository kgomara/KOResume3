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
    UIBarButtonItem     *backBtn;
    UIBarButtonItem     *editBtn;
    UIBarButtonItem     *saveBtn;
    UIBarButtonItem     *cancelBtn;
}

@property (strong, nonatomic) UIPopoverController *masterPopoverController;

- (void)configureView;
- (void)updateDataFields;
- (void)configureDefaultNavBar;
- (void)resetView;

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
                                                                action: @selector(editButtonTapped)];
    saveBtn     = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemSave
                                                                target: self
                                                                action: @selector(saveButtonTapped)];
    cancelBtn   = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel
                                                                target: self
                                                                action: @selector(cancelButtonTapped)];
    
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
- (void)configureView
{
    DLog();
    
    self.navigationItem.title = NSLocalizedString(@"Cover Letter", nil);
}


//----------------------------------------------------------------------------------------------------------
- (void)updateDataFields
{
    DLog();
    
    // get the cover letter into the view
    if (self.selectedPackage.cover_ltr) {
        self.coverLtrFld.text	= self.selectedPackage.cover_ltr;
    } else {
        self.coverLtrFld.text	= @"";
//        [self editButtonTapped];
    }
}


//----------------------------------------------------------------------------------------------------------
- (void)configureDefaultNavBar
{
    DLog();
    
    // Set the buttons.
    self.navigationItem.rightBarButtonItem = editBtn;
    self.navigationItem.leftBarButtonItem  = backBtn;
    
    [self.coverLtrFld setEditable:NO];
}

#pragma mark - UI handlers

//----------------------------------------------------------------------------------------------------------
- (void)editButtonTapped
{
    DLog();
    
    // Set up the navigation item and save button
    self.navigationItem.leftBarButtonItem  = cancelBtn;
    self.navigationItem.rightBarButtonItem = saveBtn;
    
    // Enable the fields for editing
    [self.coverLtrFld setEditable: YES];
    
    // Start an undo group...it will either be commited in saveButtonTapped or
    //    undone in cancelButtonTapped
    [[self.managedObjectContext undoManager] beginUndoGrouping];
    [self.coverLtrFld becomeFirstResponder];
}


//----------------------------------------------------------------------------------------------------------
- (void)saveButtonTapped
{
    DLog();
    
    // Save the changes
    self.selectedPackage.cover_ltr    = self.coverLtrFld.text;
    
    [[self.managedObjectContext undoManager] endUndoGrouping];
    
    [kAppDelegate saveContext: [self.fetchedResultsController managedObjectContext]];
    
    // Cleanup the undoManager
    [[self.managedObjectContext undoManager] removeAllActionsWithTarget:self];
    // ...and reset the UI defaults
    [self configureDefaultNavBar];
    [self resetView];
}


//----------------------------------------------------------------------------------------------------------
- (void)cancelButtonTapped
{
    DLog();
    
    // Undo any changes the user has made
    [[self.managedObjectContext undoManager] setActionName:OCRUndoActionName];
    [[self.managedObjectContext undoManager] endUndoGrouping];
    
    if ([[self.managedObjectContext undoManager] canUndo]) {
        [[self.managedObjectContext undoManager] undoNestedGroup];
    }
    
    // Cleanup the undoManager
    [[self.managedObjectContext undoManager] removeAllActionsWithTarget: self];
    // ...and reset the UI defaults
    self.coverLtrFld.text    = self.selectedPackage.cover_ltr;
    [self updateDataFields];
    [self configureDefaultNavBar];
    [self resetView];
}

#pragma mark - Keyboard handlers

//----------------------------------------------------------------------------------------------------------
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
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    DLog();
    
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    
    self.coverLtrFld.contentInset = contentInsets;
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
- (void)resetView
{
    DLog();
    
    [self.scrollView setContentOffset: CGPointZero
                             animated: YES];
}


//----------------------------------------------------------------------------------------------------------
- (void)reloadFetchedResults:(NSNotification*)note
{
    DLog();
    
    [super reloadFetchedResults: note];
    [self updateDataFields];
}

@end
