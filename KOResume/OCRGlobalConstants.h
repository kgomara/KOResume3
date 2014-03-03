//
//  OCRGlobalConstants.h
//  KOResume
//
//  Created by Kevin O'Mara on 6/11/13.
//  Copyright (c) 2013-2014 O'Mara Consulting Associates. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OCRGlobalConstants : NSObject

// App constants
FOUNDATION_EXPORT NSString *const kOCRDatabaseName;
FOUNDATION_EXPORT NSString *const kOCRDatabaseType;
FOUNDATION_EXPORT NSString *const kOCRUbiquityID;


// Notifications
FOUNDATION_EXPORT NSString *const kOCRApplicationDidAddPersistentStoreCoordinatorNotification;
FOUNDATION_EXPORT NSString *const kOCRApplicationDidMergeChangesFrom_iCloudNotification;

// Database Attribute names
FOUNDATION_EXPORT NSString *const kOCRSequenceNumberAttributeName;

// View Controller XIBs
FOUNDATION_EXPORT NSString *const kOCRSummaryViewController;
FOUNDATION_EXPORT NSString *const kOCRJobsDetailViewController;
FOUNDATION_EXPORT NSString *const kOCREducationViewController;
FOUNDATION_EXPORT NSString *const kOCRPackagesViewController;
FOUNDATION_EXPORT NSString *const kOCRAccomplishmentsViewController;
FOUNDATION_EXPORT NSString *const kOCRCoverLtrID;
FOUNDATION_EXPORT NSString *const kOCRResumeViewController;
FOUNDATION_EXPORT NSString *const kOCRInfoViewController;

// Storyboard segues
FOUNDATION_EXPORT NSString *const kOCRCvrLtrSegue;
FOUNDATION_EXPORT NSString *const kOCRResumeSegue;

// Miscellaneous constants
extern CGFloat const kOCRAddButtonWidth;
extern CGFloat const kOCRAddButtonHeight;

FOUNDATION_EXPORT NSString *const kOCRUndoActionName;
FOUNDATION_EXPORT NSString *const kOCRCellID;
FOUNDATION_EXPORT NSString *const kOCRPackagesCellID;

@end
