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

//@class OCRBaseDetailViewController;

@protocol SubstitutableDetailViewController <NSObject>

- (void)showRootPopoverButtonItem:(UIBarButtonItem *)aBarButtonItem
                   withController:(UIPopoverController *)aPopoverController;
- (void)invalidateRootPopoverButtonItem:(UIBarButtonItem *)aBarButtonItem;

@end

#import <CoreData/CoreData.h>

@interface OCRPackagesViewController : UICollectionViewController <NSFetchedResultsControllerDelegate, UISplitViewControllerDelegate,
                                                                   OCAEditableCollectionViewDataSource, OCAEditableCollectionViewDelegateFlowLayout>

//@property (nonatomic, strong) UISplitViewController         *splitViewController;

@property (nonatomic, strong) NSString                      *packageName;
@property (nonatomic, strong) UIPopoverController           *packagesPopoverController;
@property (nonatomic, strong) UIBarButtonItem               *rootPopoverButtonItem;

@property (nonatomic, strong) NSFetchedResultsController    *fetchedResultsController;
@property (nonatomic, strong) NSManagedObjectContext        *managedObjectContext;


@end
