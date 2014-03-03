//
//  OCRAppDelegate.h
//  KOResume
//
//  Created by Kevin O'Mara on 3/9/11.
//  Copyright (c) 2011-2014 O'Mara Consulting Associates. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OCRCoreDataController.h"

/**
 This class is the Application Delegate for KOResume.
 */
@interface OCRAppDelegate : UIResponder <UIApplicationDelegate>

/**
 The window for KOResume.
 */
@property (strong, nonatomic) UIWindow                          *window;

/**
 The managed object context for KOResume.
 */
@property (nonatomic, strong, readonly) NSManagedObjectContext  *managedObjectContext;

/**
 Reference to the core data controller object for KOResume.
 */
@property (nonatomic, strong, readonly) OCRCoreDataController   *coreDataController;


/**
 Save any changes made to the NSManagedObjectContext and returns immediately.
 
 This method adds the block to the backing queue to run on its own thread - i.e., asynchronously. The method
 will return to its caller immediately.
 
 @param moc the managed object context to save.
 */
- (void)saveContext:(NSManagedObjectContext *)moc;

/**
 Save any changes made to the NSManagedObjectContext and return when the operation completes.
 
 This method adds the block to the backing queue to run on its own thread, however does not return until the
 block is finished executing.
 
 @param moc the managed object context to save.
 */
- (void)saveContextAndWait:(NSManagedObjectContext *)moc;

@end
