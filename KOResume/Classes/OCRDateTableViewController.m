//
//  OCRDateTableViewController.m
//  KOResume
//
//  Created by Kevin O'Mara on 4/15/14.
//  Copyright (c) 2014 O'Mara Consulting Associates. All rights reserved.
//

#import "OCRDateTableViewController.h"
#import "OCRDateHeaderTableViewCell.h"
#import "OCRDatePickerTableViewCell.h"
#import "OCRDateClearTableViewCell.h"

#define kHeaderCell         0
#define kDatePickerCell     1
#define kDateClearCell      2

#define kDatePickerViewTag  1

@interface OCRDateTableViewController ()
{
    
}

/**
 A reference to the cell containing the picker.
 */
@property (strong, nonatomic) NSIndexPath       *datePickerIndexPath;


/**
 A reference to a date formatter.
 
 NSDateFormatters are expensize to instantiate. It is used fairly often, so we instansiate one globally
 and use it throughout the lifecycle of the view.
 */
@property (strong, nonatomic) NSDateFormatter   *dateFormatter;

/**
 A convenience property to determine if the datePicker is currently on screen.
 */
@property (assign, nonatomic) BOOL              datePickerIsShown;

@end

@implementation OCRDateTableViewController

/**
 The height of the kOCRDatePickerTableCell.
 
 The picker cell is re-assigned dynamically and we use this property in tableView:heightForRowAtIndexPath:
 */
static CGFloat pickerCellRowHeight;

#pragma mark - View lifecycle methods

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
    [super viewDidLoad];
    
    // Initialize a date formatter for use throughout the view's lifecycle.
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [_dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    
    // Get a picker cell so we can get the actual cell height as laid out in the storyboard
    UITableViewCell *cell   = [self.tableView dequeueReusableCellWithIdentifier: kOCRDatePickerTableCell];
    // ...and set that height into our static pickerCellRowHeight for use in tableView:heightForRowAtIndexPath:
    pickerCellRowHeight     = cell.frame.size.height;
}

#pragma mark - Date Picker delegates and convenience methods


//----------------------------------------------------------------------------------------------------------
/**
 Convenience method to determine whether or not the date picker is visible.
 
 This is an example of how to use a property to make the code more "self documenting".
 We create a getter method (see below) that checks whether or not datePickerIndexPath
 is nil. A value (YES/NO) is never set on datePickerIsShown itself. This allows us to use
 this property as:
 
    if (self.datePickerIsShown) {
        // do something
    }

 rather than
 
    if ([self datePickerIsShown]) {
        // do something
    }
 
 @return        YES if the date picker is occupying a table cell, NO otherwise.
 */
- (BOOL)datePickerIsShown
{
//    DLog(@"returning %@", self.datePickerIndexPath != nil? @"YES" : @"NO");
    
    return self.datePickerIndexPath != nil;
}


//----------------------------------------------------------------------------------------------------------
/**
 Invoked by the date picker when the user changes the value in the picker control.
 
 The date picker is always in the cell following the cell containing the date to change. This method computes
 the indexPath of that cell and updates both the managed object and the cell containing the date changed by
 the user.
 
 @param sender      UIDatePicker whose value has changed.
 */
- (IBAction)dateChanged: (UIDatePicker *)sender
{
    DLog();
    
    NSIndexPath *parentCellIndexPath = nil;
    
    // Safety check to ensure the date picker is shown
    assert(self.datePickerIsShown);
    // Get the index path immediately above the cell where the picker resides
    parentCellIndexPath = [NSIndexPath indexPathForRow: self.datePickerIndexPath.row - 1
                                             inSection: 0];
    
    if (parentCellIndexPath.row == 0) {
        // The date is for the start_date
        _selectedJob.start_date = sender.date;
    } else {
        _selectedJob.end_date   = sender.date;
    }
    // Inform the delegate one of the dates have changed
    [_delegate dateControllerDidUpdate];
    
    // Use the computed indexPath to get the cell from the tableView
    OCRDateHeaderTableViewCell *cell = (OCRDateHeaderTableViewCell *)[self.tableView cellForRowAtIndexPath: parentCellIndexPath];
    // ...and update the date
    cell.dateLabel.text = [self.dateFormatter stringFromDate: sender.date];
}

