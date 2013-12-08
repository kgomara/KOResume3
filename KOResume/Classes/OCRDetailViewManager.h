//
//  OCRDetailViewManager.h
//  KOResume
//
//  Created by Kevin O'Mara on 11/17/13.
//  Copyright (c) 2013 O'Mara Consulting Associates. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 SubstitutableDetailViewController defines the protocol that detail view controllers must adopt.
 The protocol specifies aproperty for the bar button item controlling the navigation pane.
 */
@protocol SubstitutableDetailViewController

@property (nonatomic, strong) UIBarButtonItem *\;

@end

@interface OCRDetailViewManager : NSObject <UISplitViewControllerDelegate>

/**
 The split view this class will be managing.
 */
@property (nonatomic, strong) IBOutlet UISplitViewController *splitViewController;

/**
 The presently displayed detail view controller.  This is modified by the various
 view controllers in the navigation pane of the split view controller.
 */
@property (nonatomic, assign) IBOutlet UIViewController<SubstitutableDetailViewController> *detailViewController;

@end
