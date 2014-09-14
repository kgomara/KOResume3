//
//  OCRDatePickerViewController.h
//  KOResume
//
//  Created by Kevin O'Mara on 9/10/14.
//  Copyright (c) 2014 O'Mara Consulting Associates. All rights reserved.
//

#import <UIKit/UIKit.h>

FOUNDATION_EXPORT   NSString    *const  kOCRDatePickerIdentifier;
extern              CGFloat     const   kOCRDatePickerHeight;
extern              CGFloat     const   kOCRDatePickerWidth;

@interface OCRDatePickerViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;

@end
