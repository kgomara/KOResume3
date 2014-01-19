//
//  OCRAppDelegate.h
//  KOResume
//
//  Created by Kevin O'Mara on 7/14/13.
//  Copyright (c) 2013-2014 O'Mara Consulting Associates. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OCRCoreDataController.h"

/**
 This class is the Application Delegate for KOResume
 */
@interface OCRAppDelegate : UIResponder <UIApplicationDelegate>

/**
 The window for KOResume
 */
@property (strong, nonatomic) UIWindow                          *window;

/**
 The managed object context for KOResume
 */
@property (nonatomic, strong, readonly) NSManagedObjectContext  *managedObjectContext;

/**
 Reference to the core data controller object for KOResume
 */
@property (nonatomic, strong, readonly) OCRCoreDataController   *coreDataController;


- (void)saveContext:(NSManagedObjectContext *)moc;

@end
