//
//  OCRResumeJobsDetailViewController.h
//  KOResume
//
//  Created by Kevin O'Mara on 4/6/14.
//  Copyright (c) 2014 O'Mara Consulting Associates. All rights reserved.
//

#import "OCRBaseDetailViewController.h"

/**
 @brief Manage a Jobs object.
 */
@interface OCRResumeJobsDetailViewController : OCRBaseDetailViewController  <UITextViewDelegate, UISplitViewControllerDelegate, OCRDetailViewProtocol, UIScrollViewDelegate,
                                                                 NSFetchedResultsControllerDelegate,
UITableViewDataSource, UITableViewDelegate,
                                                                             UIPopoverPresentationControllerDelegate>

/**
 IBOutlet to the tableHeaderView.
 */
@property (weak, nonatomic) IBOutlet UIView         *tableHeaderView;

/**
 IBOutlet to the name of the Job.
 */
@property (weak, nonatomic) IBOutlet UITextField    *jobName;

/**
 IBOutlet to the title of the job.
 */
@property (weak, nonatomic) IBOutlet UITextField    *jobTitle;

/**
 IBOutlet to job's city.
 */
@property (weak, nonatomic) IBOutlet UITextField    *jobCity;

/**
 IBOutlet to the job's state.
*/
@property (weak, nonatomic) IBOutlet UITextField    *jobState;

/**
 IBOutlet to the job's start date.
 */
@property (weak, nonatomic) IBOutlet UITextField    *jobStartDate;

/**
 IBOutlet to the job's end date.
 */
@property (weak, nonatomic) IBOutlet UITextField    *jobEndDate;

/**
 IBOutlet to the job's summary.
 */
@property (weak, nonatomic) IBOutlet UITextView     *jobSummary;

/**
 IBOutlet to the tableView.
 */
@property (weak, nonatomic) IBOutlet UITableView    *tableView;

/**
 IBOutlet to the infoButton.
 */
@property (weak, nonatomic) IBOutlet UIButton       *infoButton;

/**
 IBOutlet to the scroll view.
 */
@property (weak, nonatomic) IBOutlet UIScrollView   *scrollView;

/**
 IBOutler to the content view.
 */
@property (weak, nonatomic) IBOutlet UIView         *contentView;

/**
 Handles presses of the addButton (+ image) on the section header views.
 
 The tableView:viewForHeaderInSection: method sets the tag field to the
 section number in order to differentiate between adding jobs vs. education.
 
 @param sender the UIButton that was pressed.
 */
- (IBAction)didPressAddButton: (id)sender;

/**
 Handles presses of the infoButton.
 
 The infoButton behavior depends on the editing state. In normal (browse) mode, tapping
 it opens a browser window with the job.uri as the address. In editing mode tapping it
 opens an actionSheet that allows the user to edit the job.uri.
 
 @param sender the UIButton that was pressed.
 */
- (IBAction)didPressInfoButton:(id)sender;

@end
