//
//  OCRResumeJobsDetailViewController.m
//  KOResume
//
//  Created by Kevin O'Mara on 4/6/14.
//  Copyright (c) 2014 O'Mara Consulting Associates. All rights reserved.
//

#import "OCRResumeJobsDetailViewController.h"
#import "OCRTableViewHeaderCell.h"
#import "OCRAppDelegate.h"
#import "Jobs.h"
#import "Resumes.h"
#import "Accomplishments.h"
#import "SVWebViewController.h"
#import "OCRNoSelectionViewController.h"
#import "OCRAccomplishmentTableViewCell.h"
#import "OCRDatePickerViewController.h"

#define kJobStartDateFieldTag           6
#define kJobEndDateFieldTag             7

#define k_OKButtonIndex                 1

@interface OCRResumeJobsDetailViewController ()
{
@private
    /**
     Reference to the cancel button to facilitate swapping buttons between display and edit modes.
     */
    UIBarButtonItem     *cancelBtn;
    
    /**
     Reference to the active UITextField
     */
    UITextField         *activeField;
    
    /**
     Convenience reference to the managed object instance we are managing.
     
     OCRBaseDetailViewController, of which this is a subclass, declares a selectedManagedObject. We make this
     type-correct reference merely for convenience.
     */
    Jobs                *selectedJob;
    
    /**
     Reference to the date formatter object.
     */
    NSDateFormatter     *dateFormatter;
    
    /**
     Reference to the button available in table edit mode that allows the user to add an Accomplishment.
     */
    UIButton            *addObjectBtn;
}

/**
 Reference to the fetchResultsController.
 */
@property (nonatomic, strong) NSFetchedResultsController        *accFetchedResultsController;

/**
 Reference to the noSelection view, which is displayed when there is no object to manage, or a
 containing parent object is deleted.
 */
@property (strong, nonatomic) OCRNoSelectionViewController      *noSelectionView;

/**
 Reference to the date picker view controller.
 
 We keep a reference so we can dismiss it in horizontal compact size, where it is presented as a modal.
 */
@property (nonatomic, strong) OCRDatePickerViewController       *datePickerController;

@end


@implementation OCRResumeJobsDetailViewController

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
    
    /*
     From http://spin.atomicobject.com/2014/03/05/uiscrollview-autolayout-ios/
     
     I feel this is a work-around to a poor implementation of autolayout with scrollview - perhaps Apple
     will come up with a better Storyboard/IB paradigm in a later Beta of Xcode 6.
     
     Bascially, the above post points out that the "content view" (contained in our scrollView) needs to
     be pinned to the scrollView's superview (self.view) - which cannot be done in IB.
     */
    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem: self.contentView
                                                                      attribute: NSLayoutAttributeLeading
                                                                      relatedBy: NSLayoutRelationEqual
                                                                         toItem: self.view
                                                                      attribute: NSLayoutAttributeLeading
                                                                     multiplier: 1.0
                                                                       constant: 0];
    [self.view addConstraint: leftConstraint];
    
    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem: self.contentView
                                                                       attribute: NSLayoutAttributeTrailing
                                                                       relatedBy: NSLayoutRelationEqual
                                                                          toItem: self.view
                                                                       attribute: NSLayoutAttributeTrailing
                                                                      multiplier: 1.0
                                                                        constant: 0];
    [self.view addConstraint: rightConstraint];
    
    // For convenience, make a type-correct reference to the Jobs object we're working on
    selectedJob = (Jobs *)self.selectedManagedObject;
    
    // Set the default button title
    self.backButtonTitle = NSLocalizedString(@"Packages", nil);
    
    // Initialize estimate row height to support dynamic text sizing
    self.tableView.estimatedRowHeight = kOCRAccomplishmentTableViewCellDefaultHeight;
    
    // Set up button items
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
    
    // Configure the view
    [self configureView];
    
    // ...and the NavBar
    [self configureDefaultNavBar];
    
    // Turn off editing in the UI
    [self configureUIForEditing: NO];
}


//----------------------------------------------------------------------------------------------------------
/**
 Returns the title to use in the UInavigationBar.
 
 @return navigationBarTitle     The view's title.
 */
- (NSString *)navigationBarTitle
{
    return NSLocalizedString(@"Resume", nil);
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
    
    // ...add an observer for keyboard notifications
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
 Update the text fields of the view from the selected managed object.
 */
- (void)loadViewFromSelectedObject
{
    DLog();
    
    // Load the Jobs object into the view
    if ([[(Jobs *)self.selectedManagedObject resume] package])
    {
        // We have a selected object with data; remove the noSelectionView if present
        if (self.noSelectionView)
        {
            // No selection view is on-screen, remove it from the view
            [self.noSelectionView removeFromParentViewController];
            [self.noSelectionView.view removeFromSuperview];
            // ...and nil the reference
            self.noSelectionView = nil;
            // Enable the edit button
            [self.editButtonItem setEnabled: YES];
       }
        // Populate the UI with content from our managedObject
        [self populateFieldsFromSelectedObject];
    }
    else
    {
        // Check to see if we already have a no selection view up
        if ( !self.noSelectionView)
        {
            // Create a OCRNoSelectionView and add it to our view
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName: @"Main_iPad"
                                                                 bundle:nil];
            self.noSelectionView = [storyboard instantiateViewControllerWithIdentifier: kOCRNoSelectionViewController];
            [self addChildViewController: self.noSelectionView];
            [self.view addSubview: self.noSelectionView.view];
            [self.noSelectionView didMoveToParentViewController: self];
            // Disable the edit button
            [self.editButtonItem setEnabled: NO];
        }
        
        if (self.selectedManagedObject)
        {
            // We have a selected object, but no data - allow editing
            [self.editButtonItem setEnabled: YES];
            self.noSelectionView.messageLabel.text = NSLocalizedString(@"Press Edit to enter information.", nil);
        }
        else
        {
            // Nothing is selected
            [self.editButtonItem setEnabled: NO];
            self.noSelectionView.messageLabel.text = NSLocalizedString(@"Nothing selected.", nil);
        }
    }
}


