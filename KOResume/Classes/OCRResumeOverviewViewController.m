//
//  OCRResumeOverviewViewController.m
//  KOResume
//
//  Created by Kevin O'Mara on 8/5/14.
//  Copyright (c) 2014 O'Mara Consulting Associates. All rights reserved.
//

#import "OCRResumeOverviewViewController.h"
#import "OCRAppDelegate.h"
#import "Resumes.h"
#import "Jobs.h"

#define k_OKButtonIndex     1

@interface OCRResumeOverviewViewController ()
{
@private
    /**
     Reference to the back button to facilitate swapping buttons between display and edit modes.
     */
    UIBarButtonItem     *backBtn;
    

    /**
     Reference to the cancel button to facilitate swapping buttons between display and edit modes.
     */
    UIBarButtonItem     *cancelBtn;
    
    /**
     A boolean flag to indicate whether the user is editing information or simply viewing.
     */
    BOOL                isEditing;

    /**
     Reference to the date formatter object.
     */
    NSDateFormatter     *dateFormatter;
    
    /**
     Reference to the active UITextField
     */
    UITextField         *activeField;
    
    /**
     Convenience reference to the managed object instance we are managing.
     
     OCRBaseDetailViewController, of which this is a subclass, declares a selectedManagedObject. We make this
     type-correct reference merely for convenience.
     */
    Resumes             *selectedResume;
}

@end


@implementation OCRResumeOverviewViewController

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
    [self.view addConstraint:leftConstraint];
    
    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem: self.contentView
                                                                       attribute: NSLayoutAttributeTrailing
                                                                       relatedBy: NSLayoutRelationEqual
                                                                          toItem: self.view
                                                                       attribute: NSLayoutAttributeTrailing
                                                                      multiplier: 1.0
                                                                        constant: 0];
    [self.view addConstraint:rightConstraint];
    
    // For convenience, make a type-correct reference to the Resume we're working on
    selectedResume = (Resumes *)self.selectedManagedObject;
    
    // Set the default button title
    self.backButtonTitle = NSLocalizedString(@"Resume", nil);
    
    // Set up button items
    backBtn     = self.navigationItem.leftBarButtonItem;
    
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
    
    [self.scrollView setContentOffset:CGPointZero];

    // Configure the view
    [self configureView];
    
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

/*
 Notice there is no viewWillDisappear.
 
 This class inherits viewWillDisappear from the base class, which calls removeObserver and saves the context; hence
 we have no need to implement the method in this class. Similarly, we don't implement didReceiveMemoryWarning.
 */


//----------------------------------------------------------------------------------------------------------
/**
 Update the data fields of the view from the resume managed object.
 */
- (void)loadViewFromSelectedObject
{
    DLog();
    
    [_resumeName setText: selectedResume.name
           orPlaceHolder: NSLocalizedString(@"Resume name", nil)];
    
    // Get the jobs sorted by sequence_number
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: kOCRSequenceNumberAttributeName
                                                                   ascending: YES];
    NSArray *sortDescriptors    = @[sortDescriptor];
    NSArray *jobsArray          = [NSMutableArray arrayWithArray: [selectedResume.job sortedArrayUsingDescriptors: sortDescriptors]];

    /*
     Note there is a difference between iPhone and iPad - or more correctly, between horizontal size compact and regular. In Interface 
     Builder, this Scene has "uninstalled" the currentJobTitle, currentJobName, and atLabel for the size class W:Compact H:Regular. Even
     though we assign text to these fields, they do not appear in Compact width (which includes iPhone landscape).
     */
    // Check to see if there is at least 1 Job...
    if ([jobsArray count] > 0)
    {
        // ...if so, get the first one,
        Jobs *currentJob        = jobsArray[0];
        // ...use it to populate the current job information in the summaryView,
        _currentJobTitle.text   = currentJob.title;
        _currentJobName.text    = currentJob.name;
        // ...and make sure the "at" label is visible
        _atLabel.hidden         = NO;
    }
    else
    {
        // If the are no jobs, clear the current job fields
        _currentJobTitle.text   = @"";
        _currentJobName.text    = @"";
        // ...and hide the "at" label
        _atLabel.hidden         = YES;
    }
    
    /*
     It's important to set the placeholder text in case the data field is "empty" because we are using
     autolayout. If both the field and place holders are empty it will have zero width in the UI, and
     when the user presses the "edit" button they would not be able to get a cursor inside any of the
     empty fields.
     */
    // For each of the tableHeaderView's text fields, set either it's text or placeholder property
    [_resumeStreet1 setText: selectedResume.street1
              orPlaceHolder: NSLocalizedString(@"Street address", nil)];
    
    [_resumeCity setText: selectedResume.city
           orPlaceHolder: NSLocalizedString(@"City", nil)];
    
    [_resumeState setText: selectedResume.state
            orPlaceHolder: NSLocalizedString(@"ST", nil)];
    
    [_resumePostalCode setText: selectedResume.postal_code
                 orPlaceHolder: NSLocalizedString(@"Zip code", nil)];
    
    [_resumeHomePhone setText: selectedResume.home_phone
                orPlaceHolder: NSLocalizedString(@"Home phone", nil)];
    
    [_resumeMobilePhone setText: selectedResume.mobile_phone
                  orPlaceHolder: NSLocalizedString(@"Mobile phone", nil)];
    
    [_resumeEmail setText: selectedResume.email
            orPlaceHolder: NSLocalizedString(@"Email address", nil)];
    
    /*
     resumeSummary is a textView, and always has width and height, so the autolayout concern mentioned
     above is not a concern here.
     */
    // resumeSummary is a UITextView
    _resumeSummary.text = selectedResume.summary;
    [_resumeSummary scrollRangeToVisible: NSMakeRange(0, 0)];
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
    
    // Set the background color for the fields based on the editable param
    UIColor *backgroundColor = editable? [self.view.tintColor colorWithAlphaComponent:0.1f] : [UIColor clearColor];
    
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
        self.navigationItem.title = title;
        self.navigationItem.rightBarButtonItems = @[self.editButtonItem];
    }
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

    // ...and configure the fields for the current editing state
    [self configureFieldsForEditing: isEditing];
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
    /*
     These UI elements only exist on iPad - or more correctly stated, in not in horizontally Compact size.
     We use Size Class in Interface Builder and uncheck installed for the W:Compact H:Any size class
     */
    _currentJobTitle.font   = [UIFont preferredFontForTextStyle: UIFontTextStyleHeadline];
    _atLabel.font           = [UIFont preferredFontForTextStyle: UIFontTextStyleHeadline];
    _currentJobName.font    = [UIFont preferredFontForTextStyle: UIFontTextStyleHeadline];

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
}


