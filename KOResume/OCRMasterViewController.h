//
//  OCRMasterViewController.h
//  KOResume
//
//  Created by Kevin O'Mara on 7/14/13.
//  Copyright (c) 2013 O'Mara Consulting Associates. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OCRPackagesCell.h"

@class OCRDetailViewController;

#import <CoreData/CoreData.h>

@interface OCRMasterViewController : UICollectionViewController <NSFetchedResultsControllerDelegate, OCRPackageCellDelegate>

@property (nonatomic, strong) OCRDetailViewController       *detailViewController;

@property (nonatomic, strong) NSFetchedResultsController    *fetchedResultsController;
@property (nonatomic, strong) NSManagedObjectContext        *managedObjectContext;


@end
