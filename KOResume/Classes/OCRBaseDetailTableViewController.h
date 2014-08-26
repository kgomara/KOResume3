//
//  OCRBaseDetailTableViewController.h
//  KOResume
//
//  Created by Kevin O'Mara on 8/7/14.
//  Copyright (c) 2014 O'Mara Consulting Associates. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OCRDetailViewProtocol.h"
#import "Packages.h"
#import "OCRPackagesTableViewController.h"

/**
 This class defines common properties and methods for detail tableView controllers.
 */
@interface OCRBaseDetailTableViewController : UITableViewController     <OCRDetailViewProtocol, SubstitutableDetailViewController,
                                                                         UITableViewDataSource, UITableViewDelegate>

/**
 IBOutlet to the titleLabel.
 */
@property (nonatomic, strong) IBOutlet UILabel              *titleLabel;


@end
