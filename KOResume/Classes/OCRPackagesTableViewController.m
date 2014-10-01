//
//  OCRPackagesTableViewController.m
//  KOResume
//
//  Created by Kevin O'Mara on 8/24/14.
//  Copyright (c) 2014 O'Mara Consulting Associates. All rights reserved.
//

#import "OCRPackagesTableViewController.h"
#import "OCRBaseDetailViewController.h"
#import "OCRAppDelegate.h"
#import "OCRCoverLtrViewController.h"
#import "Packages.h"
#import "Resumes.h"
#import <CoreData/CoreData.h>
#import "OCRTableViewHeaderCell.h"

/**
 Manage Packages objects.
 
 It uses a UITableView to display the list of Packages, and dispatches OCRCoverLtrViewController or OCRResumeOverViewController.
 */

#define k_OKButtonIndex     1

@interface OCRPackagesTableViewController ()
{
@private
    /**
     Reference to the cancel button to facilitate swapping buttons between display and edit modes.
     */
    UIBarButtonItem         *cancelBtn;
    
    /**
     Reference to the button available in table edit mode that allows the user to add a package.
     */
    UIButton                *addObjectBtn;

    /**
     A boolean flag to indicate whether the user is editing information or simply viewing.
     */
    BOOL                    isEditing;
    
    /**
     A boolean flag to indicate if any package was deleted.
     */
    BOOL                    packageDeleted;
}

/**
 The popoverController of the for the splitView.
 */
@property (nonatomic, strong) UIPopoverController           *packagesPopoverController;

/**
 The back button for the root popover.
 */
@property (nonatomic, strong) UIBarButtonItem               *rootPopoverButtonItem;

/**
 Reference to the fetchResultsController.
 */
@property (nonatomic, strong) NSFetchedResultsController    *fetchedResultsController;

@end


@implementation OCRPackagesTableViewController

#pragma mark - View lifecycle

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
    
    // Set the App name as the Title in the Navigation bar
    NSString *title = NSLocalizedString(@"Packages", nil);
#ifdef DEBUG
    // Include the version in the title for debug builds
    NSString *version           = [[NSBundle mainBundle] infoDictionary] [@"CFBundleVersion"];
    self.navigationItem.title   = [NSString stringWithFormat: @"%@-%@", title, version];
#else
    self.navigationItem.title   = title;
#endif
    
    // Initialize estimated row height to support dynamic text sizing
    self.tableView.estimatedRowHeight           = kOCRPackagesCellHeight;
    // ...and section header height
    self.tableView.estimatedSectionHeaderHeight = kOCRHeaderCellHeight;
    
    // Set up button items
    cancelBtn   = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel
                                                                target: self
                                                                action: @selector(didPressCancelButton)];
    
    // Set up the defaults in the Navigation Bar
    [self configureDefaultNavBar];

    // Set editing off
    isEditing = NO;
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
    
    [self.tableView setContentOffset:CGPointZero];
    
    // Observe the app delegate telling us when it's finished asynchronously adding the store coordinator
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(reloadFetchedResults:)
                                                 name: kOCRApplicationDidAddPersistentStoreCoordinatorNotification
                                               object: nil];
    
    // ...add an observer for Dynamic Text size changes
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(userTextSizeDidChange:)
                                                 name: UIContentSizeCategoryDidChangeNotification
                                               object: nil];
    
    
    // ...add an observer for asynchronous iCloud merges - not used in this version
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(reloadFetchedResults:)
                                                 name: kOCRApplicationDidMergeChangesFrom_iCloudNotification
                                               object: nil];
    
    // Loop through all the packages writing their debugDescription to the log - useful when debugging
    // ...uncomment when needed
//    for (Packages *aPackage in [self.fetchedResultsController fetchedObjects])
//    {
//        DLog(@"%@", [aPackage debugDescription]);
//    }
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
    // Save any changes
    DLog();
    
    [super viewWillDisappear: animated];
    
    [kAppDelegate saveContext];
    
    // Remove ourself from observing notifications
    [[NSNotificationCenter defaultCenter] removeObserver: self];
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


/*
 There is no configureFieldsForEditing, as OCRPackagesTableViewController only has table cells. All the
 configuring is handled in configureUIForEditing (and of course, configureDefaultNavBar)
 */


//----------------------------------------------------------------------------------------------------------
/**
 Configure the default items for the navigation bar.
 */
- (void)configureDefaultNavBar
{
    DLog();
    
    // Set up the nav bar.
    /*
     The editButtonItem is part of the UITableView "built-ins". It toggles state from Edit to Done - provided
     you implement the setEditing:animated method and call super.
     */
    self.navigationItem.rightBarButtonItem  = self.editButtonItem;
    self.navigationItem.leftBarButtonItem   = nil;
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
    [self.tableView reloadData];
}


#pragma mark - UI handlers

//----------------------------------------------------------------------------------------------------------
/**
 Invoked when the user taps the '+' button in the section header.
 
 @param sender          The UIButton object sending the message.
 */