#pragma mark - Table view data source

//----------------------------------------------------------------------------------------------------------
/**
 Asks the data source to return the number of sections in the table view.
 
 @param tableView       An object representing the table view requesting this information.
 @return                The number of sections in tableView. The default value is 1.
 */
- (NSInteger)numberOfSectionsInTableView: (UITableView *)tableView
{
    // We have 1 section.
    return 1;
}


//----------------------------------------------------------------------------------------------------------
/**
 Asks the data source for a cell to insert in a particular location of the table view.
 
 The returned UITableViewCell object is frequently one that the application reuses for performance reasons.
 You should fetch a previously created cell object that is marked for reuse by sending a
 dequeueReusableCellWithIdentifier: message to tableView. Various attributes of a table cell are set automatically
 based on whether the cell is a separator and on information the data source provides, such as for accessory views
 and editing controls.
 
 In the case of the OCRDateTableViewController, we have 3 different UITableViewCell objects we can return. This is
 further complicated by the fact the date picker may or may not be present, and if it is present it could be in
 either cell 1 (after the start_date, or cell 2 (after end_date). While the clear cell is always the last cell, it
 is also complicated by the fact the date picker may or may not be present.
 
 @param tableView       A table-view object requesting the cell.
 @param indexPath       An index path locating a row in tableView.
 @return                An object inheriting from UITableViewCell that the table view can use for the specified row.
                        An assertion is raised if you return nil.
 */
- (UITableViewCell *)tableView: (UITableView *)tableView
         cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
    DLog(@"indexPath=%@", indexPath.debugDescription);
    
    UITableViewCell *cell;
    
    // Calculate the row of the clear button, which is always last.
    int clearButtonRow = [self.tableView numberOfRowsInSection:0] - 1;
    
    // The start date is always the first row
    if (indexPath.row == 0) {
        // Create a cell for the start date
        cell = [self configureDateHeaderCell: NSLocalizedString(@"Start", nil)
                                        date: _selectedJob.start_date];
    }
    else if (indexPath.row == clearButtonRow) {
        // Create a clear button cell
        cell = [self configureDateClearCell];
    }
    else if (self.datePickerIsShown) {
        assert(self.datePickerIndexPath.row == indexPath.row);
        // Date picker is in "this" row, instantiate a NSDate object to hold our date
        NSDate *pickerDate;
        if (indexPath.row == 1) {
            // If the picker is going in row 1, then we want the date from row zero, which is start date.
            pickerDate = _selectedJob.start_date;
        } else {
            // Must be end date
            pickerDate = _selectedJob.end_date;
        }
        // Create a cell for the date picker.
        cell = [self configurePickerCell: pickerDate];
    }
    // Date picker is not on screen
    else if (indexPath.row == 1) {          // The check for indexPath.row == 1 is (arguably) not necessary
        assert( self.datePickerIndexPath != indexPath);
        /*
         If the datePicker is being shown for start_date, it would be in row 1 and should be caught by the first if
         statement above. Therefore, this row must be end date.
         */
        // Create a cell for the end date
        cell = [self configureDateHeaderCell: NSLocalizedString(@"End", nil)
                                        date: _selectedJob.end_date];
    } else {
        ALog(@"Unexpected row=%d", indexPath.row);
    }
    
    return cell;
}


//----------------------------------------------------------------------------------------------------------
/**
 Convenience method to configure a date header table cell.
 
 @param aDescription    NSString to use in the description property of the cell.
 @param aDate           NSDate to use in the dataLabel property of the cell, if nil the date picker will use the current date.
 @return                A configured UITableViewCell.
 */
