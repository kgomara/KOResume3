//
//  OCRPackagesCell.h
//  KOResume2
//
//  Created by Kevin O'Mara on 7/19/13.
//  Copyright (c) 2013 O'Mara Consulting Associates. All rights reserved.
//

// TODO add protocal definition
@protocol OCRPackageCellDelegate <NSObject>

- (void)coverLtrButtonTapped:(id)sender;
- (void)resumeButtonTapped:(id)sender;

@end

#import <UIKit/UIKit.h>

@interface OCRPackagesCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel      *title;
@property (nonatomic, strong) IBOutlet UIButton     *coverLtrButton;
@property (nonatomic, strong) IBOutlet UIButton     *resumeButton;

@property (nonatomic, strong) UIViewController<OCRPackageCellDelegate>      *delegate;

- (IBAction)coverLtrBtnTapped:(id)sender;
- (IBAction)resumeBtnTapped:(id)sender;


@end
