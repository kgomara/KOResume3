//
//  OCRJobsViewController.m
//  KOResume
//
//  Created by Kevin O'Mara on 4/6/14.
//  Copyright (c) 2014 O'Mara Consulting Associates. All rights reserved.
//

#import "OCRJobsViewController.h"
#import "OCRTableViewHeaderCell.h"
#import "OCRAppDelegate.h"
#import "Jobs.h"
#import "Accomplishments.h"
#import "SVWebViewController.h"

#define kJobStartDateFieldTag           5
#define kJobEndDateFieldTag             6


@interface OCRJobsViewController ()
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
     Reference to the button available in table edit mode that allows the user to add an Accomplishment.
     */
    UIButton            *addAccomplishmentButton;
    
    /**
     Reference to the date formatter object.
     */
    NSDateFormatter     *dateFormatter;
    
    /**
     Reference to the date picker.
     */
    UIDatePicker        *datePicker;

}

/**
 Array used to keep the Job's accomplishment objects sorted by sequence_number.
 */
@property (nonatomic, strong)   NSMutableArray      *accomplishmentsArray;

/**
 Variable used to store the new entity name entered when the user adds an accomplishment object.
 */
@property (nonatomic, strong)   NSString            *nuEntityName;

/**
 Convenience reference to the managed object instance we are managing.
 
 OCRBaseDetailViewController, of which this is a subclass, declares a selectedManagedObject. We make this
 type-correct reference merely for convenience.
 */
@property (nonatomic, strong)   Jobs                *selectedJob;

/**
 A boolean flag to indicate whether the user is editing information or simply viewing.
 */
@property (nonatomic, assign, getter=isEditing) BOOL editing;

@property (nonatomic, strong) UIPopoverController   *dateControllerPopover;

@end

@implementation OCRJobsViewController

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
    
    // For convenience, make a type-correct reference to the Jobs object we're working on
    self.selectedJob = (Jobs *)self.selectedManagedObject;
    
	self.view.backgroundColor = [UIColor clearColor];
    
    // Set the default button title
    self.backButtonTitle    = NSLocalizedString(@"Resume", nil);
    self.title              = _selectedJob.name;
    
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
    /*
     Instantiating a date formatter is a relatively expensive operation and is used often in our controller.
     We instantiate one in view controller and use it throughout.
     */
    // Set a dateFormatter.
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle: NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle: NSDateFormatterNoStyle];	//Not shown
    
    // ...datePicker
    datePicker = [[UIDatePicker alloc] init];
    // ...and the NavBar
    [self configureDefaultNavBar];
    
    // Set editing off
    self.editing = NO;
    [self setUIWithEditing: NO];
    
    // Sort the job and education tables by sequence_number
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
    
    self.fetchedResultsController.delegate = self;
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
    
    // Sort accomplishments in the order they should appear in the table
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: kOCRSequenceNumberAttributeName
                                                                   ascending: YES];
    NSArray *sortDescriptors    = @[sortDescriptor];
    self.accomplishmentsArray   = [NSMutableArray arrayWithArray: [_selectedJob.accomplishment sortedArrayUsingDescriptors: sortDescriptors]];
}


//----------------------------------------------------------------------------------------------------------
/**
 Update the data fields of the view - the resume.
 */
