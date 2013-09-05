//
//  OCRAppDelegate.m
//  KOResume
//
//  Created by Kevin O'Mara on 7/14/13.
//  Copyright (c) 2013 O'Mara Consulting Associates. All rights reserved.
//

#import "OCRAppDelegate.h"

#import "OCRPackagesViewController.h"

@implementation OCRAppDelegate

@synthesize managedObjectContext        = _managedObjectContext;

@synthesize coreDataController          = _coreDataController;

#pragma mark - Application lifecycle

//----------------------------------------------------------------------------------------------------------
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Initialize CoreDataController
    _coreDataController = [[OCRCoreDataController alloc] init];
    
    // Set the overall tint color
    self.window.tintColor = [UIColor redColor];
    
    _managedObjectContext = self.coreDataController.managedObjectContext;
    if (!_managedObjectContext) {
        ALog(@"Could not get managedObjectContext");
        NSString *msg = NSLocalizedString(@"Failed to open database.", nil);
        [OCAExtensions showErrorWithMessage: msg];
    }
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        // Setup Master-Detail controller paradigm for iPad
        UISplitViewController *splitViewController          = (UISplitViewController *)self.window.rootViewController;
        UINavigationController *navigationController        = [splitViewController.viewControllers lastObject];
        splitViewController.delegate                        = (id)navigationController.topViewController;
        
        // ...and setup OCRPackagesViewController as Master
        UINavigationController *masterNavigationController  = splitViewController.viewControllers[0];
        OCRPackagesViewController *controller               = (OCRPackagesViewController *)masterNavigationController.topViewController;
        controller.managedObjectContext                     = self.managedObjectContext;
    } else {
        // ...setup navigationController paradigm for iPhone
        UINavigationController *navigationController    = (UINavigationController *)self.window.rootViewController;
        OCRPackagesViewController *controller           = (OCRPackagesViewController *)navigationController.topViewController;
        controller.managedObjectContext                 = self.managedObjectContext;
    }
    return YES;
}
							
//----------------------------------------------------------------------------------------------------------
- (void)applicationWillResignActive:(UIApplication *)application
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
- (void)applicationDidEnterBackground:(UIApplication *)application
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
- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the
     changes made on entering the background.
     */
    DLog();
}

//----------------------------------------------------------------------------------------------------------
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
    DLog();
}

//----------------------------------------------------------------------------------------------------------
- (void)applicationWillTerminate:(UIApplication *)application
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
- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
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
        if ([moc hasChanges]) {
            NSError *error = nil;
            if ([moc save: &error]) {
                DLog(@"Save successful");
            } else {
                ELog(error, @"Failed to save data");
                NSString* msg = NSLocalizedString( @"Failed to save data.", nil);
                [OCAExtensions showErrorWithMessage: msg];
            }
        } else {
            DLog(@"No changes to save");
        }
    }];
}


@end