//----------------------------------------------------------------------------------------------------------
/**
 Populate the user interface fields with data from the object we are managing.
 */
- (void)populateFieldsFromSelectedObject
{
    DLog();
    
    /*
     It's important to set the placeholder text in case the data field is "empty" because we are using
     autolayout. If both the field and place holders are empty it will have zero width in the UI, and
     when the user presses the "edit" button they would not be able to get a cursor inside any of the
     empty fields.
     */
    // For each of the tableHeaderView's text fields, set either it's text or placeholder property
    [_jobName setText: selectedJob.name
        orPlaceHolder: NSLocalizedString(@"Company name", nil)];
    
    [_jobCity setText: selectedJob.city
        orPlaceHolder: NSLocalizedString(@"City", nil)];
    [_jobTitle setText: selectedJob.title
         orPlaceHolder: NSLocalizedString(@"Job title", nil)];
    [_jobUri setText: selectedJob.uri
       orPlaceHolder: NSLocalizedString(@"Companny url", nil)];
    
    [_jobState setText: selectedJob.state
         orPlaceHolder: NSLocalizedString(@"ST", nil)];
    
    /* 
     We set the job's start_date to an initial value when the job entity is created (in OCRResumeJobsTableViewController,
     so we are guaranteed to always have a valid date. Just format it for display and don't worry about a placeHolder.
     */
    self.jobStartDate.text = [dateFormatter stringFromDate: selectedJob.start_date];
    /*
     However, the end date is a different matter. If there is no end date, we assume this is a "current" job and
     display "Current" in the textField. Still, as with start_date, there is no placeHolder text - we set the text of
     the jobEndDate UITextField to either the end_date from the job entity, or the (localized) literal "Current".
     */
    if (selectedJob.end_date)
    {
        self.jobEndDate.text = [dateFormatter stringFromDate: selectedJob.end_date];
    }
    else
    {
        self.jobEndDate.text = NSLocalizedString(@"Current", nil);
    }
    
    /*
     jobSummary is a textView, and always has width and height, so the autolayout concern mentioned
     above is not a concern here.
     */
    _jobSummary.text = selectedJob.summary;
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
- (void)configureFieldsForEditing: (BOOL)editable
{
    DLog();
    
    if (self.noSelectionView)
    {
        // No selection view is on-screen, remove it from the view
        [self.noSelectionView removeFromParentViewController];
        [self.noSelectionView.view removeFromSuperview];
        // ...and nil the reference
        self.noSelectionView = nil;
    }
    
    // Set all the text fields enable property (and text view's editable)
    [_jobName      setEnabled: editable];
    [_jobTitle     setEnabled: editable];
    // For the uri, we use an info button when we are not editing, and a text field when we are
    if (editable)
    {
        [_infoButton setHidden: YES];
        [_jobUri setHidden: NO];
    }
    else
    {
        [_infoButton setHidden: NO];
        [_jobUri setHidden: YES];
    }
    [_jobCity      setEnabled: editable];
    [_jobState     setEnabled: editable];
    [_jobStartDate setEnabled: editable];
    [_jobEndDate   setEnabled: editable];
    // jobSummary is a UITextView and has an editable property whereas UITextFields have an enabled property
    [_jobSummary   setEditable: editable];
    
    // Determine the background color for the fields based on the editable param
    UIColor *backgroundColor = editable? [self.view.tintColor colorWithAlphaComponent:0.1f] : [UIColor clearColor];
    
    // ...and set the background color
    [_jobName      setBackgroundColor: backgroundColor];
    [_jobTitle     setBackgroundColor: backgroundColor];
    [_jobUri       setBackgroundColor: backgroundColor];
    [_jobCity      setBackgroundColor: backgroundColor];
    [_jobState     setBackgroundColor: backgroundColor];
    [_jobStartDate setBackgroundColor: backgroundColor];
    [_jobEndDate   setBackgroundColor: backgroundColor];
    [_jobSummary   setBackgroundColor: backgroundColor];
    
    // Reload the accomplishments table so the cells are configured for editing
    /*
     We are using reloadRowsAtIndexPaths:withRowAnimation: to reload on the table cells that are currently visible.
     
     In the case of a typical resume, there simply won't be a large number of job rows so a simple reloadData: would
     be fine. However, if the tableview could contain hundreds or more cells, this technique would be highly
     recommended.
     */
    [self.tableView reloadRowsAtIndexPaths: [self.tableView indexPathsForVisibleRows]
                          withRowAnimation: UITableViewRowAnimationFade];
}


//----------------------------------------------------------------------------------------------------------
/**
 Configure the default items for the navigation bar.
 */
- (void)configureDefaultNavBar
{
    DLog();
    
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
        self.tabBarController.navigationItem.title = [self navigationBarTitle];
        // ...and edit button
        self.tabBarController.navigationItem.rightBarButtonItems = @[self.editButtonItem];
    }
    else
    {
        self.navigationItem.title               = [self navigationBarTitle];
        self.navigationItem.rightBarButtonItems = @[self.editButtonItem];
    }
    
    // Set table editing off
    [self.tableView setEditing: NO];
    
    // ...and hide the add buttons
    [addObjectBtn setHidden: YES];
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


//----------------------------------------------------------------------------------------------------------
/**
 Update internal state of the view controller when a package has been deleted.
 
 Invoked by notification posted by OCRPackagesViewController when it performs a package deletion.
 
 @param aNotification   The NSNotification object associated with the event.
 */
- (void)packageWasDeleted: (NSNotification *)aNotification
{
    DLog();
    
    if ( ![(Resumes *)[(Jobs *)self.selectedManagedObject resume] package] ||
        [self.selectedManagedObject isDeleted])
    {
        self.selectedManagedObject = nil;
        [self reloadFetchedResults: nil];
        [self loadViewFromSelectedObject];
        [self.tableView reloadData];
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
    _jobName.font       = [UIFont preferredFontForTextStyle: UIFontTextStyleHeadline];
    _jobTitle.font      = [UIFont preferredFontForTextStyle: UIFontTextStyleBody];
    _jobUri.font        = [UIFont preferredFontForTextStyle: UIFontTextStyleBody];
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
 Called when the user presses the "+" button in the section header.
 
 @param sender          The button pressed.
 */
- (IBAction)didPressAddButton: (id)sender
{
    DLog();
    
    // Set up a UIAlertController to get the user's input
    UIAlertController *alert = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"Enter Accomplishmet Name", nil)
                                                                   message: nil
                                                            preferredStyle: UIAlertControllerStyleAlert];
    // Add a text field to the alert
    [alert addTextFieldWithConfigurationHandler: ^(UITextField *textField) {
        textField.placeholder = NSLocalizedString(@"Accomplishment short description", nil);
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
    __weak OCRResumeJobsDetailViewController *weakself = self;
    [alert addAction: [UIAlertAction actionWithTitle: NSLocalizedString(@"OK", nil)
                                               style: UIAlertActionStyleDefault
                                             handler: ^(UIAlertAction *action) {
                                                 __strong OCRResumeJobsDetailViewController *strongSelf = weakself;
                                                 // Get the Accomplishment name from the alert and pass it to addAccomplishment
                                                 [strongSelf addAccomplishment: ((UITextField *) alert.textFields[0]).text];
                                             }]];
    
    // ...and present the alert to the user
    [self presentViewController: alert
                       animated: YES
                     completion: nil];
}


//----------------------------------------------------------------------------------------------------------
/**
 Add an Accomplishments entity for this resume.
 
 @param accomplishmentName      The name to assign to the new entity.
 */
- (void)addAccomplishment: (NSString *)accomplishmentName
{
    DLog();
    
    // Insert a new Jobs entity into the managedObjectContext
    Accomplishments *accomplishment = (Accomplishments *)[NSEntityDescription insertNewObjectForEntityForName:  kOCRAccomplishmentsEntity
                                                                                       inManagedObjectContext: [kAppDelegate managedObjectContext]];
    
    // Set the name to the value the user provided in the prompt
    accomplishment.name            = accomplishmentName;
    // ...the created timestamp to now
    accomplishment.created_date    = [NSDate date];
    // ...and the resume link to the resume we are managing
    accomplishment.job              = selectedJob;
    // ...and set its sequence_number to be the last object
    accomplishment.sequence_numberValue  = [[self.accFetchedResultsController fetchedObjects] count] + 1;
    
    // Save the context so the adds are pushed to the persistent store
    [kAppDelegate saveContextAndWait];
    // ...and reload the fetchedResults to bring them into memory
    [self reloadFetchedResults: nil];
    
    // Update the tableView with the new object
    // Construct an indexPath to insert the new object at the end
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow: [[self.accFetchedResultsController fetchedObjects] count] - 1
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
 @param animated    If YES, animates the transition; otherwise, does not.
 */
- (void)setEditing: (BOOL)editing
          animated: (BOOL)animated
{
    DLog(@"editing=%@", editing? @"YES" : @"NO");
    [super setEditing: editing
             animated: animated];
    
    if (editing)
    {
        // Start an undo group...it will either be commited here when the User presses Done, or
        //    undone in didPressCancelButton
        [[[kAppDelegate managedObjectContext] undoManager] beginUndoGrouping];
        // ...and add a cancel button to the nav bar
        [self addCancelBtn: cancelBtn];
    }
    else
    {
        // Save the changes
        [self updateSelectedObjectFromUI];

        // The user pressed "Done", end the undo group
        [[[kAppDelegate managedObjectContext] undoManager] endUndoGrouping];
        
        // ...save changes to the database
        [kAppDelegate saveContextAndWait];
        
        // ...cleanup the undoManager
        [[[kAppDelegate managedObjectContext] undoManager] removeAllActionsWithTarget: self];
        
        // Reload the fetched results
        [self reloadFetchedResults: nil];
        
        // Remove the cancel button from the nav bar
        [self removeCancelBtn: cancelBtn];
    }
    
    // Configure the UI to represent the editing state we are entering
    [self configureUIForEditing: editing];
}


//----------------------------------------------------------------------------------------------------------
/**
 Update the selected object's properties from the view's data fields
 */
- (void)updateSelectedObjectFromUI
{
    DLog();
    
    selectedJob.name           = _jobName.text;
    selectedJob.title          = _jobTitle.text;
    selectedJob.uri            = _jobUri.text;
    selectedJob.city           = _jobCity.text;
    selectedJob.state          = _jobState.text;
    selectedJob.start_date     = [dateFormatter dateFromString: _jobStartDate.text];
    if ([_jobStartDate.text isEqualToString: @"Current"])
    {
        selectedJob.end_date   = nil;
    }
    else
    {
        selectedJob.end_date   = [dateFormatter dateFromString: _jobEndDate.text];
    }
    selectedJob.summary        = _jobSummary.text;
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
    // ...turn off editing in the UI
    [self configureUIForEditing: NO];
    // ...and remove the cancel button from the nav bar
    [self removeCancelBtn: cancelBtn];
}


//----------------------------------------------------------------------------------------------------------
/**
 Set the UI for for editing enabled or disabled.
 
 Called when the user presses the Edit, Done, or Cancel buttons.
 
 @param isEditingMode   YES if we are going into edit mode, NO otherwise.
 */
- (void)configureUIForEditing: (BOOL)editing
{
    DLog();
    
    // Set the add button hidden state (hidden should be the boolean opposite of isEditingMode)
    [addObjectBtn setHidden: !editing];
    
    // ...enable/disable resume fields
    [self configureFieldsForEditing: editing];
    
    // ...enable/disable table view editing
    [self.tableView setEditing: editing];
    
    if (editing)
    {
        // Add the cancel button to the nav bar
        [self addCancelBtn: cancelBtn];
    }
    else
    {
        // Remove the cancel button from the nav bar
        [self removeCancelBtn: cancelBtn];
    }
}


- (void)addCancelBtn: (UIBarButtonItem *)cancelButtonItem
{
    DLog();
    
    /*
     In iOS8 Apple has bridged much of the gap between iPhone and iPad. However some differences persist.
     Our view controller is embedded in a UITabBarController. On the iPhone, the tabBar owns the navigation bar,
     whereas the on iPad, the our view controller owns the navigation bar.
     */
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        // Make a mutably copy of the rightBarButtonItems
        NSMutableArray *rightBarButtonItems = [self.tabBarController.navigationItem.rightBarButtonItems mutableCopy];
        // If the cancel button is not in the rightBarButtonItems,
        if ( ![rightBarButtonItems containsObject: cancelButtonItem])
        {
            // ...add the cancel button to the array copy
            [rightBarButtonItems addObject: cancelBtn];
            // ...and set it in the navigation bar
            [self.tabBarController.navigationItem setRightBarButtonItems: rightBarButtonItems];
        }
    }
    else
    {
        // Same as above, except the navigation bar is owned by this view controller, not the tabBarController
        NSMutableArray *rightBarButtonItems = [self.navigationItem.rightBarButtonItems mutableCopy];
        if ( ![rightBarButtonItems containsObject: cancelButtonItem])
        {
            [rightBarButtonItems addObject: cancelBtn];
            [self.navigationItem setRightBarButtonItems: rightBarButtonItems];
        }
    }
}

- (void)removeCancelBtn:  (UIBarButtonItem *)cancelButtonItem
{
    DLog();
    
    /*
     In iOS8 Apple has bridged much of the gap between iPhone and iPad. However some differences persist.
     Our view controller is embedded in a UITabBarController. On the iPhone, the tabBar owns the navigation bar,
     whereas the on iPad, the our view controller owns the navigation bar.
     */
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        // Make a mutably copy of the rightBarButtonItems
        NSMutableArray *rightBarButtonItems = [self.tabBarController.navigationItem.rightBarButtonItems mutableCopy];
        // Remove the cancel button from the array copy
        [rightBarButtonItems removeObject: cancelButtonItem];
        // ...and set it in the navigation bar
        [self.tabBarController.navigationItem setRightBarButtonItems: rightBarButtonItems];
    }
    else
    {
        // Same as above, except the navigation bar is owned by this view controller, not the tabBarController
        NSMutableArray *rightBarButtonItems = [self.navigationItem.rightBarButtonItems mutableCopy];
        [rightBarButtonItems removeObject: cancelButtonItem];
        [self.navigationItem setRightBarButtonItems: rightBarButtonItems];
    }
}


//----------------------------------------------------------------------------------------------------------
/*
 API documentation is in .h file. (See above comment).
 */
- (IBAction)didPressInfoButton:(id)sender
{
    DLog();
    
    if (self.isEditing)
    {
        [self promptForJobUri];
    }
    else
    {
        // Open the job.uri in a UIWebView.
        // First, check to see if we have something that looks like a URI
        if (selectedJob.uri == NULL ||
           [selectedJob.uri rangeOfString: @"://"].location == NSNotFound)
        {
            // Not a valid URI
            return;
        }
        
        // Open the Url in an application webView
        SVModalWebViewController *webViewController = [[SVModalWebViewController alloc] initWithAddress: selectedJob.uri];
        [self presentViewController: webViewController
                           animated: YES
                         completion: nil];
    }
}


//----------------------------------------------------------------------------------------------------------
/**
 Prompts the user to enter a name for the new Jobs entity.
 */
- (void)promptForJobUri
{
    DLog();

    // Set up a UIAlertController to get the user's input
    UIAlertController *alert = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"Enter URL", nil)
                                                                   message: nil
                                                            preferredStyle: UIAlertControllerStyleAlert];
    // Add a text field to the alert
    [alert addTextFieldWithConfigurationHandler: ^(UITextField *textField) {
        textField.placeholder = NSLocalizedString(@"Website address", nil);
    }];
    
    // ...add a cancel action
    [alert addAction: [UIAlertAction actionWithTitle: NSLocalizedString(@"Cancel", nil)
                                               style: UIAlertActionStyleDefault
                                             handler: nil]];
    // ...and an OK action
    [alert addAction: [UIAlertAction actionWithTitle: NSLocalizedString(@"OK", nil)
                                               style: UIAlertActionStyleDefault
                                             handler: ^(UIAlertAction *action) {
                                                 // Get the uri from the alert and update the uri field
                                                 selectedJob.uri = ((UITextField *) alert.textFields[0]).text;
                                             }]];
    
    // ...and present the alert to the user
    [self presentViewController: alert
                       animated: YES
                     completion: nil];
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
    // Get the section count from the eduFetchedResultsController
    return [[self.accFetchedResultsController sections] count];
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
    // Get the number of objects for the section from the eduFetchedResultsController
    return [[[self.accFetchedResultsController sections] objectAtIndex: section] numberOfObjects];
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
 @return               An object inheriting from UITableViewCell that the table view can use for the specified row.
 An assertion is raised if you return nil.
 */
- (UITableViewCell *)tableView: (UITableView *)tableView
         cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
    DLog();
    
	// Configure an accomplishment cell
    UITableViewCell *cell = [self       tableView: tableView
                              accCellForIndexPath: indexPath];
    
    return cell;
}


