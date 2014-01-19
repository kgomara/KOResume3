//
//  OCRCoreDataController.h
//  KOResume
//
//  Created by Kevin O'Mara on 3/9/11.
//  Copyright 2011-2014 O'Mara Consulting Associates. All rights reserved.
//

#import <CoreData/CoreData.h>

/**
 Singleton object to manage the data store for KOResume
 */
@interface OCRCoreDataController : NSObject 

/**
 Returns the managed object context for the application.
 
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the app.
 See: [Using Core Data with iCloud](http://goddess-gate.com/dc2/index.php/post/452) and
 [Ray Wenderlich's Core Data Tutorial](http://www.raywenderlich.com/12170/core-data-tutorial-how-to-preloadimport-existing-data-updated)
 for excellent tutorials on this setting up core data/iCloud
 */
@property (nonatomic, strong, readonly) NSManagedObjectContext          *managedObjectContext;

@end
