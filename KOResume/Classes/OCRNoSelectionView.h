//
//  OCRNoSelectionView.h
//  KOResume
//
//  Created by Kevin O'Mara on 9/13/14.
//  Copyright (c) 2014 O'Mara Consulting Associates. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OCRNoSelectionView : UIView

/**
 IBOutlet to the view.
 */
@property (strong, nonatomic) IBOutlet UIView   *noSelectionView;

/**
 IBOutlet to the label.
 */
@property (weak, nonatomic)   IBOutlet UILabel  *messageLabel;

+ (instancetype)addNoSelectionViewToView:(UIView *)aView;

@end