- (UITableViewCell *)configureDateHeaderCell: (NSString *)aDescription
                                        date: (NSDate *)aDate
{
    assert(aDescription);
    
    if (!aDate) {
        // The date field is nill, use today
        aDate = [NSDate date];
    }
    
    OCRDateHeaderTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier: kOCRDateHeaderTableCell];
    
    cell.description.text   = aDescription;
    cell.dateLabel.text     = [self.dateFormatter stringFromDate: aDate];
    
    return cell;
}


//----------------------------------------------------------------------------------------------------------
/**
 Convenience method to configure a date picker table cell.
 
 @param aDate           NSDate to use in the cell's UIDatePicker, if nil the date picker will use the current date.
 @return                A configured UITableViewCell.
 */
- (UITableViewCell *)configurePickerCell: (NSDate *)aDate
{
    if (!aDate) {
        // The date field is nill, use today
        aDate = [NSDate date];
    }
    
    OCRDatePickerTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier: kOCRDatePickerTableCell];
    /*
     In the Storyboard, the UIDatePicker object's tag is set in order to make it easy to find.
     */
    UIDatePicker *targetedDatePicker = (UIDatePicker *)[cell viewWithTag: kDatePickerViewTag];
    
    [targetedDatePicker setDate: aDate
                       animated: NO];
    
    return cell;
}


//----------------------------------------------------------------------------------------------------------
/**
 Convenience method to configure a date clear table cell.
 
 @return                A configured UITableViewCell.
 */
- (UITableViewCell *)configureDateClearCell
{
    OCRDatePickerTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier: kOCRDateClearTableCell];
    
    return cell;
}


//----------------------------------------------------------------------------------------------------------
/**
 Tells the data source to return the number of rows in a given section of a table view.
 
 In our case, this depends on whether or not we are editing a date cell.
 
 @param tableView       The table-view object requesting this information.
 @param section         An index number identifying a section in tableView.
 @return                The number of rows in section.
 */
- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    // If the date picker is occupying a cell,
    if (self.datePickerIsShown) {
        // ...we have 4 cells in our table
        DLog(@"returning 4");
        return 4;
    } else {
        // ...otherwise we have 3
        DLog(@"Returning 3");
        return 3;
    }
}


#pragma mark - Table view delegate methods

//----------------------------------------------------------------------------------------------------------
/**
 Tells the delegate that the specified row is now selected.
 
 The delegate handles selections in this method. One of the things it can do is exclusively assign the check-mark
 image (UITableViewCellAccessoryCheckmark) to one row in a section (radio-list style). This method isn’t called
 when the editing property of the table is set to YES (that is, the table view is in editing mode). See "Managing
 Selections" in Table View Programming Guide for iOS for further information (and code examples) related to this method.
 
 In our case, we are using the table view to display an in-line date picker. When the user taps on a cell we may need
 to add or delete a cell - specifically the kOCRDatePickerTableCell.
 
 @param tableView       A table-view object informing the delegate about the new row selection.
 @param indexPath       An index path locating the new selected row in tableView.
 */
