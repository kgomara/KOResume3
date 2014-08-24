//
//  OCRPackagesCell.h
//  KOResume2
//
//  Created by Kevin O'Mara on 7/19/13.
//  Copyright (c) 2013-2014 O'Mara Consulting Associates. All rights reserved.
//

/**
 This class manages the Package object represented by a collection view cell.
 */

#import <UIKit/UIKit.h>
#import <OCAEditableCollectionViewFlowLayout/OCAEditableCollectionViewFlowLayoutCell.h>

extern CGFloat const kOCRPackagesCellWidth;
extern CGFloat const kOCRPackagesCellHeight;
extern CGFloat const kOCRPackagesCellWidthPadding;

@interface OCRPackagesCell : OCAEditableCollectionViewFlowLayoutCell

/**
 IBOutlet to the title lable.
 */
@property (nonatomic, weak)     IBOutlet UILabel    *title;

/**
 IBOutlet to the button that shows the cover letter in the detail view.
 */
@property (nonatomic, weak)     IBOutlet UIButton   *coverLtrButton;

/**
 IBOutlet to the button that shows the resume in the detail view.
 */
@property (nonatomic, weak)     IBOutlet UIButton   *resumeButton;

/**
 Helper method to get the UIFont of the title field.
 
 Used as part of the support for dynamic font handling.
 */
+ (NSString *)titleFont;

/**
 Helper method to get the UIFont of the detail field.
 
 Used as part of the support for dynamic font handling.
 */
+ (NSString *)detailFont;

@end