//----------------------------------------------------------------------------------------------------------
/**
 Configure a jobs cell for the resume.
 
 @param tableView       A table-view object requesting the cell.
 @param indexPath   The indexPath of the section and row the cell represents.
 @return            A configured table view cell.
 */
- (UITableViewCell *)tableView: (UITableView *)tableView
           accCellForIndexPath: (NSIndexPath *)indexPath
{
    DLog();
    
    // Get an accomplishment cell
    OCRAccomplishmentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: kOCRAccomplishmentTableCell];
    
    // ...and the Accomplishment object the cell will represent
    Accomplishments *accomplishment = [self.accFetchedResultsController objectAtIndexPath: indexPath];
    
    // Determine the background color for the fields based on whether or not we are editing
    UIColor *backgroundColor = self.editing? [self.view.tintColor colorWithAlphaComponent:0.1f] : [UIColor whiteColor];
    
    // ...set the name text content and dynamic text font
    cell.accomplishmentName.text            = accomplishment.name;
    cell.accomplishmentName.font            = [UIFont preferredFontForTextStyle: UIFontTextStyleHeadline];
    cell.accomplishmentName.enabled         = self.editing;
    cell.accomplishmentName.backgroundColor = backgroundColor;
    cell.accomplishmentName.delegate        = self;
    
    // ...the summary text content and dynamic text font
    cell.accomplishmentSummary.text             = accomplishment.summary;
    cell.accomplishmentSummary.font             = [UIFont preferredFontForTextStyle: UIFontTextStyleSubheadline];
    cell.accomplishmentSummary.editable         = self.editing;
    cell.accomplishmentSummary.backgroundColor  = backgroundColor;
    cell.accomplishmentSummary.delegate         = self;
    
    // Make the cell not selectable
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    // ...and the accessory disclosure indicator
    cell.accessoryType              = UITableViewCellAccessoryNone;
    
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
        NSManagedObjectContext *context = [self.accFetchedResultsController managedObjectContext];
        NSManagedObject *objectToDelete = [self.accFetchedResultsController objectAtIndexPath: indexPath];
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
    }
    else
    {
        CLS_LOG(@"Unexpected editingStyle=%d", (int)editingStyle);
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
        [kAppDelegate showWarningWithMessage: NSLocalizedString(@"Sorry, move between sections not allowed.", nil)
                                      target: self];
        [tableView reloadData];
        return;
    }
    
    NSMutableArray *array = [[self.accFetchedResultsController fetchedObjects] mutableCopy];
    
    // Grab the item we're moving.
    NSManagedObject *objectToMove = [self.accFetchedResultsController objectAtIndexPath: fromIndexPath];
    
    // Remove the object we're moving from the array.
    [array removeObject: objectToMove];
    // ...re-insert it at the destination.
    [array insertObject: objectToMove
                atIndex: [toIndexPath row]];
    
    // All of the objects are now in their correct order.
    // Update each object's sequence_number field by iterating through the array.
    int i = 1;
    for (Accomplishments *object in array)
    {
        [object setSequence_numberValue: i++];
    }
    
    /*
     The user may edit cell contents after a move operation. 
     The updateSourceObjectWithTextField:forTableCell:atIndexPath: method expects the table view cells and 
     fetched results to be in the same order, so we must save work in progress and reload. (If the user 
     subsequently cancels, the undo manager will back out the saved work.)
     */
    // Save the re-ordered objects
    [kAppDelegate saveContextAndWait];
    // ...and reload the fetchedResults
    [self reloadFetchedResults: nil];
}


