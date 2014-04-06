//
//  OCRResumeViewController.m
//  KOResume
//
//  Created by Kevin O'Mara on 3/9/11.
//  Copyright (c) 2011-2014 O'Mara Consulting Associates. All rights reserved.
//

#import "OCRResumeViewController.h"
#import "OCRTableViewHeaderCell.h"
#import "OCRAppDelegate.h"
#import "Resumes.h"
#import "Jobs.h"
#import "Education.h"

#define	k_JobsSection       0
#define k_EducationSection	1


@interface OCRResumeViewController ()
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
    
    /**
     Reference to the button available in table edit mode that allows the user to add an Education/Certification.
     */
    UIButton            *addEducationBtn;
}

/**
 Array used to keep the Resume's job objects sorted by sequence_number.
 */
@property (nonatomic, strong)   NSMutableArray      *jobArray;

/**
 Array used to keep the Resume's education objects sorted by sequence_number.
 */
@property (nonatomic, strong)   NSMutableArray      *educationArray;

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

@implementation OCRResumeViewController


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
    
    // Sort jobs in the order they should appear in the table
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: kOCRSequenceNumberAttributeName
                                                                   ascending: YES];
    NSArray *sortDescriptors    = [NSArray arrayWithObject: sortDescriptor];
    self.jobArray               = [NSMutableArray arrayWithArray: [_selectedResume.job sortedArrayUsingDescriptors: sortDescriptors]];
    // ...sort the Education and Certification array
    self.educationArray = [NSMutableArray arrayWithArray: [_selectedResume.education sortedArrayUsingDescriptors: sortDescriptors]];
}


//----------------------------------------------------------------------------------------------------------
/**
 Update the data fields of the view - the resume.
 */
- (void)loadViewFromSelectedObject
{
    DLog();
    
    [self setTextField: _resumeName
               forData: _selectedResume.name
         orPlaceHolder: NSLocalizedString(@"Enter resume name", nil)];

    
    // Check to see if we are iPad - only the iPad has current job information
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        // The jobsArray is always in sequence_number order
        // Check to see if there is at least 1 Job...
        if ([_jobArray count] > 0) {
            // ...if so, get the first one,
            Jobs *currentJob        = [_jobArray objectAtIndex:0];
            // ...use it to populate the current job information in the summaryView,
            _currentJobTitle.text   = currentJob.title;
            _currentJobName.text    = currentJob.name;
            // ...and make sure the "at" label is visible
            _atLabel.hidden         = NO;
        } else {
            // If the are no jobs, clear the current job fields
            _currentJobTitle.text   = @"";
            _currentJobName.text    = @"";
            // ...and hide the "at" label
            _atLabel.hidden         = YES;
        }
    }
    
    /*
     It's important to set the placeholder text in case the data field is "empty" because we are using
     autolayout. If both the field and place holders are empty it will have zero width in the UI, and
     when the user presses the "edit" button they would not be able to get a cursor inside any of the
     empty fields.
     */
    // For each of the summaryView's text fields, set either it's text or placeholder property
    [self setTextField: _resumeStreet1
               forData: _selectedResume.street1
         orPlaceHolder: NSLocalizedString(@"Enter street1 address", nil)];
    
    [self setTextField: _resumeCity
               forData: _selectedResume.city
         orPlaceHolder: NSLocalizedString(@"Enter city", nil)];
    
    [self setTextField: _resumeState
               forData: _selectedResume.state
         orPlaceHolder: NSLocalizedString(@"Enter State", nil)];
    
    [self setTextField: _resumePostalCode
               forData: _selectedResume.postal_code
         orPlaceHolder: NSLocalizedString(@"Enter zip code", nil)];

    [self setTextField: _resumeHomePhone
               forData: _selectedResume.home_phone
         orPlaceHolder: NSLocalizedString(@"Enter home phone", nil)];
    
    [self setTextField: _resumeMobilePhone
               forData: _selectedResume.mobile_phone
         orPlaceHolder: NSLocalizedString(@"Enter mobile phone", nil)];
    
    [self setTextField: _resumeEmail
               forData: _selectedResume.email
         orPlaceHolder: NSLocalizedString(@"Enter email address", nil)];

    /*
     resumeSummary is a textView, and always has width and height, so the autolayout concern mentioned
     above is not a concern here.
     */
    // resumeSummary is a UITextView
    _resumeSummary.text = _selectedResume.summary;
    [_resumeSummary scrollRangeToVisible: NSMakeRange(0, 0)];
}


