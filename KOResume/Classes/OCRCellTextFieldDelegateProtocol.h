//
//  OCRCellTextFieldDelegateProtocol.h
//  KOResume
//
//  Created by Kevin O'Mara on 6/15/14.
//  Copyright (c) 2014 O'Mara Consulting Associates. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OCRCellTextFieldDelegate <NSObject>

- (void)doUpdateTextField:(UITextField *)textField
             forTableCell:(UITableViewCell *)cell;

@end
