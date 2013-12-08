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
FOUNDATION_EXPORT NSString *const OCRDatabaseName;
FOUNDATION_EXPORT NSString *const OCRDatabaseType;
FOUNDATION_EXPORT NSString *const OCRUbiquityID;


// Notifications
FOUNDATION_EXPORT NSString *const OCRApplicationDidAddPersistentStoreCoordinatorNotification;
FOUNDATION_EXPORT NSString *const OCRApplicationDidMergeChangesFrom_iCloudNotification;

// Database Attribute names
FOUNDATION_EXPORT NSString *const OCRSequenceNumberAttributeName;

// View Controller XIBs
FOUNDATION_EXPORT NSString *const OCRSummaryViewController;
FOUNDATION_EXPORT NSString *const OCRJobsDetailViewController;
FOUNDATION_EXPORT NSString *const OCREducationViewController;
//FOUNDATION_EXPORT NSString *const OCRPackagesViewController;
FOUNDATION_EXPORT NSString *const OCRAccomplishmentsViewController;
FOUNDATION_EXPORT NSString *const OCRCoverLtrID;
FOUNDATION_EXPORT NSString *const OCRResumeViewController;
FOUNDATION_EXPORT NSString *const OCRInfoViewController;

// Storyboard segues
FOUNDATION_EXPORT NSString *const OCRCvrLtrSegue;

// Miscellaneous constants
extern CGFloat const OCRAddButtonWidth;
extern CGFloat const OCRAddButtonHeight;

FOUNDATION_EXPORT NSString *const OCRUndoActionName;
FOUNDATION_EXPORT NSString *const OCRCellID;
FOUNDATION_EXPORT NSString *const OCRPackagesCellID;

@end
