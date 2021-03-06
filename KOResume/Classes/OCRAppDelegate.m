//
//  OCRAppDelegate.m
//  KOResume
//
//  Created by Kevin O'Mara on 3/9/11.
//  Copyright (c) 2011-2014 O'Mara Consulting Associates. All rights reserved.
//

#import "OCRAppDelegate.h"
#import "OCRPackagesTableViewController.h"
#import "OCRCoverLtrViewController.h"
#import <Crashlytics/Crashlytics.h>

@interface OCRAppDelegate ()

@property (nonatomic, strong) OCRPackagesTableViewController *masterViewController;

@property (nonatomic, strong) OCRCoverLtrViewController *detailViewController;

@end

@implementation OCRAppDelegate

#pragma mark - Application lifecycle

//----------------------------------------------------------------------------------------------------------
/**
 Invoked by the framework when the launch process is almost done and the app is almost ready to run.
 
 @param application The UIApplication singleton app object.
 @param launchOptions   An NSDictionary indicating the reason the app was launched (if any).
 @return BOOL           Always returns YES.
 */
- (BOOL)            application: (UIApplication *)application
  didFinishLaunchingWithOptions: (NSDictionary *)launchOptions
{
    // Initialize CoreDataController
    _coreDataController = [[OCRCoreDataController alloc] init];
    
    // Set the overall tint color
    self.window.tintColor = [UIColor redColor];     // window is nil!!!!!
    
    // Start Crashylytics
    [Crashlytics startWithAPIKey:@"968d85136f3c0349a40d5a6e4c9d57de317e3977"];
//    [[Crashlytics sharedInstance] crash];
    
    // Initialize the coreDataController class.
    _managedObjectContext = self.coreDataController.managedObjectContext;
    if (!_managedObjectContext)
    {
        CLS_LOG(@"Could not get managedObjectContext");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Error", nil)
                                                        message: NSLocalizedString(@"Failed to open database.", nil)
                                                       delegate: self
                                              cancelButtonTitle: NSLocalizedString(@"OK", nil)
                                              otherButtonTitles: nil];
        [alert show];
    }
    
    // Setup Master-Detail controller paradigm
    UISplitViewController *splitViewController      = (UISplitViewController *)self.window.rootViewController;
    // Get the nav controller containing the OCRPackagesViewController
    UINavigationController *navigationController    = [splitViewController.viewControllers firstObject];
    // ...and maintain a reference to it.
    self.masterViewController   = (OCRPackagesTableViewController *)navigationController.topViewController;
    
    // Similarly, get the UINavigation controller in which the OCRCoverLtrViewController is embedded
    navigationController        = [splitViewController.viewControllers lastObject];
    // ...and maintain a reference to it.
    self.detailViewController   = (OCRCoverLtrViewController *)navigationController.topViewController;
    
    // Set OCRPackagesViewController as  delegate of the UISplitViewController
    splitViewController.delegate = self.masterViewController;
    
    return YES;
}

//----------------------------------------------------------------------------------------------------------
/**
 Invoked by the framework when the app is about to become inactive.
 
 @param application The UIApplication singleton app object.
 */
- (void)applicationWillResignActive: (UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types
     of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the
     application and it begins the transition to the background state.
     
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games
     should use this method to pause the game.
     */
    DLog();
}

//----------------------------------------------------------------------------------------------------------
/**
 Invoked by the framework when the application is put into the background.
 
 @param application The UIApplication singleton app object.
 */
- (void)applicationDidEnterBackground: (UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough
     application state information to restore your application to its current state in case it is terminated
     later.
     
     If your application supports background execution, called instead of applicationWillTerminate: when the
     user quits.
     */
    DLog();
}

//----------------------------------------------------------------------------------------------------------
/**
 Invoked by the framework when the app is about to enter foreground.
 
 @param application The UIApplication singleton app object.
 */
- (void)applicationWillEnterForeground: (UIApplication *)application
{
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the
     changes made on entering the background.
     */
    DLog();
}

//----------------------------------------------------------------------------------------------------------
/**
 Invoked by the framework when the application has become active.
 
 @param application The UIApplication singleton app object.
 */
- (void)applicationDidBecomeActive: (UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
    DLog();
}

//----------------------------------------------------------------------------------------------------------
/**
 Invoked by the framework when the application is about to terminate.
 
 @param application The UIApplication singleton app object.
 */
- (void)applicationWillTerminate: (UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
    DLog();
    
    [self saveContext];
}

#pragma mark - Memory management

//----------------------------------------------------------------------------------------------------------
/**
 Invoked by the framework when the app receives a memory warning from the system.

 @param application The UIApplication singleton app object.
 */
- (void)applicationDidReceiveMemoryWarning: (UIApplication *)application
{
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded
     from disk) later.
     */
    CLS_LOG();
}


//----------------------------------------------------------------------------------------------------------
- (void)saveContext
{
    DLog();
    
    // Save changes to application's managed object context
    [self.managedObjectContext performBlock:^{
        if ([self.managedObjectContext hasChanges])
        {
            NSError *error = nil;
            if ([self.managedObjectContext save: &error])
            {
                DLog(@"Save successful");
            }
            else
            {
                ELog(error, @"Failed to save data");
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Error", nil)
                                                                message: NSLocalizedString(@"Failed to save data.", nil)
                                                               delegate: self
                                                      cancelButtonTitle: NSLocalizedString(@"OK", nil)
                                                      otherButtonTitles: nil];
                [alert show];
            }
        }
        else
        {
            DLog(@"No changes to save");
        }
    }];
}


//----------------------------------------------------------------------------------------------------------
- (void)saveContextAndWait
{
    DLog();
    
    // Save changes to application's managed object context.
    __block NSError *error = nil;
    [self.managedObjectContext performBlockAndWait:^{
        [self.managedObjectContext save: &error];
    }];
    if (error)
    {
        ELog(error, @"Failed to save data");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Error", nil)
                                                        message: NSLocalizedString(@"Failed to save data.", nil)
                                                       delegate: self
                                              cancelButtonTitle: NSLocalizedString(@"OK", nil)
                                              otherButtonTitles: nil];
        [alert show];
    }
    else
    {
        DLog(@"Save successful");
    }
}

// =========================================================================================================
#pragma mark - Public class methods
// =========================================================================================================

//----------------------------------------------------------------------------------------------------------
- (void)showAlertWithMessageAndType: (NSString*)aMessage
                          alertType: (NSString*)aType
                             target: (UIViewController *)aTarget
{
    // Set up a UIAlertController
    UIAlertController *alert = [UIAlertController alertControllerWithTitle: aType
                                                                   message: aMessage
                                                            preferredStyle: UIAlertControllerStyleAlert];
    // ...add an OK action
    [alert addAction: [UIAlertAction actionWithTitle: NSLocalizedString(@"OK", nil)
                                               style: UIAlertActionStyleDefault
                                             handler: nil]];
    
    // ...and present the alert to the user
    [aTarget presentViewController: alert
                          animated: YES
                        completion: nil];
}

//----------------------------------------------------------------------------------------------------------
- (void)showErrorWithMessage: (NSString*)aMessage
                      target: (UIViewController *)aTarget
{
    [self showAlertWithMessageAndType: aMessage
                            alertType: NSLocalizedString( @"Error", @"Error")
                               target: aTarget];
}

//----------------------------------------------------------------------------------------------------------
- (void)showWarningWithMessage: (NSString*)aMessage
                        target: (UIViewController *)aTarget
{
    [self showAlertWithMessageAndType: aMessage
                            alertType: NSLocalizedString(@"Warning", @"Warning")
                               target: aTarget];
}



@end