- (IBAction)didPressAddButton: (id)sender
{
    DLog();
    
    // Set up a UIAlertController to get the user's input
    UIAlertController *alert = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"Enter Package Name", nil)
                                                                   message: nil
                                                            preferredStyle: UIAlertControllerStyleAlert];
    // Add a text field to the alert
    [alert addTextFieldWithConfigurationHandler: ^(UITextField *textField) {
        textField.placeholder = NSLocalizedString(@"Package Name", nil);
    }];
    
    // ...add a cancel action
    [alert addAction: [UIAlertAction actionWithTitle: NSLocalizedString(@"Cancel", nil)
                                               style: UIAlertActionStyleDefault
                                             handler: nil]];
    // ...add an OK action
    /*
     To understand the purpose of declaring the __weak reference to self, see:
     https://developer.apple.com/library/ios/documentation/cocoa/conceptual/ProgrammingWithObjectiveC/WorkingwithBlocks/WorkingwithBlocks.html#//apple_ref/doc/uid/TP40011210-CH8-SW16
     */
    __weak OCRPackagesTableViewController *weakSelf = self;
    [alert addAction: [UIAlertAction actionWithTitle: NSLocalizedString(@"OK", nil)
                                               style: UIAlertActionStyleDefault
                                             handler: ^(UIAlertAction *action) {
                                                 __strong OCRPackagesTableViewController *strongSelf = weakSelf;
                                                 // Get the Package name from the alert and pass it to addPackage
                                                 [strongSelf addPackage: ((UITextField *) alert.textFields[0]).text];
                                             }]];
    
    // ...and present the alert to the user
    [self presentViewController: alert
                       animated: YES
                     completion: nil];
}


//----------------------------------------------------------------------------------------------------------
/**
 Add a new Package object.
 
 @param packageName     The name of the Package to add.
 */
- (void)addPackage: (NSString *)packageName
{
    DLog();
    
    // Insert a new Package into the managed object context
    Packages *package = (Packages *)[NSEntityDescription insertNewObjectForEntityForName: kOCRPackagesEntity
                                                                  inManagedObjectContext: [kAppDelegate managedObjectContext]];
    // Set the name of the Package (provided by the user)
    package.name                  = packageName;
    // ...the created_date to "now"
    package.created_date          = [NSDate date];
    // ...and set its sequence_number to be the last Package
    package.sequence_numberValue  = [[self.fetchedResultsController fetchedObjects] count] + 1;
    
    // Add a Resume for the package
    // First, insert a new Resume into the managed object context
    Resumes *resume  = (Resumes *)[NSEntityDescription insertNewObjectForEntityForName: kOCRResumesEntity
                                                                inManagedObjectContext: [kAppDelegate managedObjectContext]];
    // Set the default name of the resume
    resume.name                   = NSLocalizedString(@"Resume", nil);
    // ...the created_date to "now"
    resume.created_date           = [NSDate date];
    // ...and set its sequence_number to 1 (there can be only 1)
    resume.sequence_numberValue   = 1;
    
    // Set the relationship between the Package and Resume objects
    package.resume                = resume;
    
    // Save the context so the adds are pushed to the persistent store
    [kAppDelegate saveContextAndWait];
    // ...and reload the fetchedResults to bring them into memory
    [self reloadFetchedResults: nil];
    
    // Update the tableView with the new object
    // Construct an indexPath to insert the new object at the end
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow: [[self.fetchedResultsController fetchedObjects] count] - 1
                                                inSection: 0];
    /*
     Insert rows in the receiver at the locations identified by an array of index paths, with an option to
     animate the insertion.
     
     UITableView calls the relevant delegate and data source methods immediately afterwards to get the cells
     and other content for visible cells.
     */
    // Animate the insertion of the new row
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths: @[indexPath]
                          withRowAnimation: UITableViewRowAnimationFade];
    [self.tableView endUpdates];
    // ...and scroll the tableView to the row of the added object
    [self.tableView scrollToRowAtIndexPath: indexPath
                          atScrollPosition: UITableViewScrollPositionBottom
                                  animated: YES];
}


//----------------------------------------------------------------------------------------------------------
/**
 Sets whether the view controller shows an editable view.
 
 Subclasses that use an edit-done button must override this method to change their view to an editable state 
 if editing is YES and a non-editable state if it is NO. This method should invoke super’s implementation 
 before updating its view.
 
 @param editing     If YES, the view controller should display an editable view; otherwise, NO. If YES and one 
                    of the custom views of the navigationItem property is set to the value returned by the 
                    editButtonItem method, the associated navigation controller displays a Done button;     
                    otherwise, an Edit button.
 @param animated    If YES, animates the transition; otherwise, does not.
 */
- (void)setEditing: (BOOL)editing
          animated: (BOOL)animated
{
    DLog(@"editing=%@", editing? @"YES" : @"NO");
    [super setEditing: editing
             animated: animated];
    
    // Configure the UI to represent the editing state we are entering
    [self configureUIForEditing: editing];
    
    if (editing)
    {
        // Start an undo group...it will either be commited here when the User presses Done, or
        //    undone in didPressCancelButton
        [[[kAppDelegate managedObjectContext] undoManager] beginUndoGrouping];
        
        // Set the global flag to indicate no packages have been deleted
        packageDeleted = NO;
    }
    else
    {
        // The user pressed "Done", end the undo group
        [[[kAppDelegate managedObjectContext] undoManager] endUndoGrouping];
        
        // ...save changes to the database
        [kAppDelegate saveContextAndWait];
        
        // ...cleanup the undoManager
        [[[kAppDelegate managedObjectContext] undoManager] removeAllActionsWithTarget: self];
        
        // Set up the default navBar
        [self configureDefaultNavBar];
        
        // Check to see if an object has been deleted
        if (packageDeleted)
        {
            // ...notify any listeners if so
            [self postDeleteNotification];
            // ...and clear the global flag
            packageDeleted = NO;
        }
    }
}