- (void)loadViewFromSelectedObject
{
    DLog();
    
    [_jobName setText: _selectedJob.name
        orPlaceHolder: NSLocalizedString(@"Enter resume name", nil)];
    
    /*
     It's important to set the placeholder text in case the data field is "empty" because we are using
     autolayout. If both the field and place holders are empty it will have zero width in the UI, and
     when the user presses the "edit" button they would not be able to get a cursor inside any of the
     empty fields.
     */
    // For each of the tableHeaderView's text fields, set either it's text or placeholder property
    [_jobCity setText: _selectedJob.city
        orPlaceHolder: NSLocalizedString(@"Enter city", nil)];
    [_jobTitle setText: _selectedJob.title
         orPlaceHolder: NSLocalizedString(@"Enter job title", nil)];
    
    [_jobState setText: _selectedJob.state
         orPlaceHolder: NSLocalizedString(@"Enter State", nil)];
    
	self.jobStartDate.text = [dateFormatter stringFromDate: self.selectedJob.start_date];
    if (_selectedJob.end_date) {
        self.jobEndDate.text = [dateFormatter stringFromDate: self.selectedJob.end_date];
    } else {
        self.jobEndDate.text = NSLocalizedString(@"Current", nil);
    }
    
    /*
     jobSummary is a textView, and always has width and height, so the autolayout concern mentioned
     above is not a concern here.
     */
    _jobSummary.text = _selectedJob.summary;
    [_jobSummary scrollRangeToVisible: NSMakeRange(0, 0)];
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
    
    // Set all the text fields enable property (and text view's editable)
    [_jobName      setEnabled: editable];
    [_jobTitle     setEnabled: editable];
    [_jobCity      setEnabled: editable];
    [_jobState     setEnabled: editable];
    [_jobStartDate setEnabled: editable];
    [_jobEndDate   setEnabled: editable];
    [_jobSummary   setEditable: editable];     // resumeSummary is a UITextView
    
    // Determine the background color for the fields based on the editable param
    UIColor *backgroundColor = editable? [UIColor whiteColor] : [UIColor clearColor];
    
    // ...and set the background color
    [_jobName      setBackgroundColor: backgroundColor];
    [_jobTitle     setBackgroundColor: backgroundColor];
    [_jobCity      setBackgroundColor: backgroundColor];
    [_jobState     setBackgroundColor: backgroundColor];
    [_jobStartDate setBackgroundColor: backgroundColor];
    [_jobEndDate   setBackgroundColor: backgroundColor];
    [_jobSummary   setBackgroundColor: backgroundColor];
}


//----------------------------------------------------------------------------------------------------------
/**
 Configure the default items for the navigation bar.
 */
- (void)configureDefaultNavBar
{
    DLog();
    
    // Set the title
    self.navigationItem.title = _selectedJob.name;
    
    // Set up the navigation items and save/cancel buttons
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.navigationItem.rightBarButtonItems = @[editBtn];
    } else {
        self.navigationItem.leftBarButtonItem  = backBtn;
        self.navigationItem.rightBarButtonItem = editBtn;
    }
    
    // Set table editing off
    [self.tableView setEditing: NO];
    
    // ...and hide the add buttons
    [addAccomplishmentButton setHidden: YES];
}


#pragma mark - OCRDetailViewProtocol delegate methods

//----------------------------------------------------------------------------------------------------------
/**
 Configure the view items.
 */
- (void)configureView
{
    DLog();
    
    // Use the information in the selected managed object to update the UI fields
    [self loadViewFromSelectedObject];
}

#pragma mark - OCRDateTableViewProtocal delegate methods
//----------------------------------------------------------------------------------------------------------
/**
 Update the start and end dates when changed.
 */
- (void)dateControllerDidUpdate
{
    DLog();
    
	self.jobStartDate.text = [dateFormatter stringFromDate: self.selectedJob.start_date];
    if (_selectedJob.end_date) {
        self.jobEndDate.text = [dateFormatter stringFromDate: self.selectedJob.end_date];
    } else {
        self.jobEndDate.text = NSLocalizedString(@"Current", nil);
    }    
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
     Update fonts on all visible UI elements and recalculate a layout for the updated sizes of those elements.
     It's important to note that you must apply a new UIFont instance with preferredFontForTextStyle: to get
     an updated size. Simply calling invalidateIntrinsicContentSize or setNeedsLayout will not automatically
     apply the new content size because UIFont instances are immutable.
     */
    _jobName.Font       = [UIFont preferredFontForTextStyle: UIFontTextStyleHeadline];
    _jobTitle.font      = [UIFont preferredFontForTextStyle: UIFontTextStyleBody];
    _jobCity.font       = [UIFont preferredFontForTextStyle: UIFontTextStyleBody];
    _jobState.font      = [UIFont preferredFontForTextStyle: UIFontTextStyleBody];
    _jobStartDate.font  = [UIFont preferredFontForTextStyle: UIFontTextStyleBody];
    _jobEndDate.font    = [UIFont preferredFontForTextStyle: UIFontTextStyleBody];
    _jobSummary.font    = [UIFont preferredFontForTextStyle: UIFontTextStyleBody];
    
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
    
    // Save the changes
    _selectedJob.name           = _jobName.text;
    _selectedJob.title          = _jobTitle.text;
    _selectedJob.city           = _jobCity.text;
    _selectedJob.state          = _jobState.text;
    _selectedJob.start_date     = [dateFormatter dateFromString: _jobStartDate.text];
    if ([_jobStartDate.text isEqualToString: @"Current"]) {
        _selectedJob.end_date   = nil;
    } else {
        _selectedJob.end_date   = [dateFormatter dateFromString: _jobEndDate.text];
    }
    _selectedJob.summary        = _jobSummary.text;
    
    // ...end the undo group
    [[[kAppDelegate managedObjectContext] undoManager] endUndoGrouping];
    [kAppDelegate saveContextAndWait: [kAppDelegate managedObjectContext]];
    
    // Cleanup the undoManager
    [[[kAppDelegate managedObjectContext] undoManager] removeAllActionsWithTarget: self];
    // ...and turn off editing in the UI
    [self setUIWithEditing: NO];
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
        // Changes were made - discard them
        [[[kAppDelegate managedObjectContext] undoManager] undoNestedGroup];
    }
    
    // Cleanup the undoManager
    [[[kAppDelegate managedObjectContext] undoManager] removeAllActionsWithTarget: self];
    
    // Re-sort the tables as editing may have moved their order in the tableView
    [self loadViewFromSelectedObject];
    [self sortTables];
    [self.tableView reloadData];
    // ...and turn off editing in the UI
    [self setUIWithEditing: NO];
    [self resetView];
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
    [addAccomplishmentButton setHidden: !isEditingMode];
    
    // ...enable/disable table editing
    [self.tableView setEditing: isEditingMode
                      animated: YES];
    // ...enable/disable resume fields
    [self setFieldsEditable: isEditingMode];
    
    if (isEditingMode) {
        // Set up the navigation items and save/cancel buttons
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            self.navigationItem.rightBarButtonItems = @[saveBtn, cancelBtn];
        } else {
            self.navigationItem.leftBarButtonItem  = cancelBtn;
            self.navigationItem.rightBarButtonItem = saveBtn;
        }
    } else {
        // Reset the nav bar defaults
        [self configureDefaultNavBar];
    }
}


