//
//  OCRResumeJobsTableViewController.m
//  KOResume
//
//  Created by Kevin O'Mara on 8/7/14.
//  Copyright (c) 2014 O'Mara Consulting Associates. All rights reserved.
//

#import "OCRResumeJobsTableViewController.h"
#import "OCRAppDelegate.h"
#import "Resumes.h"
#import "Jobs.h"
#import "OCRJobsViewController.h"
#import "OCRTableViewHeaderCell.h"

/*
 Manage the table view (list) of the jobs associated with a Resume object.
 */


@interface OCRResumeJobsTableViewController ()
{
@private
    /**
     Reference to the cancel button to facilitate swapping buttons between display and edit modes.
     */
    UIBarButtonItem     *cancelBtn;
    
    /**
     Reference to the button available in table edit mode that allows the user to add a Job.
     */
    UIButton            *addJobBtn;

    /**
     A boolean flag to indicate whether the user is editing information or simply viewing.
     */
    BOOL                isEditing;

    /**
     Convenience reference to the managed object instance we are managing.
     
     OCRBaseDetailViewController, of which this is a subclass, declares a selectedManagedObject. We make this
     type-correct reference merely for convenience.
     */
    Resumes             *selectedResume;
}

/**
 Reference to the fetchResultsController.
 */
@property (nonatomic, strong) NSFetchedResultsController    *jobsFetchedResultsController;

@end


@implementation OCRResumeJobsTableViewController

//@synthesize tableView = _tableView;

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
    
    // For convenience, make a type-correct reference to the Resume we're working on
    selectedResume = (Resumes *)self.selectedManagedObject;
    
    // Set up button items
    cancelBtn   = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel
                                                                target: self
                                                                action: @selector(didPressCancelButton)];
    
    // ...and the NavBar
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
- (void)viewWillAppear:(BOOL)animated
{
    DLog();
    
    [super viewWillAppear: animated];
    
    // Observe the app delegate telling us when it's finished asynchronously adding the store coordinator
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(reloadFetchedResults:)
                                                 name: kOCRApplicationDidAddPersistentStoreCoordinatorNotification
                                               object: nil];
    
    // ...and an observer for package object deletion
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(packageWasDeleted:)
                                                 name: kOCRMocDidDeletePackageNotification
                                               object: nil];
}


//----------------------------------------------------------------------------------------------------------
/*
 Notice there is no viewWillDisappear.
 
 This class inherits viewWillDisappear from the base class, which calls removeObserver and saves the context; hence
 we have no need to implement the method in this class. Similarly, we don't implement didReceiveMemoryWarning.
 */


//----------------------------------------------------------------------------------------------------------
/**
 Enables or disables all the UI text fields for editing.
 
 As a resume app, a major Use Case is the user sharing his/her experience by passing the iOS device around.
 To avoid accidently changing information, the app defaults to non-editable and there is an explicit Edit
 button when the user wants to change information. This method sets the enabled state as appropriate and also
 changes the background color to make "edit mode" more visually distinct.
 
 @param editable    A BOOL that determines whether the fields should be enabled for editing - or not.
 */
- (void)configureFieldsForEditing: (BOOL)editable
{
    DLog();
    
    [self.tableView reloadRowsAtIndexPaths: [self.tableView indexPathsForVisibleRows]
                          withRowAnimation: UITableViewRowAnimationNone];
}


//----------------------------------------------------------------------------------------------------------
/**
 Configure the default items for the navigation bar.
 */
- (void)configureDefaultNavBar
{
    DLog();
    
    // Set the title
    NSString *title = NSLocalizedString(@"Resume", nil);
    
    /*
     In iOS8 Apple has bridged much of the gap between iPhone and iPad. However some differences persist.
     */
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        /*
         Our view controller is embedded in a UITabBarController that owns the navigation bar. So to update
         the title and buttons we must reference the navigation items in our tabBarController.
         */
        // Set the title
        self.tabBarController.navigationItem.title = title;
        // ...and edit button
        self.tabBarController.navigationItem.rightBarButtonItems = @[self.editButtonItem];
    }
    else
    {
        self.navigationItem.title               = title;
        self.navigationItem.rightBarButtonItems = @[self.editButtonItem];
    }
    
    // Set table editing off
    [self.tableView setEditing: NO];
    
    // ...and hide the add buttons
    [addJobBtn setHidden: YES];
}