#pragma mark - Table view delegate methods

//----------------------------------------------------------------------------------------------------------
/**
 Tells the delegate that the specified row is now selected.
 
 The delegate handles selections in this method. One of the things it can do is exclusively assign the check-mark
 image (UITableViewCellAccessoryCheckmark) to one row in a section (radio-list style). This method isn’t called
 when the editing property of the table is set to YES (that is, the table view is in editing mode). See "Managing
 Selections" in Table View Programming Guide for iOS for further information (and code examples) related to this 
 method.
 
 @param tableView       A table-view object informing the delegate about the new row selection.
 @param indexPath       An index path locating the new selected row in tableView.
 */
- (void)        tableView: (UITableView *)tableView
  didSelectRowAtIndexPath: (NSIndexPath *)indexPath
{
    // We display and edit all the content of an Accomplishments object in place. Selection not necessary.
    
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
    headerCell.sectionLabel.text    = NSLocalizedString(@"Accomplishments", nil);
    addObjectBtn                    = headerCell.addButton;
    
    // Hide or show the addButton depending on whether we are in editing mode
    [addObjectBtn setHidden: !self.editing];
    
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
    CGSize kbSize = [info[UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    // ...and adjust the contentInset for its height
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    
    self.scrollView.contentInset            = contentInsets;
    self.scrollView.scrollIndicatorInsets   = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    CGRect aRect        = self.view.frame;
    aRect.size.height  -= kbSize.height;
    if (!CGRectContainsPoint(aRect, activeField.frame.origin)) {
        // calculate the contentOffset for the scroller
        [self.scrollView scrollRectToVisible:activeField.frame
                                    animated:YES];
    }
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
    
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    
    self.scrollView.contentInset          = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
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

    // nil activeField - if we have finished editing, there can be no activeField
    activeField = nil;
    
    // Update the source object represented by the activeField
    // ...First, traverse the view heirarchy to get the parentCell of the textField
    UITableViewCell* cell = [self parentCellForView: textView];
    // ...If we found the cell
    if (cell)
    {
        // ...get the indexPath
        NSIndexPath* indexPath = [self.tableView indexPathForCell: cell];
        // ...and update the source object
        /*
         
         */
        [self updateSourceObjectWithString: textView.text
                                    forTag: (int)textView.tag
                               atIndexPath: indexPath];
    }
    
    // Invalidate the contentsize as the contents have changed
    [textView invalidateIntrinsicContentSize];
    // ...and ask the view to update constraints
    [self.view setNeedsUpdateConstraints];
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
    
    // Check to see if the tap occured in a date field
    if (textField.tag == kJobStartDateFieldTag ||
        textField.tag == kJobEndDateFieldTag)
    {
        // Dismiss the keyboard (if any)
        [activeField resignFirstResponder];
        
        // Save a reference to the textField we are working with
        activeField = textField;
        
        // Get the OCRDatePickerViewController from the UIStoryboard
        UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main_iPad"
                                                             bundle:nil];
        // ...and instantiate it
        OCRDatePickerViewController *datePickerController   = [storyBoard instantiateViewControllerWithIdentifier: kOCRDatePickerIdentifier];
        datePickerController.modalPresentationStyle         = UIModalPresentationPopover;
        
        // Get the UIPopoverPresentationController using the iOS8 paradigm
        /*
         See https://developer.apple.com/library/prerelease/ios/documentation/UIKit/Reference/UIPopoverPresentationController_class/index.html
         */
        UIPopoverPresentationController *popoverController = datePickerController.popoverPresentationController;
        // ...set the textField as the view containing the anchor rectangle for the popover
        popoverController.sourceView    = textField;
        // ...and set this object as delegate
        popoverController.delegate      = self;
        
        // Present the view controller.
        [self presentViewController:datePickerController
                           animated:YES
                         completion:nil];
        
        // Check to see if there is something in the date field that is not the string "Current"
        if ((textField.text.length > 0) && ![textField.text isEqualToString:NSLocalizedString(@"Current", nil)])
        {
            // If we already have a date, use it
            DLog(@"textfield=%@", textField.text);
            [datePickerController.datePicker setDate: [dateFormatter dateFromString: textField.text]];
        }
        else
        {
            // Default the date to now
            [datePickerController.datePicker setDate: [NSDate date]];
        }
        
        // Set the target for UIControlEventValueChanged.
        [datePickerController.datePicker addTarget: self
                                            action: @selector(datePickerDidChangeDate:)
                                  forControlEvents: UIControlEventValueChanged];
        
        // Set the preferred content size
        datePickerController.preferredContentSize = CGSizeMake(kOCRDatePickerWidth, kOCRDatePickerHeight);
        
        // Return NO to indicate the textField should not begin editing
        return NO;
    }
    
    return YES;
}


//----------------------------------------------------------------------------------------------------------
/**
 Called by the datePicker when the user changes the date.
 
 @param datePicker      The UIDatePicker managing the date change. Use this object to retrieve the date.
 */
- (void)datePickerDidChangeDate: (UIDatePicker *)datePicker
{
    activeField.text = [dateFormatter stringFromDate: datePicker.date];
    
    // Update the source object represented by the activeField
    // ...First, traverse the view heirarchy to get the parentCell of the textField
    UITableViewCell* cell = [self parentCellForView: activeField];
    // ...If we found the cell
    if (cell)
    {
        // ...get the indexPath
        NSIndexPath* indexPath = [self.tableView indexPathForCell: cell];
        // ...and update the source object
        [self updateSourceObjectWithString: activeField.text
                                    forTag: (int)activeField.tag
                               atIndexPath: indexPath];
    }
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
    int nextTag                 = (int)[textField tag] + 1;
    // ...and attempt to get it using the viewWithTag method
    UIResponder *nextResponder  = [textField.superview viewWithTag: nextTag];
    
    if (nextResponder)
    {
        // If there is a nextResponser, make it firstResponder - i.e., give it focus
        [nextResponder becomeFirstResponder];
    }
    else
    {
        // ...otherwise this textfield must be the last.
        [textField resignFirstResponder];       // Dismisses the keyboard
    }
    
    return NO;              // We always return NO as we are implementing the textField's behavior
}


//----------------------------------------------------------------------------------------------------------
/**
 Tells the delegate that editing began for the specified text field.
 
 This method notifies the delegate that the specified text field just became the first responder. You can use
 this method to update your delegate’s state information. For example, you might use this method to show overlay
 views that should be visible while editing.
 
 Implementation of this method by the delegate is optional.
 
 @param textField       The text field for which an editing session began.
 */
- (void)textFieldDidBeginEditing: (UITextField*)textField
{
    DLog();
    
    // Save a reference to the textField we are editing
    activeField = textField;
}

//----------------------------------------------------------------------------------------------------------
/**
 Tells the delegate that editing of the specified text view has ended.
 
 Implementation of this method is optional. A text view sends this message to its delegate after it closes out
 any pending edits and resigns its first responder status. You can use this method to tear down any data structures
 or change any state information that you set when editing began.
 
 @param textField       The text view in which editing ended.
 */
- (void)textFieldDidEndEditing: (UITextField *)textField
{
    DLog();
    
    // Clear the reference to the text field that was being edited
    activeField = nil;
    
    // Update the source object represented by the activeField
    // ...First, traverse the view heirarchy to get the parentCell of the textField
    UITableViewCell* cell = [self parentCellForView: textField];
    // ...If we found the cell
    if (cell)
    {
        // ...get the indexPath
        NSIndexPath* indexPath = [self.tableView indexPathForCell: cell];
        // ...and update the source object
        [self updateSourceObjectWithString: textField.text
                                    forTag: (int)textField.tag
                               atIndexPath: indexPath];
    }
    
    // Invalidate the contentsize as the contents have changed
    [textField invalidateIntrinsicContentSize];
    // ...and ask the view to update constraints
    [self.view layoutIfNeeded];
}


#pragma mark - UIAdaptivePresentationControllerDelegate methods

//----------------------------------------------------------------------------------------------------------
/**
 Asks the delegate for the new presentation style to use.
 
 The presentation controller calls this method when the app is about to change to a horizontally compact environment.
 Use this method to indicate that you want the presented view controller to transition to one of the full-screen
 presentation styles.
 
 If you do not implement this method or return any style other than UIModalPresentationFullScreen or
 UIModalPresentationOverFullScreen, the presentation controller adjusts the presentation style to the
 UIModalPresentationFullScreen style.
 
 @param controller      The presentation controller that is managing the size change. Use this object to retrieve the
                        view controllers involved in the presentation.
 @return                The new presentation style, which must be either UIModalPresentationFullScreen or
                        UIModalPresentationOverFullScreen.
 */
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController: (UIPresentationController *)controller
{
    return UIModalPresentationFullScreen;
}


//----------------------------------------------------------------------------------------------------------
/**
 Asks the delegate for the view controller to display when adapting to the specified presentation style.
 
 When a size class change causes a change to the underlying presentation style, the presentation controller calls
 this method to ask for the view controller to display in that new style. This method is your opportunity to
 replace the current view controller with one that is better suited for the new presentation style. For example,
 you might use this method to insert a navigation controller into your view hierarchy to facilitate pushing new
 view controllers more easily in the compact environment. In that instance, you would return a navigation controller
 whose root view controller is the currently presented view controller. You could also return an entirely different
 view controller if you prefer.
 
 If you do not implement this method or your implementation returns nil, the presentation controller uses its 
 existing presented view controller.
 
 @param controller      The presentation controller that is managing the size class change.
 @param style           The new presentation style that is about to be employed to display the view controller.
 @return                The view controller to display in place of the existing presented view controller.
 */
- (UIViewController *)presentationController: (UIPresentationController *)controller
  viewControllerForAdaptivePresentationStyle: (UIModalPresentationStyle)style
{
    DLog(@"presentedViewController class=%@", [controller.presentedViewController class]);
    
    // Save a reference to the OCRDatePickerViewController so we can dismiss it when the user taps the Done button
    self.datePickerController = (OCRDatePickerViewController *)controller.presentedViewController;
    
    // Instantiate a navigation controller with the OCRDatePickerViewController as root.
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController: controller.presentedViewController];
    
    // ...create a done button
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
                                                                                target: self
                                                                                action: @selector(didPressDoneButton:)];
    // ...and install it as the right button
    navController.topViewController.navigationItem.rightBarButtonItem = doneButton;
    
    // Set the title
    navController.topViewController.title = NSLocalizedString( @"Earned Date", nil);
    
    return navController;
}