//----------------------------------------------------------------------------------------------------------
/**
 Helper method to initialize a UITextField with text or placeholder.
 
 @param textField       The text field to populate.
 @param text            The text candidate.
 @param placeholder     The placeholder to use if candidate text is empty.
 */
- (void)setTextField: (UITextField *)textField
             forData: (NSString *)text
       orPlaceHolder: (NSString *)placeholder
{
    DLog();
    
    // Check if the text candidate is null or "empty"
    if ([text length] > 0) {
        // There is something in the text candidate - use it
        textField.text          =  text;
    } else {
        // Nothing in text, set the textField.text to an empty string
        textField.text          = @"";
        // ...and use the placeholder instead
        textField.placeholder   = placeholder;
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
    [_resumeName        setEnabled: editable];
    [_resumeStreet1     setEnabled: editable];
    [_resumeCity        setEnabled: editable];
    [_resumeState       setEnabled: editable];
    [_resumePostalCode  setEnabled: editable];
    [_resumeHomePhone   setEnabled: editable];
    [_resumeMobilePhone setEnabled: editable];
    [_resumeEmail       setEnabled: editable];
    [_resumeSummary     setEditable: editable];     // resumeSummary is a UITextView
    
    // Determine the background color for the fields based on the editable param
    UIColor *backgroundColor = editable? [UIColor whiteColor] : [UIColor clearColor];
    
    // ...and set the background color
    [_resumeName        setBackgroundColor: backgroundColor];
    [_resumeStreet1     setBackgroundColor: backgroundColor];
    [_resumeCity        setBackgroundColor: backgroundColor];
    [_resumeState       setBackgroundColor: backgroundColor];
    [_resumePostalCode  setBackgroundColor: backgroundColor];
    [_resumeHomePhone   setBackgroundColor: backgroundColor];
    [_resumeMobilePhone setBackgroundColor: backgroundColor];
    [_resumeEmail       setBackgroundColor: backgroundColor];
    [_resumeSummary     setBackgroundColor: backgroundColor];
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
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects: editBtn, nil];
    } else {
        self.navigationItem.leftBarButtonItem  = backBtn;
        self.navigationItem.rightBarButtonItem = editBtn;
    }
    
    // Set table editing off
    [self.tableView setEditing: NO];
    
    // ...and hide the add buttons
    [addJobBtn       setHidden: YES];
    [addEducationBtn setHidden: YES];
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
    [self loadViewFromSelectedObject];
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
    _resumeName.Font        = [UIFont preferredFontForTextStyle: UIFontTextStyleHeadline];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        // These UI elements only exist on iPad
        _currentJobTitle.font   = [UIFont preferredFontForTextStyle: UIFontTextStyleHeadline];
        _atLabel.font           = [UIFont preferredFontForTextStyle: UIFontTextStyleHeadline];
        _currentJobName.font    = [UIFont preferredFontForTextStyle: UIFontTextStyleHeadline];
    }
    _resumeStreet1.font     = [UIFont preferredFontForTextStyle: UIFontTextStyleBody];
    _resumeCity.font        = [UIFont preferredFontForTextStyle: UIFontTextStyleBody];
    _resumeState.font       = [UIFont preferredFontForTextStyle: UIFontTextStyleBody];
    _resumePostalCode.font  = [UIFont preferredFontForTextStyle: UIFontTextStyleBody];
    _resumeHomePhone.font   = [UIFont preferredFontForTextStyle: UIFontTextStyleBody];
    _hmLabel.font           = [UIFont preferredFontForTextStyle: UIFontTextStyleBody];
    _resumeMobilePhone.font = [UIFont preferredFontForTextStyle: UIFontTextStyleBody];
    _mbLabel.font           = [UIFont preferredFontForTextStyle: UIFontTextStyleBody];
    _resumeEmail.font       = [UIFont preferredFontForTextStyle: UIFontTextStyleBody];
    _resumeSummary.font     = [UIFont preferredFontForTextStyle: UIFontTextStyleBody];
    
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
    _selectedResume.name           = _resumeName.text;
    _selectedResume.street1        = _resumeStreet1.text;
    _selectedResume.city           = _resumeCity.text;
    _selectedResume.state          = _resumeState.text;
    _selectedResume.postal_code    = _resumePostalCode.text;
    _selectedResume.home_phone     = _resumeHomePhone.text;
    _selectedResume.mobile_phone   = _resumeMobilePhone.text;
    _selectedResume.email          = _resumeEmail.text;
    _selectedResume.summary        = _resumeSummary.text;
    
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
    [addJobBtn          setHidden: !isEditingMode];
    [addEducationBtn    setHidden: !isEditingMode];
    
    // ...enable/disable table editing
    [self.tableView setEditing: isEditingMode
                      animated: YES];
    // ...enable/disable resume fields
    [self setFieldsEditable: isEditingMode];
    
    if (isEditingMode) {
        // Set up the navigation items and save/cancel buttons
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects: saveBtn, cancelBtn, nil];
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
    
    // Use the tag of the sender UIButton to prompt for the appropriate entity name.
    switch ([(UIButton *)sender tag]) {
        case k_JobsSection:
            [self promptForJobName];
            break;

        case k_EducationSection:
            [self promptForEducationName];
            break;
            
        default:
            ALog(@"unexpected tag=%@", @([(UIButton *)sender tag]));
            break;
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
    for (int i = 0; i < [_jobArray count]; i++) {
        if ([[_jobArray objectAtIndex: i] isDeleted]) {
            // no need to update the sequence number of deleted objects
        } else {
            [[_jobArray objectAtIndex:i] setSequence_numberValue: i];
        }
    }
    // ...same for the education array
    for (int i = 0; i < [_educationArray count]; i++) {
        if ([[_educationArray objectAtIndex: i] isDeleted]) {
            // no need to update the sequence number of deleted objects
        } else {
            [[_educationArray objectAtIndex:i] setSequence_numberValue: i];
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
                                                inSection: k_JobsSection];
    
    /*
     Insert rows in the receiver at the locations identified by an array of index paths, with an option to
     animate the insertion.
     
     UITableView calls the relevant delegate and data source methods immediately afterwards to get the cells 
     and other content for visible cells.
     */
    // Animate the insertion of the new row
    [self.tableView insertRowsAtIndexPaths: [NSArray arrayWithObject: indexPath]
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
    UIAlertView *jobNameAlert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Enter Job Name", nil)
                                                           message: nil
                                                          delegate: self
                                                 cancelButtonTitle: NSLocalizedString(@"Cancel", nil)
                                                 otherButtonTitles: NSLocalizedString(@"OK", nil), nil];
    jobNameAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
    jobNameAlert.tag            = k_JobsSection;
    
    [jobNameAlert show];
}


//----------------------------------------------------------------------------------------------------------
/**
 Add a Jobs entity for this resume.
 */
- (void)addEducation
{
    DLog();
    
    // Insert a new Education entity into the managedObjectContext
    Education *education = (Education *)[NSEntityDescription insertNewObjectForEntityForName: kOCREducationEntity
                                                                      inManagedObjectContext: [kAppDelegate managedObjectContext]];
    // Set the name to the value the user provided in the prompt
    education.name            = _nuEntityName;
    // ...the created timestamp to now
    education.created_date    = [NSDate date];
    // ...and the resume link to this resume
    education.resume          = _selectedResume;
    
    // Insert the newly created entity into the array in the first (zero-ith) position
    [_educationArray insertObject: education
                          atIndex: 0];
    // ...and resequence the Jobs and Education objects
    [self resequenceTables];
    
    // Construct an indexPath
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow: 0
                                                inSection: k_EducationSection];
    
    // Animate the insertion of the new row
    [self.tableView insertRowsAtIndexPaths: [NSArray arrayWithObject: indexPath]
                          withRowAnimation: UITableViewRowAnimationFade];
    // ...and scroll the tableView back to the top to ensure the user can see the result of adding the Job
    [self.tableView scrollToRowAtIndexPath: indexPath
                          atScrollPosition: UITableViewScrollPositionTop
                                  animated: YES];
}


