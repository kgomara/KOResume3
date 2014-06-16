//
//  OCRResumeViewController.h
//  KOResume
//
//  Created by Kevin O'Mara on 3/9/11.
//  Copyright (c) 2011-2014 O'Mara Consulting Associates. All rights reserved.
//

#import "OCRBaseDetailViewController.h"
#import "OCRCellTextFieldDelegateProtocol.h"

/**
 Manage a Resume object.
 */
@interface OCRResumeViewController : OCRBaseDetailViewController <UITextViewDelegate, UISplitViewControllerDelegate, OCRDetailViewProtocol,
                                                                  NSFetchedResultsControllerDelegate, UITableViewDataSource, UITableViewDelegate,
                                                                  OCRCellTextFieldDelegate>

/**
 IBOutlet to the tableHeaderView.
 */
@property (weak, nonatomic) IBOutlet UIView                 *tableHeaderView;

/**
 IBOutlet to the name of the resume.
 */
@property (weak, nonatomic) IBOutlet UITextField            *resumeName;

/**
 IBOutlet to the title of the current job.
 */
@property (weak, nonatomic) IBOutlet UILabel                *currentJobTitle;

/**
 IBOutlet to the "at" label.
 
 Declared so the UIFont can be dynamically re-sized.
 */
@property (weak, nonatomic) IBOutlet UILabel                *atLabel;

/**
 IBOutlet to the name of the current job.
 */
@property (weak, nonatomic) IBOutlet UILabel                *currentJobName;

/**
 IBOutlet to street1 of the resume.
 */
@property (weak, nonatomic) IBOutlet UITextField            *resumeStreet1;

/**
 IBOutlet to city of the resume.
 */
@property (weak, nonatomic) IBOutlet UITextField            *resumeCity;

/**
 IBOutlet to the state of the resume.
 */
@property (weak, nonatomic) IBOutlet UITextField            *resumeState;

/**
 IBOutlet to the postalCode of the resume.
 */
@property (weak, nonatomic) IBOutlet UITextField            *resumePostalCode;

/**
 IBOutlet to the home_phone of the resume.
 */
@property (weak, nonatomic) IBOutlet UITextField            *resumeHomePhone;

/**
 IBOutlet to the "Hm" label.
 
 Declared so the UIFont can be dynamically re-sized.
 */
@property (weak, nonatomic) IBOutlet UILabel                *hmLabel;

/**
 IBOutlet to the mobile_phone of the resume.
 */
@property (weak, nonatomic) IBOutlet UITextField            *resumeMobilePhone;

/**
 IBOutlet to the "Mb" label.
 
 Declared so the UIFont can be dynamically re-sized.
 */
@property (weak, nonatomic) IBOutlet UILabel                *mbLabel;

/**
 IBOutlet to the email of the resume.
 */
@property (weak, nonatomic) IBOutlet UITextField            *resumeEmail;

/**
 IBOutlet to the summary of the resume.
 */
@property (weak, nonatomic) IBOutlet UITextView             *resumeSummary;

/**
 IBOutlet to the tableView.
 */
@property (strong, nonatomic) IBOutlet UITableView          *tableView;

/**
 Handles taps of the addButton (+ image) on the section header views.
 
 The tableView:viewForHeaderInSection: method sets the tag field to the
 section number in order to differentiate between adding jobs vs. education.
 
 @param sender the UIButton that was tapped.
 */
- (IBAction)didPressAddButton: (id)sender;

@end