//----------------------------------------------------------------------------------------------------------
/*
 API documentation is in .h file.
 
 This is a "public" method (as are the IBOutlet properties).  In Xcode 5 you can declare IB items in either
 the .m or .h files. I can make an argument for either location. From a C language perspective, they should
 be declared in the .h as they are used externally from the class - i.e., in the XIBs. But IMO good object
 architecture would hide this "implementation detail" from users of the class - declaring them in the .h file
 makes them accessible to any compilation unit, and that isn't really want I want.
 
 That said, the general consensus seems to favor declaring them in the .h, so that's what we do here.
 */
- (IBAction)didPressAddButton: (id)sender
{
    DLog();
    
    [self promptForAccomplishmentName];
}

//----------------------------------------------------------------------------------------------------------
/*
 API documentation is in .h file. (See above comment).
 */
- (IBAction)didPressInfoButton:(id)sender
{
    DLog();
    
    if (self.isEditing) {
        [self promptForJobURI];
    } else {
        // Open the job.uri in a UIWebView.
        // First, check to see if we have something that looks like a URI
        if (self.selectedJob.uri == NULL ||
           [self.selectedJob.uri rangeOfString: @"://"].location == NSNotFound)
        {
            // Not a valid URI
            return;
        }
        
        // Open the Url in an application webView
        SVWebViewController *webViewController = [[SVWebViewController alloc] initWithAddress: self.selectedJob.uri];
        [self.navigationController pushViewController: webViewController
                                             animated: YES];
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
    // ...loop through the array by index, resetting the job's sequence_number attribute
    for (int i = 0; i < [_accomplishmentsArray count]; i++) {
        if ([_accomplishmentsArray[i] isDeleted]) {
            // no need to update the sequence number of deleted objects
        } else {
            [_accomplishmentsArray[i] setSequence_numberValue: i];
        }
    }
}


//----------------------------------------------------------------------------------------------------------
/**
 Add an Accomplishments entity for this resume.
 */
- (void)addAccomplishment
{
    DLog();
    
    // Insert a new Jobs entity into the managedObjectContext
    Accomplishments *accomplishment = (Accomplishments *)[NSEntityDescription insertNewObjectForEntityForName: kOCRAccomplishmentsEntity
                                                      inManagedObjectContext: [kAppDelegate managedObjectContext]];
    
    // Set the name to the value the user provided in the prompt
    accomplishment.name            = _nuEntityName;
    // ...the created timestamp to now
    accomplishment.created_date    = [NSDate date];
    // ...and the resume link to the resume we are managing
    accomplishment.job          = _selectedJob;
    
    // Insert the newly created entity into the array in the first (zero-ith) position
    [_accomplishmentsArray insertObject: accomplishment
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
- (void)promptForAccomplishmentName
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


- (void)promptForJobURI
{
    DLog();
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
    
    if (buttonIndex == 1) {
        // OK button was pressed, get the user's input
        self.nuEntityName = [[alertView textFieldAtIndex: 0] text];
        [self addAccomplishment];
    } else {
        // User cancelled
        [self configureDefaultNavBar];
    }
}


#pragma mark - Table view datasource methods

//----------------------------------------------------------------------------------------------------------
/**
 Asks the data source to return the number of sections in the table view.
 
 @param tableView       An object representing the table view requesting this information.
 @return               The number of sections in tableView. The default value is 1.
 */
- (NSInteger)numberOfSectionsInTableView: (UITableView *)tableView
{
    DLog();
    
    // We have one sections in our table
    return 1;
}


//----------------------------------------------------------------------------------------------------------
/**
 Asks the data source to verify that the given row is editable.
 
 @param tableView       The table-view object requesting this information.
 @param indexPath       An index path locating a row in tableView.
 @return               YES to allow editing, NO otherwise,
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
 @return               An object inheriting from UITableViewCell that the table view can use for the specified row.
 An assertion is raised if you return nil.
 */
- (UITableViewCell *)tableView: (UITableView *)tableView
         cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
    DLog();
    
    // Get a Subtitle cell
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: kOCRSubtitleTableCell];
    
	// ...and configure it
    [self configureCell: cell
            atIndexPath: indexPath];
    
    return cell;
}


//----------------------------------------------------------------------------------------------------------
/**
 Configure a cell for the job.
 
 @param cell        A cell to configure.
 @param indexPath   The indexPath of the section and row the cell represents.
 */
- (void)configureCell: (UITableViewCell *)cell
          atIndexPath: (NSIndexPath *)indexPath
{
    DLog();
    
    // We're in the Jobs section,
    // ...set the title text content and dynamic text font
    cell.textLabel.text         = [(Accomplishments *)_accomplishmentsArray[indexPath.row] name];
    cell.textLabel.font         = [UIFont preferredFontForTextStyle: UIFontTextStyleHeadline];
    // ...the detail text content and dynamic text font
    cell.detailTextLabel.text   = [[(Accomplishments *)_accomplishmentsArray[indexPath.row] summary] first30];
    cell.detailTextLabel.font   = [UIFont preferredFontForTextStyle: UIFontTextStyleSubheadline];
    // ...and the accessory disclosure indicator
    cell.accessoryType          = UITableViewCellAccessoryDisclosureIndicator;
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
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the managed object at the given index path.
        NSManagedObject *accomplishmentToDelete = _accomplishmentsArray[indexPath.row];
        [[kAppDelegate managedObjectContext] deleteObject: accomplishmentToDelete];
        [_accomplishmentsArray removeObjectAtIndex: indexPath.row];
        // ...delete the object from the tableView
        [tableView deleteRowsAtIndexPaths: @[indexPath]
                         withRowAnimation: UITableViewRowAnimationFade];
        // ...and reload the table
        [tableView reloadData];
    } else {
        DLog(@"editingStyle=%d", (int)editingStyle);
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
    
    if (fromIndexPath.section != toIndexPath.section) {
        // Cannot move between sections
        [OCAUtilities showErrorWithMessage: NSLocalizedString(@"Sorry, move not allowed.", nil)];
        [self.tableView reloadData];
        return;
    }
    
    // Get the from and to Rows of the table
    NSUInteger fromRow  = [fromIndexPath row];
    NSUInteger toRow    = [toIndexPath row];
    
    // Get the accomplishments object at the fromRow
    Accomplishments *movedAccomplishment = _accomplishmentsArray[fromRow];
    // ...remove it from that "order"
    [_accomplishmentsArray removeObjectAtIndex: fromRow];
    // ...and insert it where the user wants
    [_accomplishmentsArray insertObject: movedAccomplishment
                                atIndex: toRow];
}


//----------------------------------------------------------------------------------------------------------
/**
 Tells the data source to return the number of rows in a given section of a table view.
 
 @param tableView       The table-view object requesting this information.
 @param section         An index number identifying a section in tableView.
 @return               The number of rows in section.
 */
- (NSInteger)tableView: (UITableView *)tableView
 numberOfRowsInSection: (NSInteger)section
{
    DLog(@"section=%ld", (long)section);
    
    return [_accomplishmentsArray count];
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
    // Segue to the accomplishments object
//    [self performSegueWithIdentifier: kOCRAccomplishmentsSegue
//                              sender: [_accomplishmentsArray objectAtIndex: indexPath.row]];

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
 Asks the delegate for the height to use for a row in a specified location.
 
 The method allows the delegate to specify rows with varying heights. If this method is implemented, the value
 it returns overrides the value specified for the rowHeight property of UITableView for the given row.
 
 There are performance implications to using tableView:heightForRowAtIndexPath: instead of the rowHeight property.
 Every time a table view is displayed, it calls tableView:heightForRowAtIndexPath: on the delegate for each of its
 rows, which can result in a significant performance problem with table views having a large number of rows
 (approximately 1000 or more). See also tableView:estimatedHeightForRowAtIndexPath:.
 
 
 @param tableView       The table-view object requesting this information.
 @param indexPath       An index path that locates a row in tableView.
 @return               A nonnegative floating-point value that specifies the height (in points) that row should be.
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
    
    // maxTextSize establishes bounds for the largest rect we can allow
    CGSize maxTextSize = CGSizeMake( CGRectGetWidth(CGRectIntegral(tableView.bounds)), CGRectGetHeight(CGRectIntegral(tableView.bounds)));
    
    // First, determine the size required by the the title string, given the user's dynamic text size preference.
    // ...we are only concerned about height here, so any text (that has a descender character) will work for our calculation
    NSString *stringToSize  = @"Sample String";
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
    
    OCRTableViewHeaderCell *headerView = [tableView dequeueReusableCellWithIdentifier: kOCRHeaderCell];
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
    UIView *wrapperView = [[UIView alloc] initWithFrame: [headerView frame]];
    [wrapperView addSubview:headerView];
    
    // Set the section dynamic text font, text color, and background color
	[headerView.sectionLabel setFont:            [UIFont preferredFontForTextStyle: UIFontTextStyleHeadline]];
	[headerView.sectionLabel setTextColor:       [UIColor blackColor]];
	[headerView.sectionLabel setBackgroundColor: [UIColor clearColor]];
    
    // Set the tag of the addButton to the section the header represents
    [headerView.addButton setTag:section];
    
    // Hide or show the addButton depending on whether we are in editing mode
    if (self.isEditing) {
        [headerView.addButton setHidden: NO];
    } else {
        [headerView.addButton setHidden: YES];
    }
    
    // Finally, set the text content and save a reference to the add button so they can be
    // shown or hidden whenever the user turns editing mode on or off
    headerView.sectionLabel.text    = NSLocalizedString(@"Accomplishments", nil);
    addAccomplishmentButton         = headerView.addButton;
    
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
    
    if ([segue.identifier isEqualToString: kOCRDateControllerSegue]) {
        if (_dateControllerPopover) {
            // Menu is being displayed, dismiss it
            [_dateControllerPopover dismissPopoverAnimated: YES];
            self.dateControllerPopover = nil;
        } else {
            // Get the seque from the Storyboard
            UIStoryboardPopoverSegue* popSegue  = (UIStoryboardPopoverSegue*)segue;
            self.dateControllerPopover          = popSegue.popoverController;
            // ...and set the delegate
            _dateControllerPopover.delegate     = self;
            
            // Get the destination view controller and set a few properties
            OCRDateTableViewController *dateControllerVC    = (OCRDateTableViewController *)segue.destinationViewController;
            dateControllerVC.delegate                       = self;
            dateControllerVC.selectedJob                    = _selectedJob;
            dateControllerVC.preferredContentSize           = CGSizeMake(320.0f, 460.0f);
        }
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
    
//    UIEdgeInsets contentInsets = UIEdgeInsetsZero;

//    self.coverLtrFld.contentInset          = contentInsets;
//    self.coverLtrFld.scrollIndicatorInsets = contentInsets;
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
    
    // Always allow editing
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
    DLog();
}


#pragma mark - UITextFieldDelegate methods

//----------------------------------------------------------------------------------------------------------
/**
 Asks the delegate if editing should begin in the specified text field.
 
 When the user performs an action that would normally initiate an editing session, the text field calls this method 
 first to see if editing should actually proceed. In most circumstances, you would simply return YES from this method 
 to allow editing to proceed.
 
 Implementation of this method by the delegate is optional. If it is not present, editing proceeds as if this method 
 had returned YES.
 
 @param textField   The text field for which editing is about to begin.
 @return            YES if an editing session should be initiated; otherwise, NO to disallow editing.
 */
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    DLog();
    
//    _activeDateFld = 0;
    // Check to see if the tap occured in one of the date fields
    if (textField.tag == kJobStartDateFieldTag ||
        textField.tag == kJobEndDateFieldTag)
    {
        // We are in a date field. Dismiss the keyboard, if any.
        [OCAUtilities dismissKeyboard];
        [textField resignFirstResponder];
        if (!self.selectedJob.start_date) {
            // If there is no start_date yet, default to today
            self.selectedJob.start_date = [NSDate date];
        }
        // Segue to the date controller
        [self performSegueWithIdentifier:kOCRDateControllerSegue
                                  sender:nil];
        // and return NO to disallow standard UITextField editing.
        return NO;
    }
    
    return YES;
}


//----------------------------------------------------------------------------------------------------------
/**
 Tells the delegate that editing began for the specified text field.
 
 This method notifies the delegate that the specified text field just became the first responder. You can use 
 this method to update your delegate’s state information. For example, you might use this method to show overlay
 views that should be visible while editing.
 
 Implementation of this method by the delegate is optional.
 
 @param textField   The text field for which an editing session began.
 */
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    DLog();
    
}


