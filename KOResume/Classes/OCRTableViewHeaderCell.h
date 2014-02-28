//
//  OCRTableViewHeaderCell.h
//  KOResume
//
//  Created by Kevin O'Mara on 2/27/14.
//  Copyright (c) 2014 O'Mara Consulting Associates. All rights reserved.
//

#import <UIKit/UIKit.h>

FOUNDATION_EXPORT   NSString    *const  kOCRHeaderCell;
extern              CGFloat     const   kOCRHeaderCellHeight;

@interface OCRTableViewHeaderCell : UITableViewCell

/**
 IBOutlet to the sectionLabel in the group header
 */
@property (weak, nonatomic) IBOutlet UILabel    *sectionLabel;

/**
 IBOutlet to the addButton in the group header
 */
@property (weak, nonatomic) IBOutlet UIButton   *addButton;

@end
