//
//  GlobalConstants.h
//  KOResume
//
//  Created by Kevin O'Mara on 6/11/13.
//  Copyright (c) 2013 O'Mara Consulting Associates. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GlobalConstants : NSObject

// App constants
FOUNDATION_EXPORT NSString *const KODatabaseName;
FOUNDATION_EXPORT NSString *const KODatabaseType;
FOUNDATION_EXPORT NSString *const KOUbiquityID;


// Notifications
FOUNDATION_EXPORT NSString *const KOApplicationDidAddPersistentStoreCoordinatorNotification;
FOUNDATION_EXPORT NSString *const KOApplicationDidMergeChangesFrom_iCloudNotification;

// Database Attribute names
FOUNDATION_EXPORT NSString *const KOSequenceNumberAttributeName;

// View Controller XIBs
FOUNDATION_EXPORT NSString *const KOSummaryViewController;
FOUNDATION_EXPORT NSString *const KOJobsDetailViewController;
FOUNDATION_EXPORT NSString *const KOEducationViewController;
FOUNDATION_EXPORT NSString *const KOPackagesViewController;
FOUNDATION_EXPORT NSString *const KOAccomplishmentsViewController;
FOUNDATION_EXPORT NSString *const KOCoverLtrViewController;
FOUNDATION_EXPORT NSString *const KOResumeViewController;
FOUNDATION_EXPORT NSString *const KOInfoViewController;

// Miscellaneous constants
extern CGFloat const KOAddButtonWidth;
extern CGFloat const KOAddButtonHeight;

FOUNDATION_EXPORT NSString *const KOUndoActionName;
FOUNDATION_EXPORT NSString *const KOCellID;
FOUNDATION_EXPORT NSString *const OCRPackagesCellID;

@end
