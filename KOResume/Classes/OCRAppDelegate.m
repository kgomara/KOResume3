//
//  OCRAppDelegate.m
//  KOResume
//
//  Created by Kevin O'Mara on 3/9/11.
//  Copyright (c) 2011-2014 O'Mara Consulting Associates. All rights reserved.
//

#import "OCRAppDelegate.h"
#import "OCRPackagesViewController.h"

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
    
    // Initialize the coreDataController class.
    _managedObjectContext = self.coreDataController.managedObjectContext;
    if (!_managedObjectContext)
    {
        ALog(@"Could not get managedObjectContext");
        NSString *msg = NSLocalizedString(@"Failed to open database.", nil);
        [OCAUtilities showErrorWithMessage: msg];
    }
    
    // Setup Master-Detail controller paradigm
    UISplitViewController *splitViewController      = (UISplitViewController *)self.window.rootViewController;
//    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
//    {
        UINavigationController *navigationController    = [splitViewController.viewControllers lastObject];
        splitViewController.delegate                    = (id)navigationController.topViewController;
//    }
//    else
//    {
//        splitViewController.delegate = [splitViewController.viewControllers lastObject];
        DLog(@"class=%@", [[splitViewController.viewControllers lastObject] class]);
//    }
    
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
    
    [self saveContext: _managedObjectContext];
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
    ALog();
}


//----------------------------------------------------------------------------------------------------------
- (void)saveContext: (NSManagedObjectContext *)moc
{
    DLog();
    
    // Save changes to application's managed object context
    [moc performBlock:^{
        if ([moc hasChanges])
        {
            NSError *error = nil;
            if ([moc save: &error])
            {
                DLog(@"Save successful");
            }
            else
            {
                ELog(error, @"Failed to save data");
                NSString* msg = NSLocalizedString( @"Failed to save data.", nil);
                [OCAUtilities showErrorWithMessage: msg];
            }
        }
        else
        {
            DLog(@"No changes to save");
        }
    }];
}


//----------------------------------------------------------------------------------------------------------
- (void)saveContextAndWait: (NSManagedObjectContext *)moc
{
    DLog();
    
    // Save changes to application's managed object context.
    __block NSError *error = nil;
    [moc performBlockAndWait:^{
        [moc save: &error];
    }];
    if (error) {
        ELog(error, @"Failed to save data");
        NSString* msg = NSLocalizedString( @"Failed to save data.", nil);
        [OCAUtilities showErrorWithMessage: msg];
    } else {
        DLog(@"Save successful");
    }
}


@end
