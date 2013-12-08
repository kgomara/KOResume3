//
//  OCRCoreDataController.h
//  KOResume
//
//  Created by Kevin O'Mara on 3/9/11.
//  Copyright 2011-2013 O'Mara Consulting Associates. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface OCRCoreDataController : NSObject 

@property (nonatomic, strong, readonly) NSManagedObjectContext          *managedObjectContext;

@end
