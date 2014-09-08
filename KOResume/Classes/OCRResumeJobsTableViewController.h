//
//  OCRResumeJobsTableViewController.h
//  KOResume
//
//  Created by Kevin O'Mara on 8/7/14.
//  Copyright (c) 2014 O'Mara Consulting Associates. All rights reserved.
//

#import "OCRBaseDetailTableViewController.h"

@interface OCRResumeJobsTableViewController : OCRBaseDetailTableViewController   <NSFetchedResultsControllerDelegate>

/**
 IBOutlet to the tableView.
 */
@property (strong, nonatomic) IBOutlet UITableView          *tableView;

@end