#pragma mark - OCRDetailViewProtocol delegates

//----------------------------------------------------------------------------------------------------------
/**
 Configure the view items.
 */
- (void)configureView
{
    DLog();
    
    // As a simple UITableView, there is nothing to do. Implemented because the OCRDetailViewProtocol requires it.
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

/*
 In iOS8, UITableView handles dynamic text - provided you use autolayout. If you have custom cells, be sure
 to set their estimated size (typically in viewDidLoad:), see OCRPackagesTableViewController.
 */

#pragma mark - UI handlers

//----------------------------------------------------------------------------------------------------------
/**
 Invoked when the user taps the '+' button in the section header
 */
- (IBAction)didPressAddButton: (id)sender
{
    DLog();
    
    // Set up a UIAlertController to get the user's input
    UIAlertController *alert = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"Enter Job Name", nil)
                                                                   message: nil
                                                            preferredStyle: UIAlertControllerStyleAlert];
    // Add a text field to the alert
    [alert addTextFieldWithConfigurationHandler: ^(UITextField *textField) {
        textField.placeholder = NSLocalizedString(@"Job Name", nil);
    }];
    
    // ...add a cancel action
    [alert addAction: [UIAlertAction actionWithTitle: NSLocalizedString(@"Cancel", nil)
                                               style: UIAlertActionStyleDefault
                                             handler: nil]];
    // ...and an OK action
    /*
     To understand the purpose of declaring the __weak reference to self, see:
     https://developer.apple.com/library/ios/documentation/cocoa/conceptual/ProgrammingWithObjectiveC/WorkingwithBlocks/WorkingwithBlocks.html#//apple_ref/doc/uid/TP40011210-CH8-SW16
     */
    __weak OCRResumeJobsTableViewController *weakself = self;
    [alert addAction: [UIAlertAction actionWithTitle: NSLocalizedString(@"OK", nil)
                                               style: UIAlertActionStyleDefault
                                             handler: ^(UIAlertAction *action) {
                                                 __strong OCRResumeJobsTableViewController *strongSelf = weakself;
                                                 // Get the Job name from the alert and pass it to addJob
                                                 [strongSelf addJob: ((UITextField *) alert.textFields[0]).text];
                                             }]];
    
    // ...and present the alert to the user
    [self presentViewController: alert
                       animated: YES
                     completion: nil];
}


//----------------------------------------------------------------------------------------------------------
/**
 Add a Jobs entity for this resume.
 */
- (void)addJob: (NSString *)jobName
{
    DLog();
    
    // Insert a new Jobs entity into the managedObjectContext
    Jobs *job = (Jobs *)[NSEntityDescription insertNewObjectForEntityForName: kOCRJobsEntity
                                                      inManagedObjectContext: [kAppDelegate managedObjectContext]];
    
    // Set the name to the value the user provided in the prompt
    job.name                    = jobName;
    // ...the created timestamp to now
    job.created_date            = [NSDate date];
    // ...the resume link to the resume we are managing
    job.resume                  = selectedResume;
    // ...and set its sequence_number to be the last Package
    job.sequence_numberValue    = [[self.jobsFetchedResultsController fetchedObjects] count] + 1;
    
    // Save the context so the adds are pushed to the persistent store
    [kAppDelegate saveContextAndWait];
    // ...and reload the fetchedResults to bring them into memory
    [self reloadFetchedResults: nil];
    
    // Update the tableView with the new object
    // Construct an indexPath to insert the new object at the end
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow: [[self.jobsFetchedResultsController fetchedObjects] count] - 1
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
    // ...and scroll the tableView back to the top to ensure the user can see the result of adding the Job
    [self.tableView scrollToRowAtIndexPath: indexPath
                          atScrollPosition: UITableViewScrollPositionBottom
                                  animated: YES];
}


