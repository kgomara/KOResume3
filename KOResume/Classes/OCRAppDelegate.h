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
- (void)saveContext;

/**
 Save any changes made to the NSManagedObjectContext and return when the operation completes.
 
 This method adds the block to the backing queue to run on its own thread, however does not return until the
 block is finished executing.
 
 @param moc the managed object context to save.
 */
- (void)saveContextAndWait;

/**
 Display an alert message to the user.
 
 @param aMessage    The message to display.
 @param aType       Alert type to display (typically, Information, Warning, Error).
 @param aTarget     Target viewController for the alert.
 */
//----------------------------------------------------------------------------------------------------------
- (void)showAlertWithMessageAndType: (NSString*)theMessage
                          alertType: (NSString*)theType
                             target: (UIViewController *)aTarget;

/**
 Display an alert message to the user indicating Error.
 
 @param theMessage The message to display.
 @param aTarget     Target viewController for the alert.
*/
//----------------------------------------------------------------------------------------------------------
- (void)showErrorWithMessage:(NSString*)theMessage
                      target: (UIViewController *)aTarget;

/**
 Display an alert message for the user indicating Warning.
 
 @param theMessage The message to display.
 @param aTarget     Target viewController for the alert.
 */
//----------------------------------------------------------------------------------------------------------
- (void)showWarningWithMessage:(NSString*)theMessage
                        target: (UIViewController *)aTarget;


@end
