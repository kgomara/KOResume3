//
//  OCRBaseDetailViewController.h
//  KOResume
//
//  Created by Kevin O'Mara on 7/14/13.
//  Copyright (c) 2013 O'Mara Consulting Associates. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Packages.h"
#import "OCRPackagesViewController.h"

@protocol OCRDetailViewProtocol <NSObject>

- (void)configureView;

@end

@interface OCRBaseDetailViewController : UIViewController <UITableViewDelegate, SubstitutableDetailViewController>

@property (nonatomic, strong) Packages                      *selectedPackage;
@property (nonatomic, strong) NSFetchedResultsController    *fetchedResultsController;

@property (strong, nonatomic) UIBarButtonItem               *backButtonCached;
@property (strong, nonatomic) UIPopoverController           *popoverControllerCached;

@property (nonatomic, strong) NSString                      *backButtonTitle;

@property (nonatomic, strong) IBOutlet UILabel              *titleLabel;

- (void)reloadFetchedResults:(NSNotification*)note;

@end
