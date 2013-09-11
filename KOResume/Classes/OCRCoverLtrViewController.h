//
//  OCRCoverLtrViewController.h
//  KOResume
//
//  Created by Kevin O'Mara on 8/11/13.
//  Copyright (c) 2013 O'Mara Consulting Associates. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Packages.h"

@interface OCRCoverLtrViewController : UIViewController <UITextViewDelegate>
{
    Packages                    *_selectedPackage;
    NSManagedObjectContext      *__managedObjectConext;
    NSFetchedResultsController  *__fetchedResultsController;
}

@property (nonatomic, strong) Packages                      *selectedPackage;
@property (nonatomic, strong) NSManagedObjectContext        *managedObjectContext;
@property (nonatomic, strong) NSFetchedResultsController    *fetchedResultsController;

@property (nonatomic, weak) IBOutlet UIScrollView           *scrollView;
@property (nonatomic, weak) IBOutlet UITextView             *coverLtrFld;


@end
