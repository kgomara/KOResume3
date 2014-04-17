//
//  OCRDateTableViewController.h
//  KOResume
//
//  Created by Kevin O'Mara on 4/15/14.
//  Copyright (c) 2014 O'Mara Consulting Associates. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Jobs.h"

@interface OCRDateTableViewController : UITableViewController

@property (strong, nonatomic) Jobs              *selectedJob;

@property (strong, nonatomic) UIViewController  *delegate;

- (IBAction)dateChanged:(UIDatePicker *)sender;

@end
