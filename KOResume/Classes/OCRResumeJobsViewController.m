//
//  OCRResumeJobsViewController.m
//  KOResume
//
//  Created by Kevin O'Mara on 8/7/14.
//  Copyright (c) 2014 O'Mara Consulting Associates. All rights reserved.
//

#import "OCRResumeJobsViewController.h"
#import "OCRAppDelegate.h"
#import "Resumes.h"
#import "Jobs.h"
#import "OCRJobsViewController.h"

#define k_OKButtonIndex     1

@interface OCRResumeJobsViewController ()
{
@private
    /**
     Reference to the back button to facilitate swapping buttons between display and edit modes.
     */
    UIBarButtonItem     *backBtn;
    
    /**
     Reference to the edit button to facilitate swapping buttons between display and edit modes.
     */
    UIBarButtonItem     *editBtn;
    
    /**
     Reference to the save button to facilitate swapping buttons between display and edit modes.
     */
    UIBarButtonItem     *saveBtn;
    
    /**
     Reference to the cancel button to facilitate swapping buttons between display and edit modes.
     */
    UIBarButtonItem     *cancelBtn;
    
    /**
     Reference to the button available in table edit mode that allows the user to add a Job.
     */
    UIButton            *addJobBtn;
}

/**
 Array used to keep the Resume's job objects sorted by sequence_number.
 */
@property (nonatomic, strong)   NSMutableArray      *jobArray;

/**
 Variable used to store the new entity name entered when the user adds a job or education object.
 */
@property (nonatomic, strong)   NSString            *nuEntityName;

/**
 Convenience reference to the managed object instance we are managing.
 
 OCRBaseDetailViewController, of which this is a subclass, declares a selectedManagedObject. We make this
 type-correct reference merely for convenience.
 */
@property (nonatomic, strong)   Resumes             *selectedResume;

/**
 A boolean flag to indicate whether the user is editing information or simply viewing.
 */
@property (nonatomic, assign, getter=isEditing) BOOL editing;

@end

@implementation OCRResumeJobsViewController

@synthesize tableView = _tableView;

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
    self.selectedResume = (Resumes *)self.selectedManagedObject;
    
    self.view.backgroundColor = [UIColor clearColor];
    
    // Set the default button title
    self.backButtonTitle        = NSLocalizedString(@"Resume", nil);
    
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
    
    // ...and the NavBar
    [self configureDefaultNavBar];
    
    // Set editing off
    self.editing = NO;
    
    // Sort the job table by sequence_number
    [self sortTables];
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
    
//    self.fetchedResultsController.delegate = self;
    [self.tableView reloadData];
    
    [self configureDefaultNavBar];
    [self configureView];
    [self setFieldsEditable: NO];
    
    // Register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(keyboardWillShow:)
                                                 name: UIKeyboardWillShowNotification
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
    /*
     This class inherits viewWillDisappear from the base class, which calls removeObserver
     */
}


//----------------------------------------------------------------------------------------------------------
/**
 Sort the job and education arrays into sequence_number order.
 */
- (void)sortTables
{
    DLog();
    
    // Sort jobs in the order they should appear in the table
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: kOCRSequenceNumberAttributeName
                                                                   ascending: YES];
    NSArray *sortDescriptors    = @[sortDescriptor];
    self.jobArray               = [NSMutableArray arrayWithArray: [_selectedResume.job sortedArrayUsingDescriptors: sortDescriptors]];
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
    
    [self.tableView reloadRowsAtIndexPaths:[self.tableView indexPathsForVisibleRows]
                          withRowAnimation:UITableViewRowAnimationNone];
}


//----------------------------------------------------------------------------------------------------------
/**
 Configure the default items for the navigation bar.
 */
