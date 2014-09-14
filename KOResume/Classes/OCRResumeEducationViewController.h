//
//  OCRResumeEducationViewController.h
//  KOResume
//
//  Created by Kevin O'Mara on 8/9/14.
//  Copyright (c) 2014 O'Mara Consulting Associates. All rights reserved.
//

#import "OCRBaseDetailTableViewController.h"

@interface OCRResumeEducationViewController : OCRBaseDetailTableViewController <UITextFieldDelegate, NSFetchedResultsControllerDelegate,
                                                                                UITableViewDataSource, UITableViewDelegate,
                                                                                UIPopoverPresentationControllerDelegate>

/**
 IBOutlet to the tableView.
 */
@property (strong, nonatomic) IBOutlet UITableView      *tableView;

/**
 IBOutlet to the no selection view.
 */
@property (strong, nonatomic) IBOutlet UIView           *noSelectionView;

/**
 IBOutlet to the no selection label.
 */
@property (weak, nonatomic)   IBOutlet UILabel          *noSelectionLabel;


@end
