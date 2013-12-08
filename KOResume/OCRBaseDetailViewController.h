//
//  OCRBaseDetailViewController.h
//  KOResume
//
//  Created by Kevin O'Mara on 7/14/13.
//  Copyright (c) 2013 O'Mara Consulting Associates. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Packages.h"

@protocol OCRDetailViewProtocol <NSObject>

- (void)configureView;

@end

@interface OCRBaseDetailViewController : UIViewController <UITableViewDelegate>

@property (nonatomic, strong) Packages                      *selectedPackage;
@property (nonatomic, strong) NSFetchedResultsController    *fetchedResultsController;
@property (nonatomic, strong) NSString                      *backButtonTitle;

@property (nonatomic, strong) IBOutlet UILabel              *titleLabel;

- (void)reloadFetchedResults:(NSNotification*)note;

@end
