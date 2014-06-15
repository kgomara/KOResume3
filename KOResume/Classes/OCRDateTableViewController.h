//
//  OCRDateTableViewController.h
//  KOResume
//
//  Created by Kevin O'Mara on 4/15/14.
//  Copyright (c) 2014 O'Mara Consulting Associates. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Jobs.h"

/**
 @brief  OCRDateTableViewProtocol is a protocol that detail view controllers must adopt. It defines methods that
 the base class can invoke on subclasses.
 */
@protocol OCRDateTableViewProtocol <NSObject>

- (void)dateControllerDidUpdate;

@end

/**
 @brief Manage the start and end dates of a Jobs object.
 
 This class displays an in-line date picker similar to the Calendar or Reminder apps.
 It is based on Vasilica Costescu's [iOS-Blog](http://ios-blog.co.uk/tutorials/ios-7-in-line-uidatepicker-part-1/).
 */
@interface OCRDateTableViewController : UITableViewController

/**
 @brief delegate    The object to be notified when this class updates a date.
 */
@property (nonatomic, strong) UIViewController<OCRDateTableViewProtocol>    *delegate;

/**
 The selected Jobs object.
 */
@property (strong, nonatomic) Jobs              *selectedJob;

/**
 Invoked when the user selects a date in the UIDatePicker.
 
 @param sender  The UIDatePicker sending the message.
 */
- (IBAction)dateChanged:(UIDatePicker *)sender;

@end
