//
//  OCRPackagesCell.h
//  KOResume2
//
//  Created by Kevin O'Mara on 7/19/13.
//  Copyright (c) 2013 O'Mara Consulting Associates. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OCAEditableCollectionViewFlowLayout/OCAEditableCollectionViewFlowLayoutCell.h>

extern CGFloat const kPackagesCellHeight;
extern CGFloat const kPackagesCellWidth;

@interface OCRPackagesCell : OCAEditableCollectionViewFlowLayoutCell

@property (nonatomic, weak)     IBOutlet UILabel    *title;
@property (nonatomic, weak)     IBOutlet UIButton   *coverLtrButton;
@property (nonatomic, weak)     IBOutlet UIButton   *resumeButton;

+ (NSString *)titleFont;

+ (NSString *)detailFont;

@end
