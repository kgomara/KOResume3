//
//  OCRCoverLtrViewController.h
//  KOResume
//
//  Created by Kevin O'Mara on 3/15/11.
//  Copyright (c) 2011-2014 O'Mara Consulting Associates. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OCRBaseDetailViewController.h"

/**
 Manage cover letter objects.
 */
@interface OCRCoverLtrViewController : OCRBaseDetailViewController <UITextViewDelegate, UISplitViewControllerDelegate, OCRDetailViewProtocol>

/**
 IBOutlet to the scrollView
 */
@property (nonatomic, weak) IBOutlet UIScrollView           *scrollView;

/**
 IBOutlet to the cover letter text
 */
@property (nonatomic, weak) IBOutlet UITextView             *coverLtrFld;


@end
