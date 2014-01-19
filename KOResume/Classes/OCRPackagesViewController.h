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
#import <CoreData/CoreData.h>

/**
 SubstitutableDetailViewController is a protocol that detail view controllers must adopt. It defines methods to hide or show
 the bar button item controlling the popover.
 */
@protocol SubstitutableDetailViewController <NSObject>

@required

/**
 The master view controller will call this method on the detail view when the bar button item should be shown.
 
 @param aBarButtonItem      the UIBarButtonItem to show
 @param aPopoverController  the UIPopoverController of the master view controller
 */
- (void)showRootPopoverButtonItem:(UIBarButtonItem *)aBarButtonItem
                   withController:(UIPopoverController *)aPopoverController;

/**
 The master view controller will call this method on the detail view when the bar button item should be hidden
 
 @param aBarButtonItem      the UIBarButtonItem to hide
 */
- (void)invalidateRootPopoverButtonItem:(UIBarButtonItem *)aBarButtonItem;

@end

@interface OCRPackagesViewController : UICollectionViewController <NSFetchedResultsControllerDelegate, UISplitViewControllerDelegate,
                                                                   OCAEditableCollectionViewDataSource, OCAEditableCollectionViewDelegateFlowLayout>

@end