//----------------------------------------------------------------------------------------------------------
/**
 Asks the delegate if editing should stop in the specified text field.
 
 This method is called when the text field is asked to resign the first responder status. This might occur 
 when your application asks the text field to resign focus or when the user tries to change the editing focus 
 to another control. Before the focus actually changes, however, the text field calls this method to give your 
 delegate a chance to decide whether it should.
 
 Normally, you would return YES from this method to allow the text field to resign the first responder status. 
 You might return NO, however, in cases where your delegate detects invalid contents in the text field. By 
 returning NO, you could prevent the user from switching to another control until the text field contained a 
 valid value.
 
 Note: If you use this method to validate the contents of the text field, you might also want to provide feedback 
 to that effect using an overlay view. For example, you could temporarily display a small icon indicating the 
 text was invalid and needs to be corrected. For more information about adding overlays to text fields, see the 
 methods of UITextField.
 
 Be aware that this method provides only a recommendation about whether editing should end. Even if you return 
 NO from this method, it is possible that editing might still end. For example, this might happen when the text 
 field is forced to resign the first responder status by being removed from its parent view or window.
 
 Implementation of this method by the delegate is optional. If it is not present, the first responder status is 
 resigned as if this method had returned YES.
 
 @param textField   The text field for which editing is about to end.
 @return            YES if editing should stop; otherwise, NO if the editing session should continue.
 */
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
	// Validate fields - nothing to do in this version
	
	return YES;
}


