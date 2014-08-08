//
//  OCRBaseDetailViewController.h
//  KOResume
//
//  Created by Kevin O'Mara on 7/14/13.
//  Copyright (c) 2013-2014 O'Mara Consulting Associates. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OCRDetailViewProtocol.h"
#import "Packages.h"
#import "OCRPackagesViewController.h"

/**
 This class defines common properties and methods for detail view controllers.
 */
@interface OCRBaseDetailViewController : UIViewController <OCRDetailViewProtocol, SubstitutableDetailViewController>

/**
 IBOutlet to the titleLabel.
 */
@property (nonatomic, strong) IBOutlet UILabel              *titleLabel;



@end