//----------------------------------------------------------------------------------------------------------
/**
 Sets whether the view controller shows an editable view.
 
 Subclasses that use an edit-done button must override this method to change their view to an editable state
 if editing is YES and a non-editable state if it is NO. This method should invoke super’s implementation
 before updating its view.
 
 @param editing     If YES, the view controller should display an editable view; otherwise, NO. If YES and one
                    of the custom views of the navigationItem property is set to the value returned by the
                    editButtonItem method, the associated navigation controller displays a Done button;
                    otherwise, an Edit button.
 @param animate     If YES, animates the transition; otherwise, does not.
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
    }
    else
    {
        // The user pressed "Done", end the undo group
        [[[kAppDelegate managedObjectContext] undoManager] endUndoGrouping];
        
        // ...save changes to the database
        [kAppDelegate saveContextAndWait];
        
        // ...cleanup the undoManager
        [[[kAppDelegate managedObjectContext] undoManager] removeAllActionsWithTarget: self];
        
        // Reload the fetched results
        [self reloadFetchedResults: nil];
        
        // Set up the default navBar
        [self configureDefaultNavBar];
    }
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
    // ...and turn off editing in the UI
    [self configureUIForEditing: NO];
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
    
    // Set the add button hidden state (hidden should be the boolean opposite of isEditingMode)
    [addJobBtn setHidden: !isEditingMode];
    
    // ...enable/disable resume fields
    [self configureFieldsForEditing: isEditingMode];
    
    if (isEditingMode)
    {
        /*
         In iOS8 Apple has bridged much of the gap between iPhone and iPad. However some differences persist.
         In this case, embedding in a tabBarController is slightly different.
         */
        if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        {
            /*
             Our view controller is embedded in a UITabBarController that owns the navigation bar. So to update
             the title and buttons we must reference the navigation items in our tabBarController.
             */
            // Set the edit button
            self.tabBarController.navigationItem.rightBarButtonItems = @[self.editButtonItem, cancelBtn];
        }
        else
        {
            self.navigationItem.rightBarButtonItems = @[self.editButtonItem, cancelBtn];
        }
    }
    else
    {
        // Reset the nav bar defaults
        [self configureDefaultNavBar];
    }
}


#pragma mark - Table view datasource methods

//----------------------------------------------------------------------------------------------------------
/**
 Asks the data source to return the number of sections in the table view.
 
 @param tableView       An object representing the table view requesting this information.
 @return                The number of sections in tableView. The default value is 1.
 */
- (NSInteger)numberOfSectionsInTableView: (UITableView *)tableView
{
    // Get the section count from the jobsFetchedResultsController
    return [[self.jobsFetchedResultsController sections] count];
}


//----------------------------------------------------------------------------------------------------------
/**
 Tells the data source to return the number of rows in a given section of a table view.
 
 @param tableView       The table-view object requesting this information.
 @param section         An index number identifying a section in tableView.
 @return                The number of rows in section.
 */
- (NSInteger)tableView: (UITableView *)tableView
 numberOfRowsInSection: (NSInteger)section
{
    // Get the number of objects for the section from the jobsFetchedResultsController
    return [[[self.jobsFetchedResultsController sections] objectAtIndex: section] numberOfObjects];
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
- (UITableViewCell *)tableView: (UITableView *)tableView
         cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
    DLog();
    
    //  Configure a jobs cell
    UITableViewCell *cell = [self tableView: tableView
                       jobsCellForIndexPath: indexPath];
    
    return cell;
}

//----------------------------------------------------------------------------------------------------------
/**
 Configure a jobs cell for the resume.
 
 @param cell        A cell to configure.
 @param indexPath   The indexPath of the section and row the cell represents.
 @return            A configured table view cell.
 */
