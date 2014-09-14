//
//  OCRNoSelectionView.m
//  KOResume
//
//  Created by Kevin O'Mara on 9/13/14.
//  Copyright (c) 2014 O'Mara Consulting Associates. All rights reserved.
//

#import "OCRNoSelectionView.h"

@implementation OCRNoSelectionView

//----------------------------------------------------------------------------------------------------------
+ (instancetype)addNoSelectionViewToView:(UIView *)aView
{
    DLog();
    
    OCRNoSelectionView *container = [[OCRNoSelectionView alloc] init];
    [[NSBundle mainBundle] loadNibNamed:@"OCRNoSelectionView"
                                  owner:container
                                options:nil];
    [container setFrame: aView.frame];
    
    [aView addSubview: container];
    
    [container setTranslatesAutoresizingMaskIntoConstraints: NO];
    
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem: container
                                                                  attribute: NSLayoutAttributeLeading
                                                                  relatedBy: NSLayoutRelationEqual
                                                                     toItem: aView
                                                                  attribute: NSLayoutAttributeLeading
                                                                 multiplier: 1.0
                                                                   constant: 0];
    [aView addConstraint: constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem: container
                                              attribute: NSLayoutAttributeTrailing
                                              relatedBy: NSLayoutRelationEqual
                                                 toItem: aView
                                              attribute: NSLayoutAttributeTrailing
                                             multiplier: 1.0
                                               constant: 0];
    [aView addConstraint: constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem: container
                                              attribute: NSLayoutAttributeTop
                                              relatedBy: NSLayoutRelationEqual
                                                 toItem: aView
                                              attribute: NSLayoutAttributeTop
                                             multiplier: 1.0
                                               constant: 0];
    [aView addConstraint: constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem: container
                                              attribute: NSLayoutAttributeBottom
                                              relatedBy: NSLayoutRelationEqual
                                                 toItem: aView
                                              attribute: NSLayoutAttributeBottom
                                             multiplier: 1.0
                                               constant: 0];
    [aView addConstraint: constraint];
    return container;
}


@end