- (void)configureDefaultNavBar
{
    DLog();
    
    // Set the title
    self.navigationItem.title = NSLocalizedString(@"Resume", nil);
    
    // Set up the navigation items and save/cancel buttons
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        self.navigationItem.rightBarButtonItems = @[editBtn];
    }
    else
    {
        self.navigationItem.leftBarButtonItem  = backBtn;
        self.navigationItem.rightBarButtonItem = editBtn;
    }
    
    // Set table editing off
    [self.tableView setEditing: NO];
    
    // ...and hide the add buttons
    [addJobBtn       setHidden: YES];
}


#pragma mark - OCRDetailViewProtocol delegates

//----------------------------------------------------------------------------------------------------------
/**
 Configure the view items.
 */
- (void)configureView
{
    DLog();
    
    // Use the information in the selected managed object to update the UI fields
//    [self loadViewFromSelectedObject];
}


#pragma mark - UITextKit handlers

//----------------------------------------------------------------------------------------------------------
/**
 Handle the notification that the user changed the dynamic text size.
 
 This method is invoked by notification when the user changes the text size. We apply a new UIFont instance
 to each label, text field, and text view that uses dynamic font styles.
 
 @param aNotification   The NSNotification associated with the event.
 */
- (void)userTextSizeDidChange: (NSNotification *)aNotification
{
    DLog();
    
    /*
     Reloading the table will cause the datasource methods to be called. The table controller will call
     tableView:cellForRowAtIndexPath: which applies the new fonts and tableView:heightForRowAtIndexPath: calculates
     row heights given the new text size. Note this approach requires fonts to be set in cellForRowAtIndexPath:
     and not in an init method.
     */
    [self.tableView reloadData];
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
    [self setUIWithEditing: YES];
    
    // Start an undo group...it will either be commited in didPressSaveButton or
    //    undone in didPressCancelButton
    [[[kAppDelegate managedObjectContext] undoManager] beginUndoGrouping];
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
    
    // Reset the sequence_number of the Job and Education items in case they were re-ordered during the edit
    [self resequenceTables];
    
    // ...end the undo group
    [[[kAppDelegate managedObjectContext] undoManager] endUndoGrouping];
    [kAppDelegate saveContextAndWait: [kAppDelegate managedObjectContext]];
    
    // Cleanup the undoManager
    [[[kAppDelegate managedObjectContext] undoManager] removeAllActionsWithTarget: self];
    // ...and turn off editing in the UI
    [self setUIWithEditing: NO];
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
    
    // Re-sort the tables as editing may have moved their order in the tableView
    [self sortTables];
    [self.tableView reloadData];
    // ...and turn off editing in the UI
    [self setUIWithEditing: NO];
}


//----------------------------------------------------------------------------------------------------------
/**
 Set the UI for for editing enabled or disabled.
 
 Called when the user presses the Edit, Save, or Cancel buttons.
 
 @param isEditingMode   YES if we are going into edit mode, NO otherwise.
 */
- (void)setUIWithEditing: (BOOL)isEditingMode
{
    DLog();
    
    // Update editing flag
    self.editing = isEditingMode;
    
    // ...the add buttons (hidden is the boolean opposite of isEditingMode)
    [addJobBtn          setHidden: !isEditingMode];
    
    // ...enable/disable table editing
    [self.tableView setEditing: isEditingMode
                      animated: YES];
    // ...enable/disable resume fields
    [self setFieldsEditable: isEditingMode];
    
    if (isEditingMode)
    {
        // Set up the navigation items and save/cancel buttons
#warning TODO refactor to use size classes
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        {
            self.navigationItem.rightBarButtonItems = @[saveBtn, cancelBtn];
        }
        else
        {
            self.navigationItem.leftBarButtonItem  = cancelBtn;
            self.navigationItem.rightBarButtonItem = saveBtn;
        }
    }
    else
    {
        // Reset the nav bar defaults
        [self configureDefaultNavBar];
    }
}


//----------------------------------------------------------------------------------------------------------
/**
 Resequence the Jobs and Education objects to reflect the order the user has arranged them.
 */