//----------------------------------------------------------------------------------------------------------
/**
 Invoked when the user taps the Cancel button.
 
 * End the undo group on the NSManagedObjectContext.
 * If the undoManager has changes it canUndo, undo them.
 * Cleanup the undoManager.
 * Reset the UI to its non-editing state.
 
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
    
    // ...and reload the fetchedResults to bring them into memory
    [self reloadFetchedResults: nil];
    
    /*
     This may look odd - one usually sees a call to super in a method with the same name. But we need to inform 
     the tableView that we are no longer editing the table.
     */
    [super setEditing: NO
             animated: YES];
    
    // Load the tableView from the (unchanged) packages
    [self.tableView reloadData];
    // ...turn off editing in the UI
    [self configureUIForEditing: NO];
    // ...and set up the default navBar
    [self configureDefaultNavBar];
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
    
    // Set the add button hidden state to the opposite of editable
    [addObjectBtn setHidden: !isEditingMode];
    
    if (isEditingMode)
    {
        // Set up the navigation items and cancel buttons - the Edit button
        //  state is managed by the table view
        self.navigationItem.leftBarButtonItem = cancelBtn;
    }
    else
    {
        // Reset the nav bar defaults
        [self configureDefaultNavBar];
    }
 }

#pragma mark - OCRPackagesCellDelegate methods

//----------------------------------------------------------------------------------------------------------
/**
 Handle the cover letter button.
 
 @param sender  The UIButton pressed.
 */
- (IBAction)didPressCoverLtrButton: (id)sender
{
    // configureCell:atIndexPath sets the tag on the button
    DLog(@"sender = %@", @([(UIButton *)sender tag]));
    
    // Check to see if we're in editMode
    if (isEditing)
    {
        // If we are in edit mode, ignore the tap
        /*
         When possible, I construct if statements as positives. Just a style preference - if you read aloud, it
         is "if is editing" rather than "if not is editing". Many would argue that having an empty true clause is
         just silly. I prefer the way it reads for better understanding, and rely on the compiler to generate
         optimized code.
         */
    }
    else
    {
        // Perform the segue using the identifier in the Storyboard
        [self performSegueWithIdentifier: kOCRCvrLtrSegue
                                  sender: sender];
    }
}


//----------------------------------------------------------------------------------------------------------
/**
 Handle the resume button.
 
 @param sender  The UIButton pressed.
 */
- (IBAction)didPressResumeButton: (id)sender
{
    // configureCell:atIndexPath sets the tag on the button
    DLog(@"sender = %@", @([(UIButton *)sender tag]));
    
    // Check to see if we're in editMode
    if (isEditing)
    {
        // If we are in edit mode, ignore the tap
    }
    else
    {
        // Perform the segue using the identifier in the Storyboard
        [self performSegueWithIdentifier: kOCRResumeSegue
                                  sender: sender];
    }
}

#pragma mark - Table view data source methods

//----------------------------------------------------------------------------------------------------------
/**
 Asks the data source to return the number of sections in the table view.
 
 @param tableView       An object representing the table view requesting this information.
 @return                The number of sections in tableView. The default value is 1.
 */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Get the section count from the fetchedResultsController
    return [[self.fetchedResultsController sections] count];
}


//----------------------------------------------------------------------------------------------------------
/**
 Tells the data source to return the number of rows in a given section of a table view.
 
 @param tableView       The table-view object requesting this information.
 @param section         An index number identifying a section in tableView.
 @return                The number of rows in section.
 */
- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    // Get the number of objects for the section from the fetchedResultsController
    return [[[self.fetchedResultsController sections] objectAtIndex:section] numberOfObjects];
}


//----------------------------------------------------------------------------------------------------------
/**
 Asks the data source to verify that the given row is editable.
 
 @param tableView       The table-view object requesting this information.
 @param indexPath       An index path locating a row in tableView.
 @return                YES to allow editing, NO otherwise,
 */
- (BOOL)    tableView: (UITableView *)tableView
canEditRowAtIndexPath: (NSIndexPath *)indexPath
{
    // Yes if we are in edit mode
    return self.editing;
}


//----------------------------------------------------------------------------------------------------------
/**
 Asks the data source for a cell to insert in a particular location of the table view.
 
 The returned UITableViewCell object is frequently one that the application reuses for performance reasons.
 You should fetch a previously created cell object that is marked for reuse by sending a
 dequeueReusableCellWithIdentifier: message to tableView. Various attributes of a table cell are set automatically
 based on whether the cell is a separator and on information the data source provides, such as for accessory views
 and editing controls.
 
 @param tableView       A table-view object requesting the cell.
 @param indexPath       An index path locating a row in tableView.
 @return                An object inheriting from UITableViewCell that the table view can use for the specified row.
 An assertion is raised if you return nil.
 */
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OCRPackagesCell *cell = [tableView dequeueReusableCellWithIdentifier: kOCRPackagesCellID
                                                            forIndexPath: indexPath];
    
    // Configure the cell.
    [self configureCell: cell
            atIndexPath: indexPath];
    
    return cell;
}