//----------------------------------------------------------------------------------------------------------
/**
 Prompts the user to enter a name for the new Education entity.
 */
- (void)promptForEducationName
{
    DLog();
    
    // Display an alert to get the Education name. Note the cancel button is available.
    UIAlertView *educationNameAlert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Enter Institution Name", @"A University or Certificate issuing organization")
                                                                 message: nil
                                                                delegate: self
                                                       cancelButtonTitle: NSLocalizedString(@"Cancel", nil)
                                                       otherButtonTitles: NSLocalizedString(@"OK", nil), nil];
    educationNameAlert.alertViewStyle   = UIAlertViewStylePlainTextInput;
    educationNameAlert.tag              = k_EducationSection;
    
    [educationNameAlert show];
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
        // Use the tag to determine which entity is being added
        if (alertView.tag == k_JobsSection) {
            [self addJob];
        } else {
            [self addEducation];
        }
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
 @returns               The number of sections in tableView. The default value is 1.
 */
- (NSInteger)numberOfSectionsInTableView: (UITableView *)tableView
{
    DLog();
    
    // We have two sections in our table
    return 2;
}


//----------------------------------------------------------------------------------------------------------
/**
 Asks the data source to verify that the given row is editable.
 
 @param tableView       The table-view object requesting this information.
 @param indexPath       An index path locating a row in tableView.
 @returns               YES to allow editing, NO otherwise,
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
 @returns               An object inheriting from UITableViewCell that the table view can use for the specified row.
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
 Configure a cell for the resume.
 
 @param cell        A cell to configure.
 @param indexPath   The indexPath of the section and row the cell represents.
 */
