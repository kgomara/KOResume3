//
//  OCRReorderableLayoutAttributes.h
//  KOResume
//
//  Created by Kevin O'Mara on 8/31/13.
//  Copyright (c) 2013 O'Mara Consulting Associates. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OCRReorderableLayoutAttributes : UICollectionViewLayoutAttributes

@property (nonatomic, getter = isDeleteButtonHidden) BOOL deleteButtonHidden;

@end
