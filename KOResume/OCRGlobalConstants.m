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
NSString *const kOCRDatabaseName                                             = @"KOResume";
NSString *const kOCRDatabaseType                                             = @"sqlite";
NSString *const kOCRUbiquityID                                               = @"<insert your key here>";


// Notifications
NSString *const kOCRApplicationDidAddPersistentStoreCoordinatorNotification  = @"RefetchAllDatabaseData";
NSString *const kOCRApplicationDidMergeChangesFrom_iCloudNotification        = @"RefreshAllViews";

// Database Attribute names
NSString *const kOCRSequenceNumberAttributeName                              = @"sequence_number";

// View Controller XIBs
NSString *const kOCRSummaryViewController                                    = @"SummaryViewController";
NSString *const kOCRJobsDetailViewController                                 = @"JobsDetailViewController";
NSString *const kOCREducationViewController                                  = @"EducationViewController";
NSString *const kOCRPackagesViewController                                   = @"PackagesViewController";
NSString *const kOCRAccomplishmentsViewController                            = @"AccomplishmentViewController";
NSString *const kOCRCoverLtrID                                               = @"OCRCoverLtrID";
NSString *const kOCRResumeViewController                                    = @"ResumeViewController";
NSString *const kOCRInfoViewController                                       = @"InfoViewController";

// Storyboard segues
NSString *const kOCRCvrLtrSegue                                              = @"OCRCvrLtrSegue";
NSString *const kOCRResumeSegue                                             = @"OCRResumeSegue";

// Miscellaneous constants
CGFloat const kOCRAddButtonWidth                                             = 29.0f;
CGFloat const kOCRAddButtonHeight                                            = 29.0f;
NSString *const kOCRUndoActionName                                           = @"Packages_Editing";
NSString *const kOCRCellID                                                   = @"Cell";
NSString *const kOCRPackagesCellID                                           = @"OCRPackagesCell";

@end
