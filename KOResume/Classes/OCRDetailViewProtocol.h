//
//  OCRDetailViewProtocol.h
//  KOResume
//
//  Created by Kevin O'Mara on 8/7/14.
//  Copyright (c) 2014 O'Mara Consulting Associates. All rights reserved.
//

#ifndef KOResume_OCRDetailViewProtocol_h
#define KOResume_OCRDetailViewProtocol_h

/**
 OCRDetailViewProtocol is a protocol that detail view controllers must adopt. It defines methods that
 the base class can invoke on subclasses.
 */
@protocol OCRDetailViewProtocol <NSObject>

/**
 The managed object the user selected.
 
 Subclasses should either cast or create a type appropriate reference to this object.
 */
@property (nonatomic, strong) NSManagedObject               *selectedManagedObject;

/**
 The fetchedResultsController used to retrieve the selectedPackage.
 */
@property (nonatomic, strong) NSFetchedResultsController    *fetchedResultsController;

/**
 A property used by the master view to cache the back button.
 */
@property (nonatomic, strong) UIBarButtonItem               *backButtonCached;

/**
 A property used by the master view to cache the popover controller.
 */
@property (nonatomic, strong) UIPopoverController           *popoverControllerCached;

/**
 A reference to the master view's popoverController.
 */
@property (nonatomic, strong) UIPopoverController           *masterPopoverController;

/**
 A property used by the master view to set the back button title.
 */

@property (nonatomic, strong) NSString                      *backButtonTitle;

@required

/**
 The method is called on the subclass when the selectedManagedObject changes.
 
 The subclass should update it's view to reflect the new data and perform other operations
 appropriate for its context.
 */
- (void)configureView;

/**
 Reloads the fetched Results
 
 @param     note    The NSNotification object, or nil.
 */

- (void)reloadFetchedResults: (NSNotification*)aNote;

@end


#endif