//----------------------------------------------------------------------------------------------------------
/**
 Helper method to configure a cell when asked by the table view.
 
 @param cell            The cell to configure.
 @param indexPath       The indexPath for the cell needed.
 @return                A configured cell.
 */
- (void)configureCell: (OCRPackagesCell *)cell
          atIndexPath: (NSIndexPath *)indexPath
{
    DLog();
    
    Packages *aPackage  = [self.fetchedResultsController objectAtIndexPath:indexPath];
    /*
     Set the tag for the cell and its buttons to the row of the Packages object.
     The tag property is often used to carry identifying information for later use. In our case, we'll use it in the
     button handling routines to know which cover_ltr or resume to segue to.
     */
    cell.tag                = indexPath.row;
    cell.coverLtrButton.tag = indexPath.row;
    cell.resumeButton.tag   = indexPath.row;
    
    cell.title.text         = aPackage.name;
    
    // Set the touchUpInside target of the cover letter button
    [cell.coverLtrButton addTarget: self
                            action: @selector(didPressCoverLtrButton:)
                  forControlEvents: UIControlEventTouchUpInside];
    
    // Set the title and touchUpInside target of the resume button
    [cell.resumeButton setTitle: aPackage.resume.name
                       forState: UIControlStateNormal];
    [cell.resumeButton addTarget: self
                          action: @selector(didPressResumeButton:)
                forControlEvents: UIControlEventTouchUpInside];

    // Make the cell not selectable
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    // ...with no accessory indicator
    cell.accessoryType  = UITableViewCellAccessoryNone;
}


//----------------------------------------------------------------------------------------------------------
/**
 Asks the data source to commit the insertion or deletion of a specified row in the receiver.
 
 When users tap the insertion (green plus) control or Delete button associated with a UITableViewCell object
 in the table view, the table view sends this message to the data source, asking it to commit the change. (If
 the user taps the deletion (red minus) control, the table view then displays the Delete button to get
 confirmation.) The data source commits the insertion or deletion by invoking the UITableView methods
 insertRowsAtIndexPaths:withRowAnimation: or deleteRowsAtIndexPaths:withRowAnimation:, as appropriate.
 
 To enable the swipe-to-delete feature of table views (wherein a user swipes horizontally across a row to
 display a Delete button), you must implement this method.
 
 You should not call setEditing:animated: within an implementation of this method. If for some reason you must,
 invoke it after a delay by using the performSelector:withObject:afterDelay: method.
 
 @param tableView       The table-view object requesting the insertion or deletion.
 @param editingStyle    The cell editing style corresponding to a insertion or deletion requested for the row
 specified by indexPath. Possible editing styles are UITableViewCellEditingStyleInsert
 or UITableViewCellEditingStyleDelete.
 @param indexPath       An index path locating the row in tableView.
 */
- (void)    tableView:(UITableView *)tableView
   commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
    forRowAtIndexPath:(NSIndexPath *)indexPath
{
    DLog();
    
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        // Delete the managed object at the given index path.
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        NSManagedObject *objectToDelete = [self.fetchedResultsController objectAtIndexPath: indexPath];
        [context deleteObject: objectToDelete];
        
        // Save the context so the delete is pushed to the persistent store
        [kAppDelegate saveContextAndWait];
        // ...and reload the fetchedResults to bring them into memory
        [self reloadFetchedResults: nil];
        
        // Delete the row from the table view
        [tableView beginUpdates];
        [tableView deleteRowsAtIndexPaths: @[indexPath]
                         withRowAnimation: UITableViewRowAnimationFade];
        [tableView endUpdates];
        
        // Set the global flag to indicate at least one package is deleted
        packageDeleted = YES;
    }
    else
    {
        ALog(@"Unexpected editingStyle=%d", (int)editingStyle);
    }
}



//----------------------------------------------------------------------------------------------------------
/**
 Tells the data source to move a row at a specific location in the table view to another location.
 
 The UITableView object sends this message to the data source when the user presses the reorder control in fromRow.
 
 @param tableView       The table-view object requesting this action.
 @param fromIndexPath   An index path locating the row to be moved in tableView.
 @param toIndexPath     An index path locating the row in tableView that is the destination of the move.
 */
