//
//  OCRReorderableLayoutAttributes.m
//  KOResume
//
//  Created by Kevin O'Mara on 8/31/13.
//  Copyright (c) 2013 O'Mara Consulting Associates. All rights reserved.
//

#import "OCRReorderableLayoutAttributes.h"

@implementation OCRReorderableLayoutAttributes

//----------------------------------------------------------------------------------------------------------
- (id)copyWithZone:(NSZone *)zone
{
    OCRReorderableLayoutAttributes *attributes = [super copyWithZone:zone];
    attributes.deleteButtonHidden = _deleteButtonHidden;
    
    return attributes;
}
@end