- (void)        tableView: (UITableView *)tableView
  didSelectRowAtIndexPath: (NSIndexPath *)indexPath
{
    DLog(@"indexPath=%@, datePickerIndexPath=%@", indexPath, self.datePickerIndexPath);
    
    // Start tableView updating in case we are adding/deleting a date picker row
    [self.tableView beginUpdates];
    
    /*
     The question of what to do when the user taps on a row in the table is complicated due to the presense (or absence)
     of the date picker. There are many ways you could construct the if-then-else blocks to determine what to do; I chose to
     start with whether or not the date picker is shown.
     */
    // Calculate the row of the clear button, which is always last.
    int clearButtonRow = [self.tableView numberOfRowsInSection:0] - 1;
    
    // First check to see if the date picker is on screen and user tapped row above it
    if (self.datePickerIsShown && (self.datePickerIndexPath.row - 1 == indexPath.row)) {
        // ...yes, user is done editing - hide the date picker.
        [self hideExistingPicker];
    }
    else if (indexPath.row == clearButtonRow) {
        // Clear end date button pressed
        _selectedJob.end_date = nil;
        // Inform the delegate one of the dates have changed
        [_delegate dateControllerDidUpdate];
    }
    else {
        NSIndexPath *newPickerIndexPath = [self calculateIndexPathForNewPicker: indexPath];
        if (self.datePickerIsShown) {
            [self hideExistingPicker];
        }
        [self showNewPickerAtIndex: newPickerIndexPath];
        self.datePickerIndexPath = newPickerIndexPath;
    }
    
    [self.tableView deselectRowAtIndexPath: indexPath
                                  animated: YES];
    
    // End the updates (hen you call endUpdates, UITableView animates the operations above simultaneously)
    [self.tableView endUpdates];
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
- (CGFloat)     tableView:(UITableView *)tableView
  heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Default the to standard height
    CGFloat rowHeight = self.tableView.rowHeight;
    
    // If the indexPath is pointing at the date picker
    if (self.datePickerIsShown) {
        // The date picker is in the cell after the date we are editing
        if (self.datePickerIndexPath.row == indexPath.row){
            // use the value we set in viewDidLoad
            rowHeight = pickerCellRowHeight;
        }
    }
    
    return rowHeight;
}

#pragma mark - Picker support

//----------------------------------------------------------------------------------------------------------
/**
 Remove a date picker UITableViewCell from the UI.
 */
- (void)hideExistingPicker
{
    DLog();
    assert(self.datePickerIsShown);
    
    // Delete the table view row containing the date picker, which is in the row after the date we are editing
    [self.tableView deleteRowsAtIndexPaths: @[[NSIndexPath indexPathForRow: self.datePickerIndexPath.row
                                                                 inSection: 0]]
                          withRowAnimation: UITableViewRowAnimationFade];
    // ...and nil the cooresponding property
    self.datePickerIndexPath = nil;
}


//----------------------------------------------------------------------------------------------------------
/**
 Calculate the indexPath where the date picker will occupy when the table is updated.
 
 If the date picker is not on screen its new location will be in the row after the row that was tapped (row+1).
 
 If the date picker is already on screen its new indexPath depends on whether or not the user tapped below
 the one currently on screen or below it. 
 
    * If the START date picker is currently on screen and the user taps the end date cell - i.e., the third row (row==2), when the table is updated the END date picker will end up in the third row. 
    * Conversely, if the END date were on screen and the user tapped the start date cell - i.e., the first row (row ==0), when the table is updated the START date picker will end up in the second row.
 
 @param selectedIndexPath   NSIndexPath of the cell the user tapped.
 @return                    The NSIndexPath where the date picker cell belongs after the upcoming table update.
 */
- (NSIndexPath *)calculateIndexPathForNewPicker: (NSIndexPath *)selectedIndexPath
{
    DLog();
    
    NSIndexPath *newIndexPath;
    
    // If the picker is on screen, is the selectedIndexPath after the current location of the picker?
    if (self.datePickerIsShown && (self.datePickerIndexPath.row < selectedIndexPath.row)) {
        // Yes, the tap was below the cell where the picker resides, the new date picker will end up in the cell that was tapped.
        newIndexPath = selectedIndexPath;
    } else {
        // The new date picker will end up in the row after the one that was tapped.
        newIndexPath = [NSIndexPath indexPathForRow: selectedIndexPath.row + 1
                                          inSection: 0];
    }
    
    assert(newIndexPath.row < 3);
    
    return newIndexPath;
}


//----------------------------------------------------------------------------------------------------------
/**
 Insert a row for the date picker at indexPath.
 
 @param indexPath           The NSIndexPath which the date picker will occupy.
 */
- (void)showNewPickerAtIndex: (NSIndexPath *)indexPath
{
    DLog();
    
    NSArray *indexPaths = @[[NSIndexPath indexPathForRow: indexPath.row
                                               inSection: 0]];
    
    [self.tableView insertRowsAtIndexPaths: indexPaths
                          withRowAnimation: UITableViewRowAnimationFade];
}



@end
