//
//  OCRResumeViewController.m
//  KOResume
//
//  Created by Kevin O'Mara on 2/1/14.
//  Copyright (c) 2014 O'Mara Consulting Associates. All rights reserved.
//

#import "OCRResumeViewController.h"
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

    /**
     reference to the button available in table edit mode that allows the user to add a Job
     */
    UIButton            *addJobBtn;
    
    /**
     reference to the button available in table edit mode that allows the user to add an Education/Certification
     */
    UIButton            *addEducationBtn;
}

@property (nonatomic, strong)   NSMutableArray      *_jobArray;
@property (nonatomic, strong)   NSMutableArray      *_educationArray;
@property (nonatomic, strong)   NSString            *_jobName;
@property (nonatomic, strong)   Resumes             *_selectedResume;

@end

@implementation OCRResumeViewController

#pragma mark - Life Cycle methods

//----------------------------------------------------------------------------------------------------------
- (void)viewDidLoad
{
    // For convenience, make a type-correct reference to the Resume we're working on
    self._selectedResume = (Resumes *)self.selectedManagedObject;
    
    DLog(@"job count %d", [__selectedResume.job count]);
    
    [super viewDidLoad];
	
	self.view.backgroundColor = [UIColor clearColor];
    // Set the default button title
    self.backButtonTitle        = NSLocalizedString(@"Resume", nil);
    
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
    
    addJobBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [addJobBtn setBackgroundImage: [UIImage imageNamed:@"addButton.png"]
                         forState: UIControlStateNormal];
    [addJobBtn setFrame:CGRectMake(280, 0, kOCRAddButtonWidth, kOCRAddButtonHeight)];
    [addJobBtn addTarget: self
                  action: @selector(promptForJobName)
        forControlEvents: UIControlEventTouchUpInside];
    
    addEducationBtn = [UIButton buttonWithType: UIButtonTypeCustom];
    [addEducationBtn setBackgroundImage: [UIImage imageNamed:@"addButton.png"]
                               forState: UIControlStateNormal];
    [addEducationBtn setFrame: CGRectMake(280, 0, kOCRAddButtonWidth, kOCRAddButtonHeight)];
    [addEducationBtn addTarget: self
                        action: @selector(promptForEducationName)
              forControlEvents: UIControlEventTouchUpInside];
    
    // ...and the NavBar
    [self configureDefaultNavBar];
    
    [self sortTables];
}


//----------------------------------------------------------------------------------------------------------
- (void)viewWillAppear:(BOOL)animated
{
    DLog();
    [super viewWillAppear: animated];
    
    self.fetchedResultsController.delegate = self;
    [self.tableView reloadData];

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
    
    
    [super viewWillDisappear: animated];
}


//----------------------------------------------------------------------------------------------------------
- (void)sortTables
{
    DLog();
    // Sort jobs in the order they should appear in the table
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: kOCRSequenceNumberAttributeName
                                                                   ascending: YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject: sortDescriptor];
    self._jobArray = [NSMutableArray arrayWithArray: [__selectedResume.job sortedArrayUsingDescriptors: sortDescriptors]];
    // ...sort the Education and Certification array
    self._educationArray = [NSMutableArray arrayWithArray: [__selectedResume.education sortedArrayUsingDescriptors: sortDescriptors]];
}


//----------------------------------------------------------------------------------------------------------
/**
 Configure the view items
 */
- (void)configureView
{
    DLog();
    
    self.navigationItem.title = NSLocalizedString(@"Resume", nil);
}


//----------------------------------------------------------------------------------------------------------
/**
 Update the data fields of the view - the resume
 */