- (void)resequenceTables
{
    DLog();
    
    // The job array is in the order (including deletes) the user wants
    // ...loop through the array by index, resetting the job object's sequence_number attribute
    int i = 0;
    for (Jobs *job in _jobArray)
    {
        if (job.isDeleted)
        {
            // No need to update the sequence number of deleted objects
        }
        else
        {
            // Set the sequence number on this job object and increment the counter
            [job setSequence_numberValue: i++];
        }
    }
}


//----------------------------------------------------------------------------------------------------------
/**
 Add a Jobs entity for this resume.
 */
- (void)addJob
{
    DLog();
    
    // Insert a new Jobs entity into the managedObjectContext
    Jobs *job = (Jobs *)[NSEntityDescription insertNewObjectForEntityForName: kOCRJobsEntity
                                                      inManagedObjectContext: [kAppDelegate managedObjectContext]];
    
    // Set the name to the value the user provided in the prompt
    job.name            = _nuEntityName;
    // ...the created timestamp to now
    job.created_date    = [NSDate date];
    // ...and the resume link to the resume we are managing
    job.resume          = _selectedResume;
    
    // Insert the newly created entity into the array in the first (zero-ith) position
    [_jobArray insertObject: job
                    atIndex: 0];
    // ...and resequence the Jobs and Education objects
    [self resequenceTables];
    
    // Construct an indexPath
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow: 0
                                                inSection: 0];
    
    /*
     Insert rows in the receiver at the locations identified by an array of index paths, with an option to
     animate the insertion.
     
     UITableView calls the relevant delegate and data source methods immediately afterwards to get the cells
     and other content for visible cells.
     */
    // Animate the insertion of the new row
    [self.tableView insertRowsAtIndexPaths: @[indexPath]
                          withRowAnimation: UITableViewRowAnimationFade];
    // ...and scroll the tableView back to the top to ensure the user can see the result of adding the Job
    [self.tableView scrollToRowAtIndexPath: indexPath
                          atScrollPosition: UITableViewScrollPositionTop
                                  animated: YES];
}


//----------------------------------------------------------------------------------------------------------
/**
 Prompts the user to enter a name for the new Jobs entity.
 */
- (void)promptForJobName
{
    DLog();
    
    // Display an alert to get the Job name. Note the cancel button is available.
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Enter Job Name", nil)
                                                    message: nil
                                                   delegate: self
                                          cancelButtonTitle: NSLocalizedString(@"Cancel", nil)
                                          otherButtonTitles: NSLocalizedString(@"OK", nil), nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    [alert show];
}


//----------------------------------------------------------------------------------------------------------
/**
 Sent to the delegate when the user clicks a button on an alert view.
 
 The receiver is automatically dismissed after this method is invoked.
 
 @param alertView       The alert view containing the button.
 @param buttonIndex     The index of the button that was clicked. The button indices start at 0.
 */
