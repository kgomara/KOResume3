//
//  OCRDetailViewController.h
//  KOResume
//
//  Created by Kevin O'Mara on 7/14/13.
//  Copyright (c) 2013 O'Mara Consulting Associates. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Packages.h"
#import "OCRDetailViewManager.h"

@protocol OCRDetailViewSubclass <NSObject>

- (void)configureView;

@end

@interface OCRDetailViewController : UIViewController <UISplitViewControllerDelegate, SubstitutableDetailViewController, UITableViewDelegate>

@property (nonatomic, strong) Packages                      *selectedPackage;
@property (nonatomic, strong) NSFetchedResultsController    *fetchedResultsController;
@property (nonatomic, strong) NSString                      *backButtonTitle;

@property (nonatomic, strong) IBOutlet UILabel              *titleLabel;
@property (nonatomic, strong) UIBarButtonItem               *navigationPaneBarButtonItem;

- (void)reloadFetchedResults:(NSNotification*)note;

@end