- (void)    tableView:(UITableView *)tableView
   moveRowAtIndexPath:(NSIndexPath *)fromIndexPath
          toIndexPath:(NSIndexPath *)toIndexPath
{
    DLog();
    
    /*
     We only have one section, so moving between sections can never happen, code is here for safety
     */
    if (fromIndexPath.section != toIndexPath.section)
    {
        // Cannot move between sections
        [kAppDelegate showWarningWithMessage: NSLocalizedString(@"Move between sections is not supported.", nil)
                                      target: self];
        [tableView reloadData];
        return;
    }
    
    NSMutableArray *array = [[self.fetchedResultsController fetchedObjects] mutableCopy];
    
    // Grab the item we're moving.
    NSManagedObject *objectToMove = [[self fetchedResultsController] objectAtIndexPath: fromIndexPath];
    
    // Remove the object we're moving from the array.
    [array removeObject: objectToMove];
    // ...re-insert it at the destination.
    [array insertObject: objectToMove
                   atIndex: [toIndexPath row]];
    
    // All of the objects are now in their correct order.
    // Update each object's sequence_number field by iterating through the array.
    int i = 0;
    for (Packages *package in array)
    {
        [package setSequence_numberValue: i++];
    }
    
    /*
     The user may edit cell contents after a move operation. The updateSourceObjectWithTextField:forTableCell:atIndexPath:
     method expects the table view cells and fetched results to be in the same order, so we must save work in progress
     and reload. (If the user subsequently cancels, the undo manager will back out the saved work.)
     */
    // Save the re-ordered objects
    [kAppDelegate saveContextAndWait];
    // ...and reload the fetchedResults
    [self reloadFetchedResults: nil];
}


#pragma mark - Table view delegate methods

//----------------------------------------------------------------------------------------------------------
/**
 Tells the delegate that a specified row is about to be selected.
 
 This method is not called until users touch a row and then lift their finger; the row isn't selected until 
 then, although it is highlighted on touch-down. You can use UITableViewCellSelectionStyleNone to disable the 
 appearance of the cell highlight on touch-down. This method isn’t called when the table view is in editing 
 mode (that is, the editing property of the table view is set to YES) unless the table view allows selection 
 during editing (that is, the allowsSelectionDuringEditing property of the table view is set to YES).

 We do not want to allow swipe to delete, so we return nil.
 
 @param tableView       A table-view object informing the delegate about the new row selection.
 @param indexPath       An index path locating the new  in tableView.
 @return                An index-path object that confirms or alters the selected row. Return an NSIndexPath
                        object other than indexPath if you want another cell to be selected. Return nil if you 
                        don't want the row selected.
 */
- (NSIndexPath *) tableView: (UITableView *)tableView
   willSelectRowAtIndexPath: (NSIndexPath *)indexPath
{
    DLog();
    
    return nil;
}


//----------------------------------------------------------------------------------------------------------
/**
 Asks the delegate for the height to use for the header of a particular section.
 
 This method allows the delegate to specify section headers with varying heights.
 
 @param tableView       The table-view object requesting this information.
 @param section         An index number identifying a section of tableView .
 @return               A nonnegative floating-point value that specifies the height (in points) of the header
 for section.
 */
- (CGFloat)     tableView: (UITableView *)tableView
 heightForHeaderInSection: (NSInteger)section
{
    DLog();
    
    // The height of the header constant
    return kOCRHeaderCellHeight;
}


//----------------------------------------------------------------------------------------------------------
/**
 Asks the delegate for a view object to display in the header of the specified section of the table view.
 
 The returned object can be a UILabel or UIImageView object, as well as a custom view. This method only works
 correctly when tableView:heightForHeaderInSection: is also implemented.
 
 @param tableView       The table-view object asking for the view object.
 @param section         An index number identifying a section of tableView .
 @return               A view object to be displayed in the header of section .
 */
- (UIView *)    tableView: (UITableView *)tableView
   viewForHeaderInSection: (NSInteger)section
{
    DLog();
    
    OCRTableViewHeaderCell *headerCell = [tableView dequeueReusableCellWithIdentifier: kOCRHeaderCell];
    /*
     There is a bug in UIKit (see https://devforums.apple.com/message/882042#882042) when using UITableViewCell
     as the view for section headers. This has been a common practice throughout the iOS programming community.
     
     I designed section header views in IB as prototype table view cells - specifically OCRTableViewHeaderCell,
     which subclasses UITableViewCell. This provides the benefit of using dequeueReusableCellWithIdentifier:
     to get a view for each section header.
     
     Unfortunately this resulted in "no index path for table cell being reused" errors in the log output when
     inserting new rows. Consequently the content (UILabel and UIButton) disappeared. For whatever reason,
     UITableView gets confused if the section header views are UITableViewCells (or subclasses) instead of
     just regular UIViews.
     
     What finally solved it was making the header view just a subclass of UIView instead of UITableViewCell. I
     still use the prototype cell in IB to lay out the section header view, I simply create a "wrapperView" and
     add the OCRTableViewHeaderCell as a subview.
     */
    UIView *wrapperView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, 320, headerCell.frame.size.height)];
    [wrapperView addSubview:headerCell];
    
    // Set the section dynamic text font, text color, and background color
    [headerCell.sectionLabel setFont:            [UIFont preferredFontForTextStyle: UIFontTextStyleHeadline]];
    [headerCell.sectionLabel setTextColor:       [UIColor blackColor]];
    [headerCell.sectionLabel setBackgroundColor: [UIColor clearColor]];
    
    // Set the text content and save a reference to the add button so they can be
    // shown or hidden whenever the user turns editing mode on or off
    headerCell.sectionLabel.text    = NSLocalizedString(@"Packages", nil);
    addObjectBtn                    = headerCell.addButton;

    // Hide or show the addButton depending on whether we are in editing mode
    [addObjectBtn setHidden: !isEditing];
    
    return wrapperView;
}


#pragma mark - UISplitViewControllerDelegate methods

