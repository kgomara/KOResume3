//
//  OCRPackagesViewController.h
//  KOResume
//
//  Created by Kevin O'Mara on 7/14/13.
//  Copyright (c) 2013 O'Mara Consulting Associates. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OCRReorderableCollectionViewFlowLayout.h"
#import "OCRPackagesCell.h"

@class OCRDetailViewController;

#import <CoreData/CoreData.h>

@interface OCRPackagesViewController : UICollectionViewController <NSFetchedResultsControllerDelegate, OCRPackageCellDelegate,
                                                                    OCRReorderableCollectionViewDataSource, OCRReorderableCollectionViewDelegateFlowLayout>

@property (nonatomic, strong) OCRDetailViewController       *detailViewController;

@property (nonatomic, strong) NSFetchedResultsController    *fetchedResultsController;
@property (nonatomic, strong) NSManagedObjectContext        *managedObjectContext;


@end
