//
//  OCRCoreDataController.m
//  KOResume
//
//  Created by Kevin O'Mara on 3/9/11.
//  Copyright 2011-2014 O'Mara Consulting Associates. All rights reserved.
//

#import "OCRAppDelegate.h"
#import "OCRCoreDataController.h"
#import "Packages.h"

@interface OCRCoreDataController ()
{
    
}

@property (nonatomic, strong, readonly) NSManagedObjectModel            *managedObjectModel;

/**
 The NSPersistentStoreCoordinator for the KOResume database
 */
@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator    *persistentStoreCoordinator;

@end

@implementation OCRCoreDataController

@synthesize managedObjectModel          = __managedObjectModel;
@synthesize managedObjectContext        = __managedObjectContext;
@synthesize persistentStoreCoordinator  = __persistentStoreCoordinator;


#pragma mark - Core Data Stack

//----------------------------------------------------------------------------------------------------------
- (NSManagedObjectContext *)managedObjectContext
{
    DLog();
    
    if (__managedObjectContext != nil) {
        return __managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSMainQueueConcurrencyType];
        
        // PerformBlockAndWait adds the block to the backing queue and schedules it to run on its own thread.
        //  The block will not return until the block is finished executing.
        //  If you can't move on until you know whether the operation was successful, then this is your choice.
        [moc performBlockAndWait: ^{
            [moc setPersistentStoreCoordinator: coordinator];
            [[NSNotificationCenter defaultCenter] addObserver: self
                                                     selector: @selector( mergeChangesFrom_iCloud:)
                                                         name: NSPersistentStoreDidImportUbiquitousContentChangesNotification
                                                       object: coordinator];
        }];
        __managedObjectContext = moc;
        
        // Instantiate an UndoManager
        NSUndoManager *undoManager = [[NSUndoManager alloc] init];
        [__managedObjectContext setUndoManager: undoManager];
        [__managedObjectContext setMergePolicy: NSMergeByPropertyStoreTrumpMergePolicy];
    }
    
    return __managedObjectContext;
}