//----------------------------------------------------------------------------------------------------------
/**
 Called when the user taps the Done button of a presented OCRDatePickerViewController.
 
 @param sender          The object initiating the dismiss action (the Done UIBarButtonItem).
 */
- (void)didPressDoneButton: (id)sender
{
    DLog(@"sender=%@", [sender class]);
    
    // Tell the datePickerController to dismiss
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        /*
         In iOS8 Apple has bridged much of the gap between iPhone and iPad. However some differences persist.
         */
        [self.tabBarController.navigationController dismissViewControllerAnimated: YES
                                                                       completion:nil];
    }
    else
    {
        [self.datePickerController.navigationController dismissViewControllerAnimated: YES
                                                                           completion: nil];
    }
}


#pragma mark - OCRCellTextFieldDelegate methods

//----------------------------------------------------------------------------------------------------------
/**
 Update the object represented by the tagged field in the cell at indexPath.
 
 @param string              The string data
 @param tag                 The tag of the UITextField representing the object.
 @param indexPath           An index path locating the new selected row in tableView.
 */
- (void)updateSourceObjectWithString: (NSString *)string
                              forTag: (int)tag
                         atIndexPath: (NSIndexPath *)indexPath
{
    DLog();

    // Get the object represented by the cell at indexPath
    Accomplishments *accomplishment = [self.accFetchedResultsController objectAtIndexPath: indexPath];
    
    if (tag == kAccomplishmentNameFieldTag)
    {
        accomplishment.name     = string;
    }
    else if (tag == kAccomplishmentSummaryFieldTag)
    {
        accomplishment.summary  = string;
    }
}


