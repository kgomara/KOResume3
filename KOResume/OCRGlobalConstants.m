//
//  GlobalConstants.m
//  KOResume
//
//  Created by Kevin O'Mara on 6/11/13.
//  Copyright (c) 2013 O'Mara Consulting Associates. All rights reserved.
//

#import "OCRGlobalConstants.h"

@implementation OCRGlobalConstants

// App constants
NSString *const OCRDatabaseName                                             = @"KOResume";
NSString *const OCRDatabaseType                                             = @"sqlite";
NSString *const OCRUbiquityID                                               = @"<insert your key here>";


// Notifications
NSString *const OCRApplicationDidAddPersistentStoreCoordinatorNotification  = @"RefetchAllDatabaseData";
NSString *const OCRApplicationDidMergeChangesFrom_iCloudNotification        = @"RefreshAllViews";

// Database Attribute names
NSString *const OCRSequenceNumberAttributeName                              = @"sequence_number";

// View Controller XIBs
NSString *const OCRSummaryViewController                                    = @"SummaryViewController";
NSString *const OCRJobsDetailViewController                                 = @"JobsDetailViewController";
NSString *const OCREducationViewController                                  = @"EducationViewController";
//NSString *const OCRPackagesViewController                                   = @"PackagesViewController";
NSString *const OCRAccomplishmentsViewController                            = @"AccomplishmentViewController";
NSString *const OCRCoverLtrID                                               = @"OCRCoverLtrID";
NSString *const OCRResumeViewController                                     = @"ResumeViewController";
NSString *const OCRInfoViewController                                       = @"InfoViewController";

// Storyboard segues
NSString *const OCRCvrLtrSegue                                              = @"OCRCvrLtrSegue";

// Miscellaneous constants
CGFloat const OCRAddButtonWidth                                             = 29.0f;
CGFloat const OCRAddButtonHeight                                            = 29.0f;
NSString *const OCRUndoActionName                                           = @"Packages_Editing";
NSString *const OCRCellID                                                   = @"Cell";
NSString *const OCRPackagesCellID                                           = @"OCRPackagesCell";

@end
