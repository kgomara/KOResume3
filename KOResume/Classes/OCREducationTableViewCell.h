//
//  OCREducationTableViewCell.h
//  KOResume
//
//  Created by Kevin O'Mara on 6/14/14.
//  Copyright (c) 2014 O'Mara Consulting Associates. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kTitleFieldTag          100
#define kNameFieldTag           101
#define kCityFieldTag           102
#define kStateFieldTag          103
#define kEarnedDateFieldTag     104

@interface OCREducationTableViewCell : UITableViewCell  <UITextFieldDelegate>

extern CGFloat const                    kOCREducationTableViewCellDefaultHeight;

@property (weak, nonatomic) IBOutlet    UITextField *name;

@property (weak, nonatomic) IBOutlet    UITextField *title;

@property (weak, nonatomic) IBOutlet    UITextField *earnedDate;

@property (weak, nonatomic) IBOutlet    UITextField *city;

@property (weak, nonatomic) IBOutlet    UITextField *state;

@end