//----------------------------------------------------------------------------------------------------------
/**
 Search the UIView hierarchy to find the UITableViewCell that is the parent of the view.
 
 This is a recursive method, searching through the superviews of the view. Eventually either a UITableViewCell
 is found, or the top of the superview chain is reached and the method returns nil.
 
 @param view        The UIView for whom the caller would like the parent UITableViewCell.
 @return            The UITableViewCell that is the parent of view, or nil if none is found.
 */
- (UITableViewCell *)parentCellForView: (UIView*)view
{
    DLog();
    
    // If there is no view,
    if (!view)
    {
        // ...search failed, return nil
        return nil;
    }
    
    // Check if we have OCREducationTableViewCell class
    if ([view isKindOfClass:[UITableViewCell class]])
    {
        // ...yes, return it
        return (UITableViewCell*)view;
    }
    // else, call ourself with the view's superview and continue the search
    return [self parentCellForView: view.superview];
}


#pragma mark - Fetched Results Controller

//----------------------------------------------------------------------------------------------------------
/**
 Singleton method to retrieve the eduFetchedResultsController, instantiating it if necessary.
 
 @return    An initialized NSFetchedResultsController.
 */
- (NSFetchedResultsController *)accFetchedResultsController
{
    DLog();
    
    if (_accFetchedResultsController != nil)
    {
        return _accFetchedResultsController;
    }
    
    // Create the fetch request for the entity
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity  = [NSEntityDescription entityForName: kOCRAccomplishmentsEntity
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
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"job == %@", selectedJob];
    [fetchRequest setPredicate: predicate];
    
    // Alloc and initialize the controller
    /*
     By setting sectionNameKeyPath to nil, we are stating we want everything in a single section
     */
    self.accFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest: fetchRequest
                                                                           managedObjectContext: [kAppDelegate managedObjectContext]
                                                                             sectionNameKeyPath: nil
                                                                                      cacheName: nil];
    // Set the delegate to self
    _accFetchedResultsController.delegate = self;
    
    // ...and start fetching results
    NSError *error = nil;
    if (![self.accFetchedResultsController performFetch:&error])
    {
        /*
         This is a case where something serious has gone wrong. Let the user know and try to give them some 
         options that might actually help.
         I'm providing my direct contact information in the hope I can help the user and avoid a bad review.
         */
        ELog(error, @"Unresolved error");
        [kAppDelegate showErrorWithMessage: NSLocalizedString(@"Could not read the database. Try quitting the app. If that fails, try deleting KOResume and restoring from iCloud or iTunes backup. Please contact the developer by emailing kevin@omaraconsultingassoc.com", nil)
                                    target: self];
    }
    
    return _accFetchedResultsController;
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
    
    if (![self.accFetchedResultsController performFetch: &error])
    {
        ELog(error, @"Fetch failed!");
        NSString* msg = NSLocalizedString( @"Failed to reload data after syncing with iCloud.", nil);
        [kAppDelegate showErrorWithMessage: msg
                                    target: self];
    }
    else
    {
        // Get the fetchedObjects re-loaded
        [self.accFetchedResultsController fetchedObjects];
    }
    
    if (selectedJob.isDeleted)
    {
        // Need to display a message
        [kAppDelegate showWarningWithMessage: @"Job deleted."
                                      target: self];
    }
}


@end
