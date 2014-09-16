//
//  OCRAccomplishmentTableViewCell.h
//  KOResume
//
//  Created by Kevin O'Mara on 6/14/14.
//  Copyright (c) 2014 O'Mara Consulting Associates. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kNameFieldTag       100
#define kSummaryFieldTag    101

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
