//
//  OCRDateClearTableViewCell.m
//  KOResume
//
//  Created by Kevin O'Mara on 4/15/14.
//  Copyright (c) 2014 O'Mara Consulting Associates. All rights reserved.
//

#import "OCRDateClearTableViewCell.h"

@implementation OCRDateClearTableViewCell

//----------------------------------------------------------------------------------------------------------
- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        // Initialization code
    }
    return self;
}

//----------------------------------------------------------------------------------------------------------
- (void)awakeFromNib
{
    // Initialization code
}

//----------------------------------------------------------------------------------------------------------
- (void)setSelected:(BOOL)selected
           animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
