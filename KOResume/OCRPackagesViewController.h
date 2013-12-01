//
//  OCRPackagesViewController.h
//  KOResume
//
//  Created by Kevin O'Mara on 7/14/13.
//  Copyright (c) 2013 O'Mara Consulting Associates. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OCAEditableCollectionViewFlowLayout.h"
#import "OCRPackagesCell.h"

@class OCRBaseDetailViewController;

#import <CoreData/CoreData.h>

@interface OCRPackagesViewController : UICollectionViewController <NSFetchedResultsControllerDelegate,
                                                                    OCAEditableCollectionViewDataSource, OCAEditableCollectionViewDelegateFlowLayout>

@property (nonatomic, strong) OCRBaseDetailViewController       *detailViewController;

@property (nonatomic, strong) NSFetchedResultsController    *fetchedResultsController;
@property (nonatomic, strong) NSManagedObjectContext        *managedObjectContext;


@end
