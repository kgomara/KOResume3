//
//  OCRPackagesCell.h
//  KOResume2
//
//  Created by Kevin O'Mara on 7/19/13.
//  Copyright (c) 2013 O'Mara Consulting Associates. All rights reserved.
//

#import <UIKit/UIKit.h>

// TODO - refactor to extract OCACollectionViewCell behavior and inherit from that

@interface OCRPackagesCell : UICollectionViewCell

@property (nonatomic, strong)   IBOutlet UILabel    *title;
@property (nonatomic, strong)   IBOutlet UIButton   *coverLtrButton;
@property (nonatomic, strong)   IBOutlet UIButton   *resumeButton;
@property (nonatomic, strong)   IBOutlet UIButton   *deleteButton;

@end
