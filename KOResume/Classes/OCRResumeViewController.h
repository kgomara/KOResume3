//
//  OCRResumeViewController.h
//  KOResume
//
//  Created by Kevin O'Mara on 2/1/14.
//  Copyright (c) 2014 O'Mara Consulting Associates. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OCRBaseDetailViewController.h"

@interface OCRResumeViewController : OCRBaseDetailViewController <UITextViewDelegate, UISplitViewControllerDelegate, OCRDetailViewProtocol>

/**
 IBOutlet to the scrollView
 */
@property (nonatomic, weak) IBOutlet UIScrollView           *scrollView;

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
 IBOutlet to the city and statue of the current job
 */
@property (weak, nonatomic) IBOutlet UILabel                *resumeCityState;

@end