#pragma mark - UI handlers

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
        
        // ...and bring the keyboard onscreen with the cursor in resume name
        [_resumeName becomeFirstResponder];
    }
    else
    {
        // The user pressed "Done", save the changes
        selectedResume.name           = _resumeName.text;
        selectedResume.street1        = _resumeStreet1.text;
        selectedResume.city           = _resumeCity.text;
        selectedResume.state          = _resumeState.text;
        selectedResume.postal_code    = _resumePostalCode.text;
        selectedResume.home_phone     = _resumeHomePhone.text;
        selectedResume.mobile_phone   = _resumeMobilePhone.text;
        selectedResume.email          = _resumeEmail.text;
        selectedResume.summary        = _resumeSummary.text;
        
        // ...end the undo group
        [[[kAppDelegate managedObjectContext] undoManager] endUndoGrouping];
        
        // ...save changes to the database
        [kAppDelegate saveContextAndWait];
        
        // ...cleanup the undoManager
        [[[kAppDelegate managedObjectContext] undoManager] removeAllActionsWithTarget: self];
        
        // ...and turn off editing in the UI
        [self configureUIForEditing: NO];
        [self resetView];
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

    // ...re-load the view with the data from the (unchanged) resume
    [self loadViewFromSelectedObject];
    
    /*
     This may look odd - one usually sees a call to super in a method with the same name. But we need to inform
     the tableView that we are no longer editing the table.
     */
    [super setEditing: NO
             animated: YES];
    // ...turn off editing in the UI
    [self configureUIForEditing: NO];
    [self resetView];
}


//----------------------------------------------------------------------------------------------------------
/**
 Set the UI for for editing enabled or disabled.
 
 Called when the user presses the Edit, Save, or Cancel buttons.
 
 @param isEditingMode   YES if we are going into edit mode, NO otherwise.
 */
- (void)configureUIForEditing: (BOOL)isEditingMode
{
    DLog();
    
    // Update editing flag
    isEditing = isEditingMode;
    
    // ...enable/disable resume fields
    [self configureFieldsForEditing: isEditingMode];
    
    if (isEditingMode)
    {
        /*
         In iOS8 Apple has bridged much of the gap between iPhone and iPad. However some differences persist.
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
 @return                YES if an editing session should be initiated; otherwise, NO to disallow editing.
 */
- (BOOL)textViewShouldBeginEditing: (UITextView *)textView
{
    DLog();
    
    // Always allow editing
    return YES;
}


/**
 Tells the delegate that editing began for the specified text field.
 
 This method notifies the delegate that the specified text field just became the first responder. You can use 
 this method to update your delegate’s state information. For example, you might use this method to show overlay 
 views that should be visible while editing.
 
 Implementation of this method by the delegate is optional.
 
 In our case, we set the activeField property which is used in in the calculation to scroll fields so they are
 visible when the keyboard is on-screen.

 @param textField       The text field for which an editing session began.

 */
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    activeField = textField;
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
    
    activeField = nil;
}


#pragma mark - UITextField delegate methods

//----------------------------------------------------------------------------------------------------------
/**
 Asks the delegate if the text field should proc
 
 The text field calls this method whenever the user taps the return button. You can use this method to implement
 any custom behavior when the button is tapped.
 
 In our Storyboard scene, we set the textfield tag values incrementally, and then use the tag of the current
 textField responder to determine what to do next. We also set the other keyboard atttributes appropriately for]
 the data type we expect to see, and in particular set the return key to "Next" if hitting return will advance
 the user to the next field.
 
 Note the specific check for the date fields, in which case we bring up the data picker.
 
 @param textField       The text field whose return button was pressed.
 @return                YES if the text field should implement its default behavior for the return button; otherwise, NO.
 */
- (BOOL)textFieldShouldReturn: (UITextField *)textField
{
    DLog();
    
    NSInteger nextTag = [textField tag] + 1;
    UIResponder *nextResponder = [textField.superview viewWithTag: nextTag];
    
    if (nextResponder)
    {
        [nextResponder becomeFirstResponder];
    }
    else
    {
        [textField resignFirstResponder];       // Dismisses the keyboard
        [self resetView];
    }
    
    return NO;
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
    
    if (selectedResume.isDeleted)
    {
        // Need to display a message
        [kAppDelegate showWarningWithMessage: @"Resume deleted."
                                      target: self];
    }
    else
    {
        [self loadViewFromSelectedObject];
    }
}


@end