- (UITableViewCell *)tableView: (UITableView *)tableView
          jobsCellForIndexPath: (NSIndexPath *)indexPath
{
    DLog();
    
    // Get a Subtitle cell
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: kOCRSubtitleTableCell];
    
    // ...and the Job object the cell will represent
    Jobs *job = [self.jobsFetchedResultsController objectAtIndexPath: indexPath];
    
    // ...set the title text content and dynamic text font
    cell.textLabel.text         = job.name;
    cell.textLabel.font         = [UIFont preferredFontForTextStyle: UIFontTextStyleHeadline];
    // ...the detail text content and dynamic text font
    cell.detailTextLabel.text   = job.title;
    cell.detailTextLabel.font   = [UIFont preferredFontForTextStyle: UIFontTextStyleSubheadline];
    // ...and the accessory disclosure indicator
    cell.accessoryType          = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
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
- (void) tableView: (UITableView *)tableView
commitEditingStyle: (UITableViewCellEditingStyle)editingStyle
 forRowAtIndexPath: (NSIndexPath *)indexPath
{
    DLog();
    
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        // Delete the managed object at the given index path.
        NSManagedObjectContext *context = [self.jobsFetchedResultsController managedObjectContext];
        Jobs *jobToDelete               = [self.jobsFetchedResultsController objectAtIndexPath: indexPath];
        [context deleteObject: jobToDelete];
        
        // Save the context so the delete is pushed to the persistent store
        [kAppDelegate saveContextAndWait];
        // ...and reload the fetchedResults to bring them into memory
        [self reloadFetchedResults: nil];
        
        // Delete the row from the table view
        [self.tableView beginUpdates];
        [tableView deleteRowsAtIndexPaths: @[indexPath]
                         withRowAnimation: UITableViewRowAnimationFade];
        [self.tableView endUpdates];
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
- (void) tableView: (UITableView *)tableView
moveRowAtIndexPath: (NSIndexPath *)fromIndexPath
       toIndexPath: (NSIndexPath *)toIndexPath
{
    DLog();
    
    /*
     We only have one section, so moving between sections can never happen, code is here for safety
     */
    if (fromIndexPath.section != toIndexPath.section)
    {
        // Cannot move between sections
        [kAppDelegate showWarningWithMessage: NSLocalizedString(@"Sorry, move between sections not allowed.", nil)
                                      target: self];
        [self.tableView reloadData];
        return;
    }
    
    NSMutableArray *jobs = [[self.jobsFetchedResultsController fetchedObjects] mutableCopy];
    
    // Grab the item we're moving.
    Jobs *movingJob = [self.jobsFetchedResultsController objectAtIndexPath: fromIndexPath];
    
    // Remove the object we're moving from the array.
    [jobs removeObject: movingJob];
    // ...re-insert it at the destination.
    [jobs insertObject: movingJob
               atIndex: [toIndexPath row]];
    
    // All of the objects are now in their correct order.
    // Update each object's sequence_number field by iterating through the array.
    int i = 1;
    for (Jobs *job in jobs)
    {
        [job setSequence_numberValue: i++];
    }
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
 Tells the delegate that the specified row is now selected.
 
 The delegate handles selections in this method. One of the things it can do is exclusively assign the check-mark
 image (UITableViewCellAccessoryCheckmark) to one row in a section (radio-list style). This method isn’t called
 when the editing property of the table is set to YES (that is, the table view is in editing mode). See "Managing
 Selections" in Table View Programming Guide for iOS for further information (and code examples) related to this method.
 
 @param tableView       A table-view object informing the delegate about the new row selection.
 @param indexPath       An index path locating the new selected row in tableView.
 */
- (void)        tableView: (UITableView *)tableView
  didSelectRowAtIndexPath: (NSIndexPath *)indexPath
{
    DLog();
    
    // Segue to the job
    [self performSegueWithIdentifier: kOCRJobsSegue
                              sender: [self.jobsFetchedResultsController objectAtIndexPath: indexPath]];
    
    // Clear the selection highlight
    [tableView deselectRowAtIndexPath: indexPath
                             animated: YES];
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
    headerCell.sectionLabel.text    = NSLocalizedString(@"Jobs", nil);
    addJobBtn                       = headerCell.addButton;
    
    // Hide or show the addButton depending on whether we are in editing mode
    [addJobBtn setHidden: !isEditing];
    
    return wrapperView;
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
 @param sender  The object that initiated the segue. In this case, we set sender to be the Job or Education
 object represented by the selected tableViewCell.
 based on which control (or other object) initiated the segue.
 */
- (void)prepareForSegue: (UIStoryboardSegue *)segue
                 sender: (id)sender
{
    DLog();
    
    if ([[segue identifier] isEqualToString: kOCRJobsSegue])
    {
        OCRJobsViewController *detailViewController = segue.destinationViewController;
        [detailViewController setSelectedManagedObject: (Jobs *)sender];
        [detailViewController setBackButtonTitle: selectedResume.name];
//        [detailViewController setFetchedResultsController: self.jobsFetchedResultsController];
    }
}


#pragma mark - Fetched Results Controller

//----------------------------------------------------------------------------------------------------------
/**
 Singleton method to retrieve the jobsFetchedResultsController, instantiating it if necessary.
 
 @return    An initialized NSFetchedResultsController.
 */
- (NSFetchedResultsController *)jobsFetchedResultsController
{
    DLog();
    
    if (_jobsFetchedResultsController != nil)
    {
        return _jobsFetchedResultsController;
    }
    
    // Create the fetch request for the entity
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity  = [NSEntityDescription entityForName: kOCRJobsEntity
                                               inManagedObjectContext: [kAppDelegate managedObjectContext]];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number
    [fetchRequest setFetchBatchSize: 25];
    
    // Sort by package sequence_number
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: kOCRSequenceNumberAttributeName
                                                                   ascending: YES];
    NSArray *sortDescriptors = @[sortDescriptor];
    [fetchRequest setSortDescriptors: sortDescriptors];
    
    // Create predicate to select the jobs for the selected resume
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"resume == %@", selectedResume];
    [fetchRequest setPredicate: predicate];
    
    // Alloc and initialize the controller
    /*
     By setting sectionNameKeyPath to nil, we are stating we want everything in a single section
     */
    self.jobsFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest: fetchRequest
                                                                        managedObjectContext: [kAppDelegate managedObjectContext]
                                                                          sectionNameKeyPath: nil
                                                                                   cacheName: nil];
    // Set the delegate to self
    _jobsFetchedResultsController.delegate = self;
    
    // ...and start fetching results
    NSError *error = nil;
    if (![self.jobsFetchedResultsController performFetch:&error])
    {
        /*
         This is a case where something serious has gone wrong. Let the user know and try to give them some options that might actually help.
         I'm providing my direct contact information in the hope I can help the user and avoid a bad review.
         */
        ELog(error, @"Unresolved error");
        [kAppDelegate showErrorWithMessage: NSLocalizedString(@"Could not read the database. Try quitting the app. If that fails, try deleting KOResume and restoring from iCloud or iTunes backup. Please contact the developer by emailing kevin@omaraconsultingassoc.com", nil)
                                    target: self];
    }
    
    return _jobsFetchedResultsController;
}


//----------------------------------------------------------------------------------------------------------
/**
 Reloads the fetched results
 
 Invoked by notification when the underlying data objects may have changed
 
 @param aNote the NSNotification describing the changes (ignored)
 */
- (void)reloadFetchedResults: (NSNotification*)aNote
{
    DLog();
    
    NSError *error = nil;
    
    if (![self.jobsFetchedResultsController performFetch: &error])
    {
        ELog(error, @"Fetch failed!");
        NSString* msg = NSLocalizedString( @"Failed to reload data after syncing with iCloud.", nil);
        [kAppDelegate showErrorWithMessage: msg
                                    target: self];
    }
    else
    {
        // Get the fetchedObjects re-loaded
        [self.jobsFetchedResultsController fetchedObjects];
    }
    
    if (selectedResume.isDeleted)
    {
        // Need to display a message
        [kAppDelegate showWarningWithMessage: @"Resume deleted."
                                      target: self];
    }
}



@end