//----------------------------------------------------------------------------------------------------------
/**
 Asks the delegate whether the first view controller should be hidden for the specified orientation.
 
 The split view controller calls this method only for the first child view controller in its array. The second
 view controller always remains visible regardless of the orientation.
 
 @param svc         The split view controller that owns the first view controller.
 @param vc          The first view controller in the array of view controllers.
 @param orientation The orientation being considered.
 @return            YES if the view controller should be hidden in the specified orientation or NO if it should
 be visible.
 */
- (BOOL)splitViewController: (UISplitViewController *)svc
   shouldHideViewController: (UIViewController *)vc
              inOrientation: (UIInterfaceOrientation)orientation
{
    if (UIInterfaceOrientationIsPortrait(orientation))
    {
        return YES; // if you return NO, it will display side by side, not above.
    }
    
    return NO;
}

//----------------------------------------------------------------------------------------------------------
/**
 Tells the delegate that the specified view controller is about to be hidden.
 
 When the split view controller rotates from a landscape to portrait orientation, it normally hides one of its
 view controllers. When that happens, it calls this method to coordinate the addition of a button to the toolbar
 (or navigation bar) of the remaining custom view controller. If you want the soon-to-be hidden view controller
 to be displayed in a popover, you must implement this method and use it to add the specified button to your
 interface.
 
 @param svc                 The split view controller that owns the specified view controller.
 @param aViewController     The view controller being hidden.
 @param barButtonItem       A button you can add to your toolbar.
 @param aPopoverController  The popover controller that uses taps in barButtonItem to display the specified
 view controller.
 */
- (void)splitViewController: (UISplitViewController*)svc
     willHideViewController: (UIViewController *)aViewController
          withBarButtonItem: (UIBarButtonItem*)barButtonItem
       forPopoverController: (UIPopoverController*)aPopoverController
{
    DLog();
    
    // Keep references to the popover controller and the popover button, and tell the detail view controller to show the button.
    barButtonItem.title             = NSLocalizedString( @"Packages", nil);
    self.packagesPopoverController  = aPopoverController;
    self.rootPopoverButtonItem      = barButtonItem;
    
    /*
     The detail view may be the cover letter - a simple UIViewController, or the resume - a UITabBarController containing several
     aspects of the resume. Figure out which one we have and tell any and all subordinate objects to showRootPopoverButtonItem
     */
    // Let's guess we are doing a resume segue, in which case we have a UITabBarController
    UITabBarController *tabBarController = (svc.viewControllers)[1];
    // Check to see if we have a UITabBarController
    if ([tabBarController isMemberOfClass:[UITabBarController class]])
    {
        // We have a UITabBarController, loop through all its children (which are embedded in UINavigationController objects) and tell them to showRootPopoverButtonItem
        for (UINavigationController *navigationController in tabBarController.childViewControllers)
        {
            // Get the topViewController
            id<SubstitutableDetailViewController> detailViewController = (id)navigationController.topViewController;
            // ...and send it the showRootPopoverButtonItem:withController message
            [detailViewController showRootPopoverButtonItem: _rootPopoverButtonItem
                                             withController: aPopoverController];
        }
    }
    else
    {
        // We have cover letter. Get the UINavigationController's topViewController
        OCRBaseDetailViewController <SubstitutableDetailViewController> *detailViewController;
        detailViewController = (OCRBaseDetailViewController<SubstitutableDetailViewController>*)[(svc.viewControllers)[1] topViewController];
        // ...and send it the showRootPopoverButtonItem:withController message
        [detailViewController showRootPopoverButtonItem: _rootPopoverButtonItem
                                         withController: aPopoverController];
    }
}


//----------------------------------------------------------------------------------------------------------
/**
 Tells the delegate that the specified view controller is about to be shown again.
 
 When the view controller rotates from a portrait to landscape orientation, it shows its hidden view controller
 once more. If you added the specified button to your toolbar to facilitate the display of the hidden view
 controller in a popover, you must implement this method and use it to remove that button.
 
 Nil out references to the popover controller and the popover button, and tell the detail view controller to hide the button.
 
 @param svc                 The split view controller that owns the specified view controller.
 @param aViewController     The view controller being hidden.
 @param button              The button used to display the view controller while it was hidden.
 */
- (void)splitViewController: (UISplitViewController*)svc
     willShowViewController: (UIViewController *)aViewController
  invalidatingBarButtonItem: (UIBarButtonItem *)button
{
    DLog();
    
    /*
     The detail view may be the cover letter - a simple UIViewController, or the resume - a UITabBarController containing several
     aspects of the resume. Figure out which one we have and tell any and all subordinate objects to invalidateRootPopoverButtonItem
     */
    // Let's guess we are doing a resume segue, in which case we have a UITabBarController
    UITabBarController *tabBarController = (svc.viewControllers)[1];
    // Check to see if we have a UITabBarController
    if ([tabBarController isMemberOfClass:[UITabBarController class]])
    {
        // We have a UITabBarController, loop through all its children (which are embedded in UINavigationController objects) and tell them to invalidateRootPopoverButtonItem
        for (UINavigationController *navigationController in tabBarController.childViewControllers)
        {
            // Get the topViewController
            id<SubstitutableDetailViewController> detailViewController = (id)navigationController.topViewController;
            // ...and send it the invalidateRootPopoverButtonItem message
            [detailViewController invalidateRootPopoverButtonItem: _rootPopoverButtonItem];
        }
    }
    else
    {
        OCRBaseDetailViewController <SubstitutableDetailViewController> *detailViewController = (OCRBaseDetailViewController<SubstitutableDetailViewController>*)[(svc.viewControllers)[1] topViewController];
        [detailViewController invalidateRootPopoverButtonItem: _rootPopoverButtonItem];
    }
    self.packagesPopoverController  = nil;
    self.rootPopoverButtonItem      = nil;
}