- (void)    alertView: (UIAlertView *)alertView
 clickedButtonAtIndex: (NSInteger)buttonIndex
{
    DLog();
    
    if (buttonIndex == k_OKButtonIndex)
    {
        // OK button was pressed, get the user's input
#warning TODO refactor to pass entity name as parameter
        self.nuEntityName = [[alertView textFieldAtIndex: 0] text];
        // Use the tag to determine which entity is being added
        [self addJob];
    }
    else
    {
        // User cancelled
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
    DLog();
    
    // We have one section in our table
    return 1;
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
    DLog();
    
    // If we are in edit mode allow swipe to delete
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
 */
- (UITableViewCell *)tableView: (UITableView *)tableView
          jobsCellForIndexPath: (NSIndexPath *)indexPath
{
    DLog();
    
    // Get a Subtitle cell
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: kOCRSubtitleTableCell];
    
    // ...set the title text content and dynamic text font
    cell.textLabel.text         = [_jobArray[indexPath.row] name];
    cell.textLabel.font         = [UIFont preferredFontForTextStyle: UIFontTextStyleHeadline];
    // ...the detail text content and dynamic text font
    cell.detailTextLabel.text   = [_jobArray[indexPath.row] title];
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
        NSManagedObject *jobToDelete = _jobArray[indexPath.row];
        [[kAppDelegate managedObjectContext] deleteObject: jobToDelete];
        [_jobArray removeObjectAtIndex: indexPath.row];
        // ...delete the object from the tableView
        [tableView deleteRowsAtIndexPaths: @[indexPath]
                         withRowAnimation: UITableViewRowAnimationFade];
        // ...and reload the table
        [tableView reloadData];
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
    
    if (fromIndexPath.section != toIndexPath.section)
    {
        // Cannot move between sections
        [OCAUtilities showErrorWithMessage: NSLocalizedString(@"Sorry, move not allowed.", nil)];
        [self.tableView reloadData];
        return;
    }
    
    // Get the from and to Rows of the table
    NSUInteger fromRow  = [fromIndexPath row];
    NSUInteger toRow    = [toIndexPath row];
    
    // Get the Job at the fromRow
    Jobs *movedJob = _jobArray[fromRow];
    // ...remove it from that "order"
    [_jobArray removeObjectAtIndex: fromRow];
    // ...and insert it where the user wants
    [_jobArray insertObject: movedJob
                    atIndex: toRow];
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
    DLog(@"section=%ld", (long)section);
    
    // We only have one section, so just return the count of the objects in jobArray
    return [_jobArray count];
}


#pragma mark - Table view delegate methods

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
                              sender: (self.jobArray)[indexPath.row]];
    
    // Clear the selection highlight
    [tableView deselectRowAtIndexPath: indexPath
                             animated: YES];
}


//----------------------------------------------------------------------------------------------------------
/**
 Asks the delegate for the height to use for a row in a specified location.
 
 The method allows the delegate to specify rows with varying heights. If this method is implemented, the value
 it returns overrides the value specified for the rowHeight property of UITableView for the given row.
 
 There are performance implications to using tableView:heightForRowAtIndexPath: instead of the rowHeight property.
 Every time a table view is displayed, it calls tableView:heightForRowAtIndexPath: on the delegate for each of its
 rows, which can result in a significant performance problem with table views having a large number of rows
 (approximately 1000 or more). See also tableView:estimatedHeightForRowAtIndexPath:.
 
 
 @param tableView       The table-view object requesting this information.
 @param indexPath       An index path that locates a row in tableView.
 @return                A nonnegative floating-point value that specifies the height (in points) that row should be.
 */
- (CGFloat)     tableView: (UITableView *)tableView
  heightForRowAtIndexPath: (NSIndexPath *)indexPath
{
    DLog();
    
    /*
     To support Dynamic Text, we need to calculate the size required by the text at run time given the
     user's preferred dynamic text size.
     
     We use boundingRectWithSize:options:attributes:context on a text string to determine the height required to show
     the content as completely as possible.
     
     Using this information we determine the height of the title and detail labels in the cell, return their total
     plus padding.
     
     We use CGRectIntegral here to ensure the rect is actually large enough. Here's the "help" for CGRectIntegral:
     Returns the smallest rectangle that results from converting the source rectangle values to integers.
     
     Returns a rectangle with the smallest integer values for its origin and size that contains the source rectangle.
     That is, given a rectangle with fractional origin or size values, CGRectIntegral rounds the rectangle’s origin
     downward and its size upward to the nearest whole integers, such that the result contains the original rectangle.
     */
    
    // Declare a test string for use in the calculations. We are only concerned about height here, so any text (that has a descender character) will work for our calculation
    NSString *stringToSize  = @"Sample String";
    // maxTextSize establishes bounds for the largest rect we can allow
    CGSize maxTextSize = CGSizeMake( CGRectGetWidth(CGRectIntegral(tableView.bounds)), CGRectGetHeight(CGRectIntegral(tableView.bounds)));
    
    // First, determine the size required by the the title string, given the user's dynamic text size preference.
    // ...get the bounding rect using UIFontTextStyleHeadline
    CGRect titleRect        = [stringToSize boundingRectWithSize: maxTextSize
                                                         options: NSStringDrawingUsesLineFragmentOrigin
                                                      attributes: @{NSFontAttributeName: [UIFont preferredFontForTextStyle: UIFontTextStyleHeadline]}
                                                         context: nil];
    // ...and the bounding rect using UIFontTextStyleSubheadline
    CGRect detailRect       = [stringToSize boundingRectWithSize: maxTextSize
                                                         options: NSStringDrawingUsesLineFragmentOrigin
                                                      attributes: @{NSFontAttributeName: [UIFont preferredFontForTextStyle: UIFontTextStyleSubheadline]}
                                                         context: nil];
    
    // Return the larger of 44 or the sum of the heights plus some padding
    return MAX(44.0f, CGRectGetHeight( CGRectIntegral( titleRect)) + CGRectGetHeight( CGRectIntegral( detailRect)) + 20);
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
        [detailViewController setBackButtonTitle: _selectedResume.name];
        [detailViewController setFetchedResultsController: self.fetchedResultsController];
    }
}