- (void)configureCell: (UITableViewCell *)cell
          atIndexPath: (NSIndexPath *)indexPath
{
    DLog();

    switch (indexPath.section) {
		case k_JobsSection:
            // We're in the Jobs section,
            // ...set the title text content and dynamic text font
			cell.textLabel.text         = [[_jobArray objectAtIndex: indexPath.row] name];
            cell.textLabel.font         = [UIFont preferredFontForTextStyle: UIFontTextStyleHeadline];
            // ...the detail text content and dynamic text font
            cell.detailTextLabel.text   = [[_jobArray objectAtIndex: indexPath.row] title];
            cell.detailTextLabel.font   = [UIFont preferredFontForTextStyle: UIFontTextStyleSubheadline];
            // ...and the accessory disclosure indicator
			cell.accessoryType          = UITableViewCellAccessoryDisclosureIndicator;
			break;
		case k_EducationSection:
            // We're in the Eduction and Certifications section,
            // ...set the title text content and dynamic text font
			cell.textLabel.text         = [[_educationArray objectAtIndex: indexPath.row] name];
            cell.textLabel.font         = [UIFont preferredFontForTextStyle: UIFontTextStyleHeadline];
            // ...the detail text content and dynamic text font
            cell.detailTextLabel.text   = [[_educationArray objectAtIndex: indexPath.row] title];
            cell.detailTextLabel.font   = [UIFont preferredFontForTextStyle: UIFontTextStyleSubheadline];
            // ...and the accessory disclosure indicator
			cell.accessoryType          = UITableViewCellAccessoryDisclosureIndicator;
			break;
		default:
			ALog(@"Unexpected section = %ld", (long)indexPath.section);
			break;
	}
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
        if (indexPath.section == k_JobsSection) {
            NSManagedObject *jobToDelete = [_jobArray objectAtIndex: indexPath.row];
            [[kAppDelegate managedObjectContext] deleteObject: jobToDelete];
            [_jobArray removeObjectAtIndex: indexPath.row];
        } else {
            NSManagedObject *jobToDelete = [_educationArray objectAtIndex: indexPath.row];
            [[kAppDelegate managedObjectContext] deleteObject: jobToDelete];
            [_educationArray removeObjectAtIndex: indexPath.row];
        }
        // ...delete the object from the tableView
        [tableView deleteRowsAtIndexPaths: [NSArray arrayWithObject: indexPath]
                         withRowAnimation: UITableViewRowAnimationFade];
        // ...and reload the table
        [tableView reloadData];
    } else {
        DLog(@"editingStyle=%@", [NSNumber numberWithInt: editingStyle]);
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
    
    if (toIndexPath.section == k_JobsSection) {
        // Get the Job at the fromRow
        Jobs *movedJob = [_jobArray objectAtIndex: fromRow];
        // ...remove it from that "order"
        [_jobArray removeObjectAtIndex: fromRow];
        // ...and insert it where the user wants
        [_jobArray insertObject: movedJob
                        atIndex: toRow];
    } else {
        // Get the Education at the fromRow
        Education *movedEducation = [_educationArray objectAtIndex: fromRow];
        // ...remove it from that "order"
        [_educationArray removeObjectAtIndex: fromRow];
        // ...and insert it where the user wants
        [_educationArray insertObject: movedEducation
                              atIndex: toRow];
    }
}