/**
 Asks the delegate to adjust the primary view controller and to incorporate the secondary view controller into the collapsed interface.
 
 This method is your opportunity to perform any necessary tasks related to the transition to a collapsed interface. After this
 method returns, the split view controller removes the secondary view controller from its viewControllers array, leaving the
 primary view controller as its only child. In your implementation of this method, you might prepare the primary view controller
 for display in a compact environment or you might attempt to incorporate the secondary view controller’s content into the newly
 collapsed interface.
 
 Returning NO tells the split view controller to use its default behavior to try and incorporate the secondary view controller 
 into the collapsed interface. When you return NO, the split view controller calls the collapseSecondaryViewController:forSplitViewController: 
 method of the primary view controller, giving it a chance to do something with the secondary view controller’s content. Most view
 controllers do nothing by default but the UINavigationController class responds by pushing the secondary view controller onto its
 navigation stack.
 
 Returning YES from this method tells the split view controller not to apply any default behavior. You might return YES in cases
 where you do not want the secondary view controller’s content incorporated into the resulting interface.

 @param splitViewController     The split view controller whose interface is collapsing.
 @param secondaryViewController The secondary view controller of the split view interface.
 @param primaryViewController   The primary view controller of the split view interface. If you implement the
                                primaryViewControllerForCollapsingSplitViewController: method in your delegate, this object is the 
                                one returned by that method.
 @return                        NO to let the split view controller try and incorporate the secondary view controller’s content 
                                into the collapsed interface or YES to indicate that you do not want the split view controller to
                                do anything with the secondary view controller.
 */
- (BOOL)splitViewController:(UISplitViewController *)splitViewController
collapseSecondaryViewController:(UIViewController *)secondaryViewController
  ontoPrimaryViewController:(UIViewController *)primaryViewController
{
    DLog();
    
    return YES;
}


#pragma mark - Seque handling

//----------------------------------------------------------------------------------------------------------
/**
 Notifies the view controller that a segue is about to be performed.
 
 The default implementation of this method does nothing. Your view controller overrides this method when it
 needs to pass relevant data to the new view controller. The segue object describes the transition and includes
 references to both view controllers involved in the segue.
 
 Because segues can be triggered from multiple sources, you can use the information in the segue and sender
 parameters to disambiguate between different logical paths in your app. For example, if the segue originated
 from a table view, the sender parameter would identify the table view cell that the user tapped. You could use
 that information to set the data on the destination view controller.
 
 @param segue   The segue object containing information about the view controllers involved in the segue.
 @param sender  The object that initiated the segue. You might use this parameter to perform different actions
 based on which control (or other object) initiated the segue.
 */
- (void)prepareForSegue: (UIStoryboardSegue *)segue
                 sender: (id)sender
{
    DLog();
    /*
     See the comment in - configureCell:atIndexPath: to understand how we are using sender.tag with fetchedResultsController
     
     The sender is one of the buttons in a UICollectionViewCell (not the cell itself). To construct the indexPath
     we use the tag on the UIButton, which is set in configureCell:atIndexPath:
     */
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow: [(UIButton *)sender tag]
                                                inSection: 0];
    if ([[segue identifier] isEqualToString: kOCRCvrLtrSegue])
    {
        Packages *aPackage = [self.fetchedResultsController objectAtIndexPath: indexPath];
        /*
         We want to pass a few data object references to the cover letter controller (discussed in more detail below) - so we
         first get a reference to the cover letter controller, which is embedded in a UINavigationController.
         */
        OCRBaseDetailViewController *cvrLtrController = [(UINavigationController *)[segue destinationViewController] viewControllers][0];
        // Check to see if we have a popover button
        if (_rootPopoverButtonItem != nil)
        {
            // ...if so, have the cvrLtrController show it
            [cvrLtrController showRootPopoverButtonItem:_rootPopoverButtonItem
                                         withController:_packagesPopoverController];
        }
        
        if (self.packagesPopoverController)
        {
            [self.packagesPopoverController dismissPopoverAnimated: YES];
        }
        /*
         A common strategy for passing data between controller objects is to declare public properties in the receiving object
         and have the instantiator set those properties. Here we pass the Package represented by the cell the user tapped.
         
         An alternative strategy for data that is global scope by nature is to set those properties on the UIApplication
         delegate and reference them as [[[UIApplication sharedApplication] delegate] foo_bar]. In our case, there is only one
         managedObjectContext used throughout the app, which is a public property on OCRAppDelegate
         
         I also created a macro (see GlobalMacros.h):
         
         #define kAppDelegate    (OCRAppDelegate *)[[UIApplication sharedApplication] delegate]      // Note it DOES NOT end with a ';'
         
         Thus, in other source files [kAppDelegate managedObjectContext] returns a reference to our managedObjectContext.
         */
        [cvrLtrController setSelectedManagedObject: aPackage];
        [cvrLtrController setBackButtonTitle: NSLocalizedString(@"Packages", nil)];
        [cvrLtrController setFetchedResultsController: self.fetchedResultsController];
    }
    else if ([[segue identifier] isEqualToString: kOCRResumeSegue])
    {
        Packages *aPackage = [self.fetchedResultsController objectAtIndexPath: indexPath];
        /*
         In this case, there is a UITabBarController intermediary container, which contains 3 controller objects, each of
         which is embedded in a UINavigationController.
         */
        UITabBarController *tabBarController = (UITabBarController *)[segue destinationViewController];
        for (UINavigationController *navigationController in tabBarController.viewControllers)
        {
            OCRBaseDetailViewController *detailViewController = [navigationController viewControllers][0];
            // Check to see if we have a popover button
            if (_rootPopoverButtonItem != nil)
            {
                // ...if so, have the detail view show it
                [detailViewController showRootPopoverButtonItem: _rootPopoverButtonItem
                                                 withController: _packagesPopoverController];
            }
            [detailViewController setSelectedManagedObject: aPackage.resume];
            [detailViewController setBackButtonTitle: NSLocalizedString(@"Packages", nil)];
            [detailViewController setFetchedResultsController: self.fetchedResultsController];
        }
        
        if (self.packagesPopoverController)
        {
            [self.packagesPopoverController dismissPopoverAnimated: YES];
        }
    }
}