- (void)updateDataFields
{
    DLog();
    
    _resumeName.text            = __selectedResume.name;
    
    // We need to get the job the user has put at the top of the table, so sort the Jobs by sequence_number
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: kOCRSequenceNumberAttributeName
                                                                   ascending: YES];
    NSArray *sortDescriptors    = [[NSArray alloc] initWithObjects: sortDescriptor, nil];
    NSArray *jobsArray          = [__selectedResume.job sortedArrayUsingDescriptors:sortDescriptors];
    if ([jobsArray count] > 0) {
        Jobs *currentJob = [jobsArray objectAtIndex:0];
        _currentJobTitle.text   = currentJob.title;
        _currentJobName.text    = currentJob.name;
    } else {
        _currentJobTitle.text   = @"";
        _currentJobName.text    = @"";
    }
    _resumeStreet1.text         = __selectedResume.street1;
    _resumeCity.text            = [NSString stringWithFormat:@"%@,", __selectedResume.city];
    _resumeState.text           = __selectedResume.state;
    _resumePostalCode.text      = __selectedResume.postal_code;
    _resumeHomePhone.text       = __selectedResume.home_phone;
    _resumeMobilePhone.text     = __selectedResume.mobile_phone;
    _resumeEmail.text           = __selectedResume.email;
    _resumeSummary.text         = __selectedResume.summary;
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
    
    // Set table editing off
    [self.tableView setEditing: NO];
    
    // ...and hide the add buttons
    [addJobBtn       setHidden: YES];
    [addEducationBtn setHidden: YES];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    
    // Enable table editing
    [self.tableView setEditing: YES];
    // ...and enable resume fields
    [_resumeName setEnabled: YES];
    [_resumeStreet1 setEnabled: YES];
    [_resumeCity setEnabled: YES];
    [_resumeState setEnabled: YES];
    [_resumePostalCode setEnabled: YES];
    [_resumeHomePhone setEnabled: YES];
    [_resumeMobilePhone setEnabled: YES];
    [_resumeEmail setEnabled: YES];
    [_resumeSummary setEditable: YES];
    
    // Set up the navigation item and save button
    self.navigationItem.leftBarButtonItem  = cancelBtn;
    self.navigationItem.rightBarButtonItem = saveBtn;
    
    // ...and show the add buttons
    [addJobBtn          setHidden: NO];
    [addEducationBtn    setHidden: NO];
    
    // Start an undo group...it will either be commited in didPressSaveButton or
    //    undone in didPressCancelButton
    [[[kAppDelegate managedObjectContext] undoManager] beginUndoGrouping];
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
    
    // Reset the sequence_number of the Job and Education items in case they were re-ordered during the edit
    [self resequenceTables];
    
    // Save the changes
    __selectedResume.name           = _resumeName.text;
    __selectedResume.street1        = _resumeStreet1.text;
    __selectedResume.city           = _resumeCity.text;
    __selectedResume.state          = _resumeState.text;
    __selectedResume.postal_code    = _resumePostalCode.text;
    __selectedResume.home_phone     = _resumeHomePhone.text;
    __selectedResume.mobile_phone   = _resumeMobilePhone.text;
    __selectedResume.email          = _resumeEmail.text;
    __selectedResume.summary        = _resumeSummary.text;
    
    // ...end the undo group
    [[[kAppDelegate managedObjectContext] undoManager] endUndoGrouping];
    [kAppDelegate saveContextAndWait: [kAppDelegate managedObjectContext]];
    
    // Cleanup the undoManager
    [[[kAppDelegate managedObjectContext] undoManager] removeAllActionsWithTarget:self];
    // ...and reset the UI defaults
    [self configureDefaultNavBar];
    [self resetView];
    [self.tableView reloadData];
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
    [[[kAppDelegate managedObjectContext] undoManager] setActionName:kOCRUndoActionName];
    [[[kAppDelegate managedObjectContext] undoManager] endUndoGrouping];
    
    if ([[[kAppDelegate managedObjectContext] undoManager] canUndo]) {
        // Changes were made - discard them
        [[[kAppDelegate managedObjectContext] undoManager] undoNestedGroup];
    }
    
    // Cleanup the undoManager
    [[[kAppDelegate managedObjectContext] undoManager] removeAllActionsWithTarget: self];
    // ...and reset the UI defaults
//    self.coverLtrFld.text    = self.selectedPackage.cover_ltr;
    [self updateDataFields];
    [self configureDefaultNavBar];
    [self resetView];
    [self.tableView reloadData];
}

//----------------------------------------------------------------------------------------------------------
- (void)resequenceTables
{
    DLog();
    // The job array is in the order (including deletes) the user wants
    // ...loop through the array by index resetting the job's sequence_number attribute
    for (int i = 0; i < [__jobArray count]; i++) {
        if ([[__jobArray objectAtIndex: i] isDeleted]) {
            // no need to update the sequence number of deleted objects
        } else {
            [[__jobArray objectAtIndex:i] setSequence_numberValue: i];
        }
    }
    // ...same for the education array
    for (int i = 0; i < [__educationArray count]; i++) {
        if ([[__educationArray objectAtIndex: i] isDeleted]) {
            // no need to update the sequence number of deleted objects
        } else {
            [[__educationArray objectAtIndex:i] setSequence_numberValue: i];
        }
    }
}