//----------------------------------------------------------------------------------------------------------
/**
 Tells the data source to return the number of rows in a given section of a table view.
 
 @param tableView       The table-view object requesting this information.
 @param section         An index number identifying a section in tableView.
 @returns               The number of rows in section.
 */
- (NSInteger)tableView: (UITableView *)tableView
 numberOfRowsInSection: (NSInteger)section
{
    DLog(@"section=%ld", (long)section);
    
    /*
     From a style perspective, I prefer that methods "leave" at the end, so I tend to instantiate a variable
     to return whatever the method returns, set its value where appropriate, and "fall thru" to the end of
     the method.
     There is nothing wrong with sprinkling return statements throughout the method - e.g., return [_jobArray count];
     it's just my preference.
     */
    NSInteger rowsInSection;
    
	switch (section) {
		case k_JobsSection:
			rowsInSection = [_jobArray count];
			break;
		case k_EducationSection:
			rowsInSection = [_educationArray count];
			break;
		default:
			ALog(@"Unexpected section = %ld", (long)section);
			rowsInSection = 0;
			break;
	}
    
    return rowsInSection;
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
    switch (indexPath.section) {
		case k_JobsSection: {
            DLog(@"Job selected");
            // Segue to the job
//			JobsDetailViewController *detailVC = [[JobsDetailViewController alloc] initWithNibName: KOJobsDetailViewController
//                                                                                            bundle: nil];
//			// Pass the selected object to the new view controller.
//			detailVC.title                      = NSLocalizedString(@"Jobs", nil);
//			detailVC.selectedJob                = [self.jobArray objectAtIndex: indexPath.row];
//            detailVC.managedObjectContext       = self.managedObjectContext;
//            detailVC.fetchedResultsController   = self.fetchedResultsController;
//
//			[self.navigationController pushViewController: detailVC
//                                                 animated: YES];
			break;
		}
		case k_EducationSection: {
            DLog(@"Education selected");
            // Segue to the education
//			EducationViewController *educationVC = [[EducationViewController alloc] initWithNibName: KOEducationViewController
//                                                                                             bundle: nil];
//			// Pass the selected object to the new view controller.
//            educationVC.selectedEducation           = [self.educationArray objectAtIndex: indexPath.row];
//            educationVC.managedObjectContext        = self.managedObjectContext;
//            educationVC.fetchedResultsController    = self.fetchedResultsController;
//			educationVC.title                       = NSLocalizedString(@"Education", nil);
//
//			[self.navigationController pushViewController: educationVC
//                                                 animated: YES];
			break;
		}
		default:
			break;
	}
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
 @returns               A nonnegative floating-point value that specifies the height (in points) of the header 
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
 @returns               A nonnegative floating-point value that specifies the height (in points) that row should be.
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
 @returns               A view object to be displayed in the header of section .
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
    
    // Finally, set the text content and save a reference to the respective add buttons so they can be
    // shown or hidden whenever the user turns editing mode on or off
	switch (section) {
		case k_JobsSection: {
			headerView.sectionLabel.text    = NSLocalizedString(@"Professional History", nil);
            addJobBtn                       = headerView.addButton;
            break;
		}
		case k_EducationSection: {
			headerView.sectionLabel.text    = NSLocalizedString(@"Education & Certifications", nil);
            addEducationBtn                 = headerView.addButton;
            break;
		}
		default:
			ALog(@"Unexpected section = %ld", (long)section);
	}
    
    return wrapperView;
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
    CGSize kbSize = [[info objectForKey: UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
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
 @returns               YES if an editing session should be initiated; otherwise, NO to disallow editing.
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
            [_tableView insertRowsAtIndexPaths: [NSArray arrayWithObject: newIndexPath]
                              withRowAnimation: UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            // Delete a row
            [_tableView deleteRowsAtIndexPaths: [NSArray arrayWithObject:indexPath]
                              withRowAnimation: UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            // Underlying contents have changed, re-configure the cell
            [self configureCell: [_tableView cellForRowAtIndexPath: indexPath]
                    atIndexPath: indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            // On a move, delete the rows where they were...
            [_tableView deleteRowsAtIndexPaths: [NSArray arrayWithObject: indexPath]
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
    
    [self.resumeSummary setContentOffset: CGPointZero
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
