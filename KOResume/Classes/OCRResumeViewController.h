//
//  OCRResumeViewController.h
//  KOResume
//
//  Created by Kevin O'Mara on 2/1/14.
//  Copyright (c) 2014 O'Mara Consulting Associates. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OCRBaseDetailViewController.h"

@interface OCRResumeViewController : OCRBaseDetailViewController <UITextViewDelegate, UISplitViewControllerDelegate, OCRDetailViewProtocol,
                                                                  NSFetchedResultsControllerDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *summarView;

/**
 IBOutlet to the name of the resume
 */
@property (weak, nonatomic) IBOutlet UITextField            *resumeName;

/**
 IBOutlet to the title of the current job
 */
@property (weak, nonatomic) IBOutlet UILabel                *currentJobTitle;

/**
 IBOutlet to the name of the current job
 */
@property (weak, nonatomic) IBOutlet UILabel                *currentJobName;

/**
 IBOutlet to street1 of the resume
 */
@property (weak, nonatomic) IBOutlet UITextField            *resumeStreet1;

/**
 IBOutlet to city of the resume
 */
@property (weak, nonatomic) IBOutlet UITextField            *resumeCity;

/**
 IBOutlet to the state of the resume
 */
@property (weak, nonatomic) IBOutlet UITextField            *resumeState;

/**
 IBOutlet to the postalCode of the resume
 */
@property (weak, nonatomic) IBOutlet UITextField            *resumePostalCode;

/**
 IBOutlet to the home_phone of the resume
 */
@property (weak, nonatomic) IBOutlet UITextField            *resumeHomePhone;

/**
 IBOutlet to the mobile_phone of the resume
 */
@property (weak, nonatomic) IBOutlet UITextField            *resumeMobilePhone;

/**
 IBOutlet to the email of the resume
 */
@property (weak, nonatomic) IBOutlet UITextField            *resumeEmail;

/**
 IBOutlet to the summary of the resume
 */
@property (weak, nonatomic) IBOutlet UITextView             *resumeSummary;

/**
 IBOutlet to the tableView
 */
@property (weak, nonatomic) IBOutlet UITableView            *tableView;

@end
