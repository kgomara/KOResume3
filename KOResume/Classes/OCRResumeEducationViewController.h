//
//  OCRResumeEducationViewController.h
//  KOResume
//
//  Created by Kevin O'Mara on 8/9/14.
//  Copyright (c) 2014 O'Mara Consulting Associates. All rights reserved.
//

#import "OCRBaseDetailTableViewController.h"

/**
 Manage education object.
 */
@interface OCRResumeEducationViewController : OCRBaseDetailTableViewController <UITextFieldDelegate, NSFetchedResultsControllerDelegate,
                                                                                UITableViewDataSource, UITableViewDelegate,
                                                                                UIPopoverPresentationControllerDelegate>

/**
 IBOutlet to the tableView.
 */
@property (strong, nonatomic) IBOutlet UITableView      *tableView;

@end