#pragma mark - Fetched Results Controller

//----------------------------------------------------------------------------------------------------------
/**
 Singleton method to retrieve the fetchedResultsController, instantiating it if necessary.
 
 @return    An initialized NSFetchedResultsController.
 */
- (NSFetchedResultsController *)fetchedResultsController
{
    DLog();
    
    if (_fetchedResultsController != nil)
    {
        return _fetchedResultsController;
    }
    
    // Create the fetch request for the entity
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity  = [NSEntityDescription entityForName: kOCRPackagesEntity
                                               inManagedObjectContext: [kAppDelegate managedObjectContext]];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number
    [fetchRequest setFetchBatchSize: 25];
    
    // Sort by package sequence_number
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: kOCRSequenceNumberAttributeName
                                                                   ascending: YES];
    NSArray *sortDescriptors = @[sortDescriptor];
    [fetchRequest setSortDescriptors: sortDescriptors];
    
    // Alloc and initialize the controller
    /*
     By setting sectionNameKeyPath to nil, we are stating we want everything in a single section
     */
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest: fetchRequest
                                                                        managedObjectContext: [kAppDelegate managedObjectContext]
                                                                          sectionNameKeyPath: nil
                                                                                   cacheName: nil];
    // Set the delegate to self
    _fetchedResultsController.delegate = self;
    
    // ...and start fetching results
    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error])
    {
        /*
         This is a case where something serious has gone wrong. Let the user know and try to give them some options that might actually help.
         I'm providing my direct contact information in the hope I can help the user and avoid a bad review.
         */
        ELog(error, @"Unresolved error");
        [kAppDelegate showErrorWithMessage: NSLocalizedString(@"Could not read the database. Try quitting the app. If that fails, try deleting KOResume and restoring from iCloud or iTunes backup. Please contact the developer by emailing kevin@omaraconsultingassoc.com", nil)
                                    target: self];
    }
    
    return _fetchedResultsController;
}    


//----------------------------------------------------------------------------------------------------------
/**
 Loads a fresh copy of fetched results.
 
 This method is called when the underlying data in the persistent store (may have) changed.
 
 @param note    The NSNotification object associated with the event that triggered the need to reload.
 */
- (void)reloadFetchedResults: (NSNotification*)note
{
    DLog();
    
    /*
     Because the app delegate now loads the NSPersistentStore into the NSPersistentStoreCoordinator asynchronously
     the NSManagedObjectContext is set up before any persistent stores are registered we need to fetch again
     after the persistent store is loaded
     */
    
    NSError *error = nil;
    
    if (![[self fetchedResultsController] performFetch: &error])
    {
        ELog(error, @"Fetch failed!");
        NSString* msg = NSLocalizedString( @"Failed to reload data.", nil);
        [kAppDelegate showWarningWithMessage: msg
                                      target: self];
    }
    else
    {
        // Get the fetchedObjects re-loaded
        [self.fetchedResultsController fetchedObjects];
    }
}


//----------------------------------------------------------------------------------------------------------
/**
 Post a notification informing listeners that a package has been deleted.
 
 Listeners should register for this notication and take appropriate action to ensure orphaned child objects are not
 updated inadvertently.
 */
- (void)postDeleteNotification
{
    DLog();
    // Post a notification to inform interested objects - i.e., the view controllers that a package has been deleted
    NSNotification *deleteNotification = [NSNotification notificationWithName: kOCRMocDidDeletePackageNotification
                                                                       object: nil
                                                                     userInfo: nil];
    
    [[NSNotificationCenter defaultCenter] postNotification: deleteNotification];
    
}


@end
