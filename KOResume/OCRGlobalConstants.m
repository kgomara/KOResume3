//
//  GlobalConstants.m
//  KOResume
//
//  Created by Kevin O'Mara on 6/11/13.
//  Copyright (c) 2013-2014 O'Mara Consulting Associates. All rights reserved.
//

#import "OCRGlobalConstants.h"
#import "OCRPrivateKeys.h"

@implementation OCRGlobalConstants

// App constants
NSString *const kOCRDatabaseName                                            = @"KOResume";
NSString *const kOCRDatabaseType                                            = @"sqlite";
NSString *const kOCRUbiquityID                                              = kPrivateOCRUbiquityID;


// Notifications
NSString *const kOCRApplicationDidAddPersistentStoreCoordinatorNotification = @"RefetchAllDatabaseData";
NSString *const kOCRApplicationDidMergeChangesFrom_iCloudNotification       = @"RefreshAllViews";
NSString *const kOCRMocDidDeletePackageNotification                         = @"MocDidDeletePackage";

// Database Attribute names
NSString *const kOCRSequenceNumberAttributeName                             = @"sequence_number";

// View Controller XIBs
NSString *const kOCRSummaryViewController                                   = @"SummaryViewController";
NSString *const kOCRJobsDetailViewController                                = @"JobsDetailViewController";
NSString *const kOCREducationViewController                                 = @"EducationViewController";
NSString *const kOCRPackagesViewController                                  = @"PackagesViewController";
NSString *const kOCRAccomplishmentsViewController                           = @"AccomplishmentViewController";
NSString *const kOCRCoverLtrID                                              = @"OCRCoverLtrID";
NSString *const kOCRResumeViewController                                    = @"ResumeViewController";
NSString *const kOCRInfoViewController                                      = @"InfoViewController";
NSString *const kOCRDateTableViewController                                 = @"OCRDateTableViewController";

// Storyboard segues
NSString *const kOCRCvrLtrSegue                                             = @"OCRCvrLtrSegue";
NSString *const kOCRResumeSegue                                             = @"OCRResumeSegue";
NSString *const kOCRJobsSegue                                               = @"OCRJobsSegue";
NSString *const kOCREducationSegue                                          = @"OCREducationSegue";
NSString *const kOCRDateControllerSegue                                     = @"OCRDateControllerSegue";

// Miscellaneous constants
CGFloat const kOCRAddButtonWidth                                            = 29.0f;
CGFloat const kOCRAddButtonHeight                                           = 29.0f;
NSString *const kOCRUndoActionName                                          = @"Packages_Editing";
NSString *const kOCRCellID                                                  = @"Cell";
NSString *const kOCRPackagesCellID                                          = @"OCRPackagesCell";
NSString *const kOCRSubtitleTableCell                                       = @"OCRSubtitleTableCell";
NSString *const kOCRBasicTableCell                                          = @"OCRBasicTableCell";
NSString *const kOCRJobsTableCell                                           = @"OCRJobsTableCell";
NSString *const kOCREducationTableCell                                      = @"OCREducationTableCell";
NSString *const kOCRAccomplishmentTableCell                                 = @"OCRAccomplishmentTableCell";
NSString *const kOCRDateClearTableCell                                      = @"OCRDateClearTableCell";
NSString *const kOCRDateHeaderTableCell                                     = @"OCRDateHeaderTableCell";
NSString *const kOCRDatePickerTableCell                                     = @"OCRDatePickerTableCell";

@end
