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
@property (strong, nonatomic) NSIndexPath *datePickerIndexPath;

/**
 A reference to a date formatter.
 */
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@end

@implementation OCRDateTableViewController

CGFloat pickerCellRowHeight;

//----------------------------------------------------------------------------------------------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [_dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    
    UITableViewCell *pickerViewCellToCheck = [self.tableView dequeueReusableCellWithIdentifier: kOCRDatePickerTableCell];
    pickerCellRowHeight = pickerViewCellToCheck.frame.size.height;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}


//----------------------------------------------------------------------------------------------------------
- (void)didReceiveMemoryWarning
{
    ALog();
    
    [super didReceiveMemoryWarning];
}


//----------------------------------------------------------------------------------------------------------
- (BOOL)datePickerIsShown
{
    return self.datePickerIndexPath != nil;
}


//----------------------------------------------------------------------------------------------------------
- (IBAction)dateChanged: (UIDatePicker *)sender
{
    DLog();
    
    NSIndexPath *parentCellIndexPath = nil;
    
    if ([self datePickerIsShown]){
        parentCellIndexPath = [NSIndexPath indexPathForRow: self.datePickerIndexPath.row - 1
                                                 inSection:0];
    } else {
        return;
    }
    
    if (parentCellIndexPath.row == 0) {
        // The date is for the start_date
        _selectedJob.start_date = sender.date;
    } else {
        _selectedJob.end_date   = sender.date;
    }
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath: parentCellIndexPath];
    cell.detailTextLabel.text = [self.dateFormatter stringFromDate: sender.date];
}

#pragma mark - Table view data source

//----------------------------------------------------------------------------------------------------------
- (NSInteger)numberOfSectionsInTableView: (UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}


//----------------------------------------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self datePickerIsShown]) {
        return 4;
    } else {
        return 3;
    }
}


//----------------------------------------------------------------------------------------------------------
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CGFloat rowHeight = self.tableView.rowHeight;
    
    if ([self datePickerIsShown] && (self.datePickerIndexPath.row == indexPath.row)){
        rowHeight = pickerCellRowHeight;
        
    }
    
    return rowHeight;
}


//----------------------------------------------------------------------------------------------------------
- (UITableViewCell *)tableView: (UITableView *)tableView
         cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    if ([self datePickerIsShown] && (self.datePickerIndexPath.row == indexPath.row)){
        NSDate *pickerDate;
        if (indexPath.row == 1) {
            /*
             If the picker is going in row 1, then we want the date from row zero, which is start date.
             */
            pickerDate = _selectedJob.start_date;
        } else {
            // must be end date, which could be null
            if (_selectedJob.end_date) {
                pickerDate = _selectedJob.end_date;
            } else {
                pickerDate = [NSDate date];
            }
        }
        cell = [self createPickerCell:pickerDate];
    }
    else if (indexPath.row == 0) {
        // The start date is always the first row
        cell = [self createDateHeaderCell: NSLocalizedString(@"Start", nil)
                                     date: _selectedJob.start_date];
    }
    else if (indexPath.row == 1) {
        assert( _datePickerIndexPath != indexPath);
        /*
         If the datePicker were being shown for start_date, it should be caught by the first if statement above. Therefore, this row must be end date.
         */
        cell = [self createDateHeaderCell: NSLocalizedString(@"End", nil)
                                     date: _selectedJob.end_date];
    }
    else if (indexPath.row == 2) {
        if ([self datePickerIsShown]) {
            assert( _datePickerIndexPath.row == 1);
            /*
             If the datePicker were being shown for end_date, it should be caught by the first if statement above. Therefore this row must be end date.
             */
            cell = [self createDateHeaderCell: NSLocalizedString(@"End", nil)
                                         date: _selectedJob.end_date];
        } else {
            cell = [self createDateClearCell];
        }
    }
    
    return cell;
}


//----------------------------------------------------------------------------------------------------------
- (UITableViewCell *)createDateHeaderCell: (NSString *)aDescription
                                     date: (NSDate *)aDate
{
    OCRDateHeaderTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier: kOCRDateHeaderTableCell];
    
    cell.description.text   = aDescription;
    cell.dateLabel.text     = [self.dateFormatter stringFromDate: aDate];
    
    return cell;
}


//----------------------------------------------------------------------------------------------------------
- (UITableViewCell *)createPickerCell: (NSDate *)aDate
{
    OCRDatePickerTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier: kOCRDatePickerTableCell];
    /*
     The tag is set on the UIDatePicker object in the Storyboard in order to make it easy to find.
     */
    UIDatePicker *targetedDatePicker = (UIDatePicker *)[cell viewWithTag: kDatePickerViewTag];
    
    [targetedDatePicker setDate: aDate
                       animated: NO];

    return cell;
}


//----------------------------------------------------------------------------------------------------------
- (UITableViewCell *)createDateClearCell
{
    OCRDatePickerTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier: kOCRDatePickerTableCell];
    
    return cell;
}


//----------------------------------------------------------------------------------------------------------
- (void)        tableView: (UITableView *)tableView
  didSelectRowAtIndexPath: (NSIndexPath *)indexPath
{
    DLog();
    
    [self.tableView beginUpdates];
    
    if ([self datePickerIsShown] && (self.datePickerIndexPath.row - 1 == indexPath.row)) {
        [self hideExistingPicker];
    } else {
        NSIndexPath *newPickerIndexPath = [self calculateIndexPathForNewPicker: indexPath];
        if ([self datePickerIsShown]) {
            [self hideExistingPicker];
        }
        
        [self showNewPickerAtIndex: newPickerIndexPath];
        
        self.datePickerIndexPath = [NSIndexPath indexPathForRow: newPickerIndexPath.row + 1
                                                      inSection: 0];
    }
    
    [self.tableView deselectRowAtIndexPath: indexPath
                                  animated: YES];
    
    [self.tableView endUpdates];
}


//----------------------------------------------------------------------------------------------------------
- (void)hideExistingPicker
{
    DLog();
    
    [self.tableView deleteRowsAtIndexPaths: @[[NSIndexPath indexPathForRow: self.datePickerIndexPath.row
                                                                 inSection: 0]]
                          withRowAnimation: UITableViewRowAnimationFade];
    
    self.datePickerIndexPath = nil;
}


//----------------------------------------------------------------------------------------------------------
- (NSIndexPath *)calculateIndexPathForNewPicker: (NSIndexPath *)selectedIndexPath
{
    DLog();
    
    NSIndexPath *newIndexPath;
    
    if (([self datePickerIsShown]) && (self.datePickerIndexPath.row < selectedIndexPath.row)){
        newIndexPath = [NSIndexPath indexPathForRow: selectedIndexPath.row - 1
                                          inSection: 0];
    } else {
        newIndexPath = [NSIndexPath indexPathForRow: selectedIndexPath.row
                                          inSection: 0];
    }
    
    return newIndexPath;
}


//----------------------------------------------------------------------------------------------------------
- (void)showNewPickerAtIndex: (NSIndexPath *)indexPath
{
    DLog();
    
    NSArray *indexPaths = @[[NSIndexPath indexPathForRow: indexPath.row + 1
                                               inSection: 0]];
    
    [self.tableView insertRowsAtIndexPaths: indexPaths
                          withRowAnimation: UITableViewRowAnimationFade];
}



@end