//----------------------------------------------------------------------------------------------------------
/**
 Asks the delegate if the text field should process the pressing of the return button.
 
 The text field calls this method whenever the user taps the return button. You can use this method to implement 
 any custom behavior when the button is tapped.
 
 @param textField   The text field whose return button was pressed.
 @return            YES if the text field should implement its default behavior for the return button; otherwise, NO.
 */
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    DLog();
    
    /*
     Another use of the tag field...in Interface Builder, each of the UITextFields is given a sequential tag value,
     and the keyboard Return key is set to "Next". When the user taps the Next key, this delegate method is invoked
     We use the tag field to find the next field, and if there is one we set it as firstResponder.
     */
    // Get the value of the next field's tag
	int nextTag = [textField tag] + 1;
    // ...and attempt to get it using the viewWithTag method
	UIResponder *nextResponder = [textField.superview viewWithTag: nextTag];
	
	if (nextResponder) {
        // If there is a nextResponser, make it firstResponder - i.e., give it focus
        [nextResponder becomeFirstResponder];
	} else {
        // ...otherwise this textfield must be the last.
		[textField resignFirstResponder];       // Dismisses the keyboard
        [self resetView];
	}
	
	return NO;                                  // We always return NO as we are implementing the textField's behavior
}

#pragma mark - UIPopoverDelegate methods

//----------------------------------------------------------------------------------------------------------
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    DLog();
    
    self.dateControllerPopover = nil;
    [self configureView];
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
    switch(type) {
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
            [self configureCell: [_tableView cellForRowAtIndexPath: indexPath]
                    atIndexPath: indexPath];
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
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [_tableView insertSections: [NSIndexSet indexSetWithIndex: sectionIndex]
                      withRowAnimation: UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [_tableView deleteSections: [NSIndexSet indexSetWithIndex: sectionIndex]
                      withRowAnimation: UITableViewRowAnimationFade];
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
 Reset the view to it default state
 */
- (void)resetView
{
    DLog();
    
    [self.jobSummary setContentOffset: CGPointZero
                             animated: YES];
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
    
    [self loadViewFromSelectedObject];
}


@end
