//
//  OCRCoverLtrViewController.h
//  KOResume
//
//  Created by Kevin O'Mara on 8/11/13.
//  Copyright (c) 2013 O'Mara Consulting Associates. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OCRBaseDetailViewController.h"

@interface OCRCoverLtrViewController : OCRBaseDetailViewController <UITextViewDelegate, UISplitViewControllerDelegate>

@property (nonatomic, weak) IBOutlet UIScrollView           *scrollView;
@property (nonatomic, weak) IBOutlet UITextView             *coverLtrFld;


@end