//----------------------------------------------------------------------------------------------------------
/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the app's model.
 
 I use Mogenerator to generate the concrete classes for the data model (KOResume.xcdatamodel). You can download Mogenerator from
 [GitHub](http://rentzsch.github.io/mogenerator/)

 The key thing with Mogenerator is you DO NOT WANT TO use Xcode's built in model generator. I've create a build target
 */
- (NSManagedObjectModel *)managedObjectModel
{
    DLog();
    
    if (__managedObjectModel != nil) {
        return __managedObjectModel;
    }
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource: OCRDatabaseName
                                              withExtension: @"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL: modelURL];
    
    return __managedObjectModel;
}


//----------------------------------------------------------------------------------------------------------
/**
 Singleton object reference to the NSPersistentStoreCoordinator
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    DLog();
    
    if (__persistentStoreCoordinator != nil) {
        return __persistentStoreCoordinator;
    }

    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    
    // TODO - move the database to ubiquity container, so check from version 2.0 in Documents and move...
    
    if (__persistentStoreCoordinator) {
        // Set up the path to the location of the database
        // TODO need to get it inside iCloud if enabled
        NSString *docDir            = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *dbFileName        = [NSString stringWithFormat: @"%@.%@", OCRDatabaseName, OCRDatabaseType];
        NSString *dbPath            = [docDir stringByAppendingPathComponent: dbFileName];
        // TODO - need to put this in iCloud (if enabled) with .nosync
        NSURL *storeURL             = [[self applicationDocumentsDirectory] URLByAppendingPathComponent: dbFileName];
        DLog(@"Core Data store path = \"%@\"", [storeURL path]);
        
        // TODO - implement HUD
        dispatch_queue_t queue;
        queue = dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0);        // User is waiting - dispatch at high priority
        
        dispatch_async(queue, ^{
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if ( ![fileManager fileExistsAtPath: dbPath]) {
                // database does not exist, need to copy the seed database in from the app bundle
                NSURL *bundleSeedURL = [NSURL fileURLWithPath: [[NSBundle mainBundle] pathForResource: OCRDatabaseName
                                                                                               ofType: OCRDatabaseType]];
                NSError *error;
                if ([fileManager copyItemAtURL: bundleSeedURL
                                         toURL: storeURL
                                         error: &error])
                {
                    DLog(@"Copied store from bundle successfully!");
                } else {
                    ELog(error, @"Copy seed Error");
                    return;
                }
            }
            
            // A database should exist now in the user's documents, just add it to the persistent store coordinator
            // ...first, get options appropriate for iCloud available or not
            NSDictionary *options = [self createStoreOptions];
            if (options) {
                // ...load the store to the persistentStoreCoordinator
                if ([self addStore: storeURL
                           withOptions: options])
                {
                    dispatch_async( dispatch_get_main_queue(), ^{
                        DLog(@"Existing store added successfully!");
                        [[NSNotificationCenter defaultCenter] postNotificationName: OCRApplicationDidAddPersistentStoreCoordinatorNotification
                                                                            object: self
                                                                          userInfo: nil];
                        
                    });
                } else {
                    ALog(@"Failed to add store to coordinator");
                }
            } else {
                ALog(@"Failed to create options");
            }
        });
    } else {
        ALog(@"Could not inititialize NSPersistentStoreCoordinator");
    }
    
    return __persistentStoreCoordinator;
}

//----------------------------------------------------------------------------------------------------------
/**
 Helper method to configure the options for the NSPersistentStoreCoordinator object
 
 @return NSDictionry of the appropriate options
 */
- (NSDictionary *)createStoreOptions
{
    DLog();
    
    NSDictionary *options;
    
    /*
     *  iCloud has some fundamentals flaws making it (IMO), too brittle at this time
     *  ...will try again in iOS7
     */
    
//    NSURL *cloudURL                 = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier: OCRUbiquityID];
//    NSString *coreDataCloudContent  = [[cloudURL path] stringByAppendingPathComponent: @"data"];
    
//    if ([coreDataCloudContent length] != 0) {
//        // iCloud is available
//        cloudURL = [NSURL fileURLWithPath: coreDataCloudContent];
//        
//        NSString *storeName = [NSString stringWithFormat: @"%@.%@", OCRDatabaseName, @"store"];
//        options = [NSDictionary dictionaryWithObjectsAndKeys:
//                   [NSNumber numberWithBool: YES], NSMigratePersistentStoresAutomaticallyOption,
//                   [NSNumber numberWithBool: YES], NSInferMappingModelAutomaticallyOption,
//                   storeName,                      NSPersistentStoreUbiquitousContentNameKey,
//                   cloudURL,                       NSPersistentStoreUbiquitousContentURLKey,
//                   nil];
//    } else {
        // iCloud is not available
        options = [NSDictionary dictionaryWithObjectsAndKeys:
                   [NSNumber numberWithBool: YES], NSMigratePersistentStoresAutomaticallyOption,
                   [NSNumber numberWithBool: YES], NSInferMappingModelAutomaticallyOption,
                   nil];
//    }
    
    return options;
}

//----------------------------------------------------------------------------------------------------------
//- (BOOL)seedStoreFromURL: (NSURL *)seedURL
//                   toURL: (NSURL *)storeURL
//                 options: (NSDictionary *)options
//{
//    DLog(/* @"seedURL=%@, storeURL=%@", seedURL, storeURL */);
//    
//    BOOL success = NO;
//    NSDictionary *localOnlyOptions = [NSDictionary dictionaryWithObjectsAndKeys:
//                                      (id)kCFBooleanTrue, NSMigratePersistentStoresAutomaticallyOption,
//                                      (id)kCFBooleanTrue, NSInferMappingModelAutomaticallyOption,
//                                      nil];
//
//    NSError *error = nil;
//    NSPersistentStore *oldStore = [__persistentStoreCoordinator addPersistentStoreWithType: NSSQLiteStoreType
//                                                                             configuration: nil
//                                                                                       URL: seedURL
//                                                                                   options: localOnlyOptions
//                                                                                     error: &error];
//    DLog(@"added oldStore to psc");
//    if (oldStore && !error) {
//        NSPersistentStore *newStore = [__persistentStoreCoordinator migratePersistentStore: oldStore
//                                                                                     toURL: storeURL
//                                                                                   options: options
//                                                                                  withType: NSSQLiteStoreType
//                                                                                     error: &error];
//        if (newStore && !error) {
//            success = YES;
//        } else {
//            if (error) {
//                ELog(error, @"Failed to migrate seed store from bundle");
//            } else {
//                ALog(@"Failed to migrate seed store from bundle, no error returned");
//            }
//        }
//    }
//    
//    return success;
//}

//----------------------------------------------------------------------------------------------------------
/**
 Add a persistent store to the NSPersistentStoreCoordinator
 
 @param storeURL    the NSURL of the store to add
 @param options     NSDictionary containing the options for the store
 @return BOOL       YES if the add is successful, NO otherwise
 */
- (BOOL)addStore: (NSURL *)storeURL
     withOptions: (NSDictionary *)options
{
    DLog();
    
    BOOL success = NO;
    
    NSError *error = nil;
    
    [__persistentStoreCoordinator lock];
    if ( [__persistentStoreCoordinator addPersistentStoreWithType: NSSQLiteStoreType
                                                    configuration: nil
                                                              URL: storeURL
                                                          options: options
                                                            error: &error])
    {
        success = YES;
        DLog(@"Success!");
    } else {
        ELog(error, @"Could not add PersistentStore");
    }
    [__persistentStoreCoordinator unlock];
    
    return success;
}


//----------------------------------------------------------------------------------------------------------
/**
 Invoked when iCloud has changes to merge (currently, iCloud is disabled)
 
 * Invokes mergeChangesFromContextDidSaveNotification on the NSManagedObjectContext
 * Creates a NSNotification to inform interested parties that updates were merged
 
 @param aNote       the NSNotification object containing information about the changes
 @param moc         the NSManagedObjectContext effected
 */
- (void)merge_iCloudChanges:(NSNotification *)aNote
                 forContext:(NSManagedObjectContext *)moc
{
    DLog();
    
    [moc mergeChangesFromContextDidSaveNotification: aNote];
    DLog(@"completed merging changes from iCloud, posting notification");
    
    // Create a notification for change observers, passing along the userInfo from iCloud
    NSNotification *refreshNotification = [NSNotification notificationWithName: OCRApplicationDidMergeChangesFrom_iCloudNotification
                                                                        object: self
                                                                      userInfo: [aNote userInfo]];
    
    [[NSNotificationCenter defaultCenter] postNotification: refreshNotification];
}


//----------------------------------------------------------------------------------------------------------
/**
 Invoked by NSNotification when iCloud has changes
 
 @param notification    the NSNotification object containing information about the changes
 */
- (void)mergeChangesFrom_iCloud:(NSNotification *)notification
{
    DLog();
    
    // NSNotifications are posted synchronously on the caller's thread
    // make sure to vector this back to the thread we want, in this case
    // the main thread for our views & controller
    NSManagedObjectContext *moc = [self managedObjectContext];
    
    // this only works if you used NSMainQueueConcurrencyType
    // otherwise use a dispatch_async back to the main thread yourself
    // TODO - possible problem?
    [moc performBlock:^{
        [self merge_iCloudChanges: notification
                       forContext: moc];
    }];
}

#pragma mark - Helper methods

/**
 Returns the URL to the application's documents directory
 
 @return NSURL of the application's Documents Directory
 */
- (NSURL *)applicationDocumentsDirectory
{
    DLog();
    
    return [[[NSFileManager defaultManager] URLsForDirectory: NSDocumentDirectory
                                                   inDomains: NSUserDomainMask] lastObject];
}

@end
