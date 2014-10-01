//
//  OCRAccomplishmentTableViewCell.h
//  KOResume
//
//  Created by Kevin O'Mara on 6/14/14.
//  Copyright (c) 2014 O'Mara Consulting Associates. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kAccomplishmentNameFieldTag       100
#define kAccomplishmentSummaryFieldTag    101

/**
 Manage UITableViewCell objects representing accomplishments.
 */
@interface OCRAccomplishmentTableViewCell : UITableViewCell  <UITextFieldDelegate>

/**
 Constant to specifiy the height of the table cell.
 */
extern CGFloat const kOCRAccomplishmentTableViewCellDefaultHeight;

/**
 IBOutlet to the accomplishment name text field.
 */
@property (weak, nonatomic) IBOutlet UITextField *accomplishmentName;

/**
 IBOutlet to the accomplishment name text view.
 */
@property (weak, nonatomic) IBOutlet UITextView *accomplishmentSummary;

@end
