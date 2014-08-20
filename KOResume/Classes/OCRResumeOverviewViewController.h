//
//  OCRResumeOverviewViewController.h
//  KOResume
//
//  Created by Kevin O'Mara on 8/5/14.
//  Copyright (c) 2014 O'Mara Consulting Associates. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OCRPackagesViewController.h"
#import "OCRBaseDetailViewController.h"

@interface OCRResumeOverviewViewController : OCRBaseDetailViewController    <UITextFieldDelegate, UIScrollViewDelegate>

/**
 IBOutlet to the scrollview
 */
@property (weak, nonatomic) IBOutlet UIScrollView           *scrollView;
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
 IBOutlet to the contentView containing all the UI elements.
 */
@property (weak, nonatomic) IBOutlet UIView                 *contentView;

/**
 IBOutlet to the bottom constraint of the contentView.
 */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint     *contentViewBottomConstraint;
@end