//----------------------------------------------------------------------------------------------------------
- (void)addJob
{
    DLog();
    Jobs *job = (Jobs *)[NSEntityDescription insertNewObjectForEntityForName: kOCRJobsEntity
                                                      inManagedObjectContext: [kAppDelegate managedObjectContext]];
    job.name            = __jobName;
    job.created_date    = [NSDate date];
    job.resume          = __selectedResume;
    
    [kAppDelegate saveContextAndWait: [kAppDelegate managedObjectContext]];
    
    [__jobArray insertObject: job
                     atIndex: 0];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow: 0
                                                inSection: k_JobsSection];
    
    [self.tableView insertRowsAtIndexPaths: [NSArray arrayWithObject: indexPath]
                          withRowAnimation: UITableViewRowAnimationFade];
    [self.tableView scrollToRowAtIndexPath: indexPath
                          atScrollPosition: UITableViewScrollPositionTop
                                  animated: YES];
}


//----------------------------------------------------------------------------------------------------------
- (void)promptForJobName
{
    DLog();
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
- (void)addEducation
{
    DLog();
    Education *education = (Education *)[NSEntityDescription insertNewObjectForEntityForName: kOCREducationEntity
                                                                      inManagedObjectContext: [kAppDelegate managedObjectContext]];
    education.name            = __jobName;
    education.created_date    = [NSDate date];
    education.resume          = __selectedResume;
    
    [kAppDelegate saveContextAndWait: [kAppDelegate managedObjectContext]];
    
    [__educationArray insertObject: education
                           atIndex: 0];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow: 0
                                                inSection: k_EducationSection];
    
    [self.tableView insertRowsAtIndexPaths: [NSArray arrayWithObject: indexPath]
                          withRowAnimation: UITableViewRowAnimationFade];
    [self.tableView scrollToRowAtIndexPath: indexPath
                          atScrollPosition: UITableViewScrollPositionTop
                                  animated: YES];
}


//----------------------------------------------------------------------------------------------------------
- (void)promptForEducationName
{
    DLog();
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
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    DLog();
    if (buttonIndex == 1) {
        // OK button was tapped
        self._jobName = [[alertView textFieldAtIndex: 0] text];
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

#pragma mark - Table view data source


//----------------------------------------------------------------------------------------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}


//----------------------------------------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    DLog(@"section=%d", section);
    NSInteger rowsInSection;
    
	switch (section) {
		case k_JobsSection:
			rowsInSection = [__jobArray count];
			break;
		case k_EducationSection:
			rowsInSection = [__educationArray count];
			break;
		default:
			ALog(@"Unexpected section = %d", section);
			rowsInSection = 0;
			break;
	}
    
    return rowsInSection;
}


//----------------------------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DLog();
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: @"OCRResumeCell"];
    
	// Configure the cell.
    cell = [self configureCell: cell
                   atIndexPath: indexPath];
    
    return cell;
}


//----------------------------------------------------------------------------------------------------------
- (UITableViewCell *)configureCell:(UITableViewCell *)cell
                       atIndexPath:(NSIndexPath *) indexPath
{
    DLog();
    switch (indexPath.section) {
		case k_JobsSection:
			cell.textLabel.text         = [[__jobArray objectAtIndex: indexPath.row] name];
            cell.detailTextLabel.text   = [[__jobArray objectAtIndex: indexPath.row] title];
			cell.accessoryType          = UITableViewCellAccessoryDisclosureIndicator;
			break;
		case k_EducationSection:
			cell.textLabel.text         = [[__educationArray objectAtIndex: indexPath.row] name];
            cell.detailTextLabel.text   = [[__educationArray objectAtIndex: indexPath.row] title];
			cell.accessoryType          = UITableViewCellAccessoryDisclosureIndicator;
			break;
		default:
			ALog(@"Unexpected section = %d", indexPath.section);
			break;
	}
    
    return cell;
    
}

#pragma mark - Table view delegates


