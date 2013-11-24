//
//  OCRAppDelegate.h
//  KOResume
//
//  Created by Kevin O'Mara on 7/14/13.
//  Copyright (c) 2013 O'Mara Consulting Associates. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OCRCoreDataController.h"
#import "OCRDetailViewManager.h"


@interface OCRAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow                          *window;
@property (strong, nonatomic) OCRDetailViewManager              *detailViewManager;

@property (nonatomic, strong, readonly) NSManagedObjectContext  *managedObjectContext;
@property (nonatomic, strong, readonly) OCRCoreDataController   *coreDataController;


- (void)saveContext:(NSManagedObjectContext *)moc;

@end
