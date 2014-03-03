//
//  OCRBaseDetailViewController.h
//  KOResume
//
//  Created by Kevin O'Mara on 7/14/13.
//  Copyright (c) 2013-2014 O'Mara Consulting Associates. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Packages.h"
#import "OCRPackagesViewController.h"

/**
 OCRDetailViewProtocol is a protocol that detail view controllers must adopt. It defines methods that the base class can invoke on subclasses.
 */
@protocol OCRDetailViewProtocol <NSObject>

@required

/**
 The method is called on the subclass when the selectedManagedObject changes.
 
 The subclass should update it's view to reflect the new data and perform other operations
 appropriate for its context.
 */
- (void)configureView;

@end

/**
 This class defines common properties and methods for detail veiw controllers
 */
@interface OCRBaseDetailViewController : UIViewController <UITableViewDelegate, SubstitutableDetailViewController>

/**
 The package the user selected in the master view controller
 */
@property (nonatomic, strong) NSManagedObject               *selectedManagedObject;

/**
 The fetchedResultsController used to retrieve the selectedPackage
 */
@property (nonatomic, strong) NSFetchedResultsController    *fetchedResultsController;

/**
 A property used by the master view to cache the back button
 */
@property (strong, nonatomic) UIBarButtonItem               *backButtonCached;

/**
 A property used by the master view to cache the popover controller
 */
@property (strong, nonatomic) UIPopoverController           *popoverControllerCached;

/**
 A reference to the master view's popoverController
 */
@property (nonatomic, strong) UIPopoverController           *masterPopoverController;

/**
 A property used by the master view to set the back button title
 */

@property (nonatomic, strong) NSString                      *backButtonTitle;

/**
 IBOutlet to the titleLabel
 */
@property (nonatomic, strong) IBOutlet UILabel              *titleLabel;

- (void)reloadFetchedResults:(NSNotification*)note;

@end