//----------------------------------------------------------------------------------------------------------
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    DLog();
	UILabel *sectionLabel = [[UILabel alloc] initWithFrame: CGRectMake(0, 0, 260.0f, kOCRAddButtonHeight)];
	[sectionLabel setFont: [UIFont preferredFontForTextStyle:UIFontTextStyleBody]];
	[sectionLabel setTextColor: [UIColor blackColor]];
	[sectionLabel setBackgroundColor: [UIColor clearColor]];
    
	switch (section) {
		case k_JobsSection: {
			sectionLabel.text   = NSLocalizedString(@"Professional History", nil);
            UIView *sectionView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, 280.0f, kOCRAddButtonHeight)];
            [sectionView addSubview: sectionLabel];
            [sectionView addSubview: addJobBtn];
			return sectionView;
		}
		case k_EducationSection: {
			sectionLabel.text = NSLocalizedString(@"Education & Certifications", nil);
            UIView *sectionView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, 280.0f, kOCRAddButtonHeight)];
            [sectionView addSubview: sectionLabel];
            [sectionView addSubview: addEducationBtn];
			return sectionView;
		}
		default:
			ALog(@"Unexpected section = %d", section);
			return nil;
	}
}


//----------------------------------------------------------------------------------------------------------
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return 44;
}


//----------------------------------------------------------------------------------------------------------
- (void) tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
 forRowAtIndexPath:(NSIndexPath *)indexPath
{
    DLog();
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the managed object at the given index path.
        if (indexPath.section == k_JobsSection) {
            NSManagedObject *jobToDelete = [__jobArray objectAtIndex: indexPath.row];
            [[kAppDelegate managedObjectContext] deleteObject: jobToDelete];
            [__jobArray removeObjectAtIndex: indexPath.row];
        } else {
            NSManagedObject *jobToDelete = [__educationArray objectAtIndex: indexPath.row];
            [[kAppDelegate managedObjectContext] deleteObject: jobToDelete];
            [__educationArray removeObjectAtIndex: indexPath.row];
        }
        // ...delete the object from the tableView
        [tableView deleteRowsAtIndexPaths: [NSArray arrayWithObject: indexPath]
                         withRowAnimation: UITableViewRowAnimationFade];
        // ...and reload the table
        [tableView reloadData];
    }
}


//----------------------------------------------------------------------------------------------------------
- (void) tableView:(UITableView *)tableView
moveRowAtIndexPath:(NSIndexPath *)fromIndexPath
       toIndexPath:(NSIndexPath *)toIndexPath
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
        Jobs *movedJob = [__jobArray objectAtIndex: fromRow];
        // ...remove it from that "order"
        [__jobArray removeObjectAtIndex: fromRow];
        // ...and insert it where the user wants
        [__jobArray insertObject: movedJob
                         atIndex: toRow];
    } else {
        // Get the Education at the fromRow
        Education *movedEducation = [__educationArray objectAtIndex: fromRow];
        // ...remove it from that "order"
        [__educationArray removeObjectAtIndex: fromRow];
        // ...and insert it where the user wants
        [__educationArray insertObject: movedEducation
                               atIndex: toRow];
    }
}


//----------------------------------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
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
	[tableView deselectRowAtIndexPath:indexPath
							 animated:YES];
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
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    DLog();
    
//    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    
//    self.coverLtrFld.contentInset          = contentInsets;
//    self.coverLtrFld.scrollIndicatorInsets = contentInsets;
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
    
}


#pragma mark - Fetched Results Controller delegate methods

//----------------------------------------------------------------------------------------------------------
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    DLog();
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [self.tableView beginUpdates];
}


//----------------------------------------------------------------------------------------------------------
- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    DLog();
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [_tableView insertRowsAtIndexPaths: [NSArray arrayWithObject: newIndexPath]
                              withRowAnimation: UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [_tableView deleteRowsAtIndexPaths: [NSArray arrayWithObject:indexPath]
                              withRowAnimation: UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell: [_tableView cellForRowAtIndexPath: indexPath]
                    atIndexPath: indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [_tableView deleteRowsAtIndexPaths: [NSArray arrayWithObject: indexPath]
                              withRowAnimation: UITableViewRowAnimationFade];
            // Reloading the section inserts a new row and ensures that titles are updated appropriately.
            [_tableView reloadSections: [NSIndexSet indexSetWithIndex: newIndexPath.section]
                      withRowAnimation: UITableViewRowAnimationFade];
            break;
    }
}


//----------------------------------------------------------------------------------------------------------
- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
{
    DLog();
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
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    DLog();
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [_tableView endUpdates];
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
