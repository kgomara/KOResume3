//
//  OCRDetailViewController.h
//  KOResume
//
//  Created by Kevin O'Mara on 7/14/13.
//  Copyright (c) 2013 O'Mara Consulting Associates. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Packages.h"

@interface OCRDetailViewController : UITableViewController <UISplitViewControllerDelegate, UITableViewDelegate>

@property (nonatomic, retain) IBOutlet UITableView          *tblView;
@property (nonatomic, retain) Packages                      *selectedPackage;

@property (nonatomic, retain) NSManagedObjectContext        *managedObjectContext;
@property (nonatomic, retain) NSFetchedResultsController    *fetchedResultsController;

@end
