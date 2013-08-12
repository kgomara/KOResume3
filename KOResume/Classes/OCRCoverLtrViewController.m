//
//  OCRCoverLtrViewController.m
//  KOResume
//
//  Created by Kevin O'Mara on 8/11/13.
//  Copyright (c) 2013 O'Mara Consulting Associates. All rights reserved.
//

#import "OCRCoverLtrViewController.h"

@interface OCRCoverLtrViewController ()
{
@private
    UIBarButtonItem     *backBtn;
    UIBarButtonItem     *editBtn;
    UIBarButtonItem     *saveBtn;
    UIBarButtonItem     *cancelBtn;
}

- (void)updateDataFields;
- (void)configureDefaultNavBar;
- (void)resetView;
- (BOOL)saveMoc:(NSManagedObjectContext *)moc;

@end

@implementation OCRCoverLtrViewController

@synthesize selectedPackage             = _selectedPackage;
@synthesize managedObjectContext        = __managedObjectContext;
@synthesize fetchedResultsController    = __fetchedResultsController;

@synthesize scrollView                  = _scrollView;
@synthesize coverLtrFld                 = _coverLtrFld;

#pragma mark - Life Cycle methods

//----------------------------------------------------------------------------------------------------------
- (void)viewDidLoad
{
    DLog();
    
    [super viewDidLoad];
	
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
    
    [self configureDefaultNavBar];
    
    // Register for iCloud notifications
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(reloadFetchedResults:)
                                                 name: KOApplicationDidMergeChangesFrom_iCloudNotification
                                               object: nil];
}

//----------------------------------------------------------------------------------------------------------
- (void)viewDidUnload
{
    DLog();
    
    // Remove all observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.scrollView             = nil;
    self.coverLtrFld            = nil;
    
    [super viewDidUnload];
}


//----------------------------------------------------------------------------------------------------------
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
    ALog();
}


//----------------------------------------------------------------------------------------------------------
- (void)viewWillDisappear:(BOOL)animated
{
    DLog();
    
    // Save any changes
    [self saveMoc: self.managedObjectContext];
}


//----------------------------------------------------------------------------------------------------------
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


//----------------------------------------------------------------------------------------------------------
- (void)updateDataFields
{
    DLog();
    
    // get the cover letter into the view
	self.coverLtrFld.text	= self.selectedPackage.cover_ltr;
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
}


//----------------------------------------------------------------------------------------------------------
- (void)saveButtonTapped
{
    DLog();
    
    // Save the changes
    self.selectedPackage.cover_ltr    = self.coverLtrFld.text;
    
    [[self.managedObjectContext undoManager] endUndoGrouping];
    
    if (![self saveMoc: [self.fetchedResultsController managedObjectContext]]) {
        ALog(@"Failed to save data");
        NSString* msg = NSLocalizedString(@"Failed to save data.", nil);
        [OCAExtensions showErrorWithMessage: msg];
    }
    
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
    [[self.managedObjectContext undoManager] setActionName:KOUndoActionName];
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
    
    NSError *error = nil;
    
    if (![[self fetchedResultsController] performFetch: &error]) {
        ELog(error, @"Fetch failed!");
        NSString* msg = NSLocalizedString(@"Failed to reload data.", nil);
        [OCAExtensions showErrorWithMessage: msg];
    }
    
    [self updateDataFields];
    
    //    if (note) {
    //        // The notification is on an async thread, so block while the UI updates
    //        [self.managedObjectContext performBlock:^{
    //            [self updateDataFields];
    //        }];
    //    }
}

//----------------------------------------------------------------------------------------------------------
- (BOOL)saveMoc:(NSManagedObjectContext *)moc
{
    DLog();
    
    BOOL result = YES;
    NSError *error = nil;
    
    if (moc) {
        if ([moc hasChanges]) {
            if (![moc save: &error]) {
                ELog(error, @"Failed to save");
                result = NO;
            } else {
                DLog(@"Save successful");
            }
        } else {
            DLog(@"No changes to save");
        }
    } else {
        ALog(@"managedObjectContext is null");
        result = NO;
    }
    
    return result;
}

@end
