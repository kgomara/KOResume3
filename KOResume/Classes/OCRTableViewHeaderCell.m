//
//  OCRTableViewHeaderCell.m
//  KOResume
//
//  Created by Kevin O'Mara on 2/27/14.
//  Copyright (c) 2014 O'Mara Consulting Associates. All rights reserved.
//

#import "OCRTableViewHeaderCell.h"

@implementation OCRTableViewHeaderCell

NSString    *const  kOCRHeaderCell          = @"OCRHeaderCell";
CGFloat     const   kOCRHeaderCellHeight    = 44.0f;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