#pragma mark - Keyboard handlers

//----------------------------------------------------------------------------------------------------------
/**
 Invoked when the keyboard is about to show
 
 Scroll the content to ensure the active field is visible
 
 @param aNotification   the NSNotification containing information about the keyboard
 */
- (void)keyboardWillShow: (NSNotification*)aNotification
{
    DLog();
#warning TODO refactor
    
    // Get the size of the keyboard
    NSDictionary *info = [aNotification userInfo];
    CGSize kbSize = [info[UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    // ...and adjust the contentInset for its height
    //    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    
    //    self.coverLtrFld.contentInset           = contentInsets;
    //    self.coverLtrFld.scrollIndicatorInsets  = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    //    if (!CGRectContainsPoint(aRect, self.coverLtrFld.frame.origin)) {
    //        // calculate the contentOffset for the scroller
    //        CGPoint scrollPoint = CGPointMake(0.0, self.coverLtrFld.frame.origin.y - kbSize.height);
    //        [self.coverLtrFld setContentOffset: scrollPoint
    //                                  animated: YES];
    //    }
}


//----------------------------------------------------------------------------------------------------------
/**
 Invoked when the keyboard is about to be hidden
 
 Reset the contentInsets to "zero"
 
 @param aNotification   the NSNotification containing information about the keyboard
 */
- (void)keyboardWillBeHidden: (NSNotification*)aNotification
{
    DLog();
#warning TODO refactor
    
    //    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    
    //    self.coverLtrFld.contentInset          = contentInsets;
    //    self.coverLtrFld.scrollIndicatorInsets = contentInsets;
}


#pragma mark - Fetched Results Controller delegate methods

//----------------------------------------------------------------------------------------------------------
/**
 Notifies the receiver that the fetched results controller is about to start processing of one or more changes
 due to an add, remove, move, or update.
 
 This method is invoked before all invocations of controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:
 and controller:didChangeSection:atIndex:forChangeType: have been sent for a given change event (such as the
 controller receiving a NSManagedObjectContextDidSaveNotification notification).
 
 @param controller      The fetched results controller that sent the message.
 */
- (void)controllerWillChangeContent: (NSFetchedResultsController *)controller
{
    DLog();
    
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [self.tableView beginUpdates];
}


//----------------------------------------------------------------------------------------------------------
/**
 Notifies the receiver that a fetched object has been changed due to an add, remove, move, or update.
 
 The fetched results controller reports changes to its section before changes to the fetch result objects.
 Changes are reported with the following heuristics:
 * On add and remove operations, only the added/removed object is reported.
 * It’s assumed that all objects that come after the affected object are also moved, but these moves are
 not reported.
 * A move is reported when the changed attribute on the object is one of the sort descriptors used in the
 fetch request.
 An update of the object is assumed in this case, but no separate update message is sent to the delegate.
 * An update is reported when an object’s state changes, but the changed attributes aren’t part of the sort keys.
 
 This method may be invoked many times during an update event (for example, if you are importing data on a background
 thread and adding them to the context in a batch). You should consider carefully whether you want to update the
 table view on receipt of each message.
 
 @param controller      The fetched results controller that sent the message.
 @param anObject        The object in controller’s fetched results that changed.
 @param indexPath       The index path of the changed object (this value is nil for insertions).
 @param type            The type of change. For valid values see “NSFetchedResultsChangeType”.
 @param newIndexPath    The destination path for the object for insertions or moves (this value is nil for a deletion).
 */
- (void)controller: (NSFetchedResultsController *)controller
   didChangeObject: (id)anObject
       atIndexPath: (NSIndexPath *)indexPath
     forChangeType: (NSFetchedResultsChangeType)type
      newIndexPath: (NSIndexPath *)newIndexPath
{
    DLog();
    
    // Use the type to determine the operation to perform
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            // Insert a row
            [_tableView insertRowsAtIndexPaths: @[newIndexPath]
                              withRowAnimation: UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            // Delete a row
            [_tableView deleteRowsAtIndexPaths: @[indexPath]
                              withRowAnimation: UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            // Underlying contents have changed, re-configure the cell
            [self.tableView reloadRowsAtIndexPaths:@[newIndexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeMove:
            // On a move, delete the rows where they were...
            [_tableView deleteRowsAtIndexPaths: @[indexPath]
                              withRowAnimation: UITableViewRowAnimationFade];
            // ...and reload the section to insert new rows and ensure titles are updated appropriately.
            [_tableView reloadSections: [NSIndexSet indexSetWithIndex: newIndexPath.section]
                      withRowAnimation: UITableViewRowAnimationFade];
            break;
    }
}


//----------------------------------------------------------------------------------------------------------
/**
 Notifies the receiver of the addition or removal of a section.
 
 The fetched results controller reports changes to its section before changes to the fetched result objects.
 
 This method may be invoked many times during an update event (for example, if you are importing data on a
 background thread and adding them to the context in a batch). You should consider carefully whether you want
 to update the table view on receipt of each message.
 
 @param controller      The fetched results controller that sent the message.
 @param sectionInfo     The section that changed.
 @param sectionIndex    The index of the changed section.
 @param type            The type of change (insert or delete). Valid values are NSFetchedResultsChangeInsert
 and NSFetchedResultsChangeDelete.
 */
- (void)controller: (NSFetchedResultsController *)controller
  didChangeSection: (id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex: (NSUInteger)sectionIndex
     forChangeType: (NSFetchedResultsChangeType)type
{
    DLog();
    
    // Use the type to determine the operation to perform
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [_tableView insertSections: [NSIndexSet indexSetWithIndex: sectionIndex]
                      withRowAnimation: UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [_tableView deleteSections: [NSIndexSet indexSetWithIndex: sectionIndex]
                      withRowAnimation: UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeMove:
            ALog(@"Did not expect NSFetchedResultsChangeMove");
            break;
            
        case NSFetchedResultsChangeUpdate:
            ALog(@"Did not expect NSFetchedResultsChangeUpdate");
            break;
    }
}


//----------------------------------------------------------------------------------------------------------
/**
 Notifies the receiver that the fetched results controller has completed processing of one or more changes
 due to an add, remove, move, or update.
 
 This method is invoked after all invocations of controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:
 and controller:didChangeSection:atIndex:forChangeType: have been sent for a given change event (such as the
 controller receiving a NSManagedObjectContextDidSaveNotification notification).
 
 @param controller  The fetched results controller that sent the message.
 */
- (void)controllerDidChangeContent: (NSFetchedResultsController *)controller
{
    DLog();
    
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [_tableView endUpdates];
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
    
    [super reloadFetchedResults: aNote];
    
    if (self.selectedResume.isDeleted)
    {
        // Need to display a message
        [OCAUtilities showWarningWithMessage:@"resume delete"];
    }
    else
    {
        [_tableView reloadData];
    }
}



@end
