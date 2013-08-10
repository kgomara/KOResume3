//
//  GlobalConstants.m
//  KOResume
//
//  Created by Kevin O'Mara on 6/11/13.
//  Copyright (c) 2013 O'Mara Consulting Associates. All rights reserved.
//

#import "GlobalConstants.h"

@implementation GlobalConstants

// App constants
NSString *const KODatabaseName                                              = @"KOResume";
NSString *const KODatabaseType                                              = @"sqlite";
NSString *const KOUbiquityID                                                = @"CVC369LW49.com.kevingomara.koresume";


// Notifications
NSString *const KOApplicationDidAddPersistentStoreCoordinatorNotification  = @"RefetchAllDatabaseData";
NSString *const KOApplicationDidMergeChangesFrom_iCloudNotification         = @"RefreshAllViews";

// Database Attribute names
NSString *const KOSequenceNumberAttributeName                               = @"sequence_number";

// View Controller XIBs
NSString *const KOSummaryViewController                                     = @"SummaryViewController";
NSString *const KOJobsDetailViewController                                  = @"JobsDetailViewController";
NSString *const KOEducationViewController                                   = @"EducationViewController";
NSString *const KOPackagesViewController                                    = @"PackagesViewController";
NSString *const KOAccomplishmentsViewController                             = @"AccomplishmentViewController";
NSString *const KOCoverLtrViewController                                    = @"CoverLtrViewController";
NSString *const KOResumeViewController                                      = @"ResumeViewController";
NSString *const KOInfoViewController                                        = @"InfoViewController";

// Miscellaneous constants
CGFloat const KOAddButtonWidth                                              = 29.0f;
CGFloat const KOAddButtonHeight                                             = 29.0f;
NSString *const KOUndoActionName                                            = @"Packages_Editing";
NSString *const KOCellID                                                    = @"Cell";
NSString *const OCRPackagesCellID                                           = @"OCRPackagesCell";

@end
