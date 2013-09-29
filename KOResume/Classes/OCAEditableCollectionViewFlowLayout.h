//
//  OCAEditableCollectionViewFlowLayout.h
//  KOResume
//
//  Created by Kevin O'Mara on 8/28/13.
//  Copyright (c) 2013 O'Mara Consulting Associates. All rights reserved.
//
//  Portions created by:
//  Created by Stan Chang Khin Boon on 1/10/12.
//  https://github.com/lxcid/LXReorderableCollectionViewFlowLayout
//  Copyright (c) 2012 d--buzz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OCAEditableCollectionViewFlowLayout : UICollectionViewFlowLayout <UIGestureRecognizerDelegate>

@property (assign, nonatomic)           CGFloat                         scrollingSpeed;
@property (assign, nonatomic)           UIEdgeInsets                    scrollingTriggerEdgeInsets;
@property (strong, nonatomic, readonly) UILongPressGestureRecognizer    *longPressGestureRecognizer;
@property (strong, nonatomic, readonly) UIPanGestureRecognizer          *panGestureRecognizer;
@property (strong, nonatomic, readonly) UITapGestureRecognizer          *tapGestureRecognizer;

@end

@protocol OCAEditableCollectionViewDataSource <UICollectionViewDataSource>

@optional

- (BOOL)collectionView: (UICollectionView *)collectionView
canMoveItemAtIndexPath: (NSIndexPath *)indexPath;

- (void)collectionView: (UICollectionView *)collectionView
       itemAtIndexPath: (NSIndexPath *)fromIndexPath
   willMoveToIndexPath: (NSIndexPath *)toIndexPath;

- (void)collectionView: (UICollectionView *)collectionView
       itemAtIndexPath: (NSIndexPath *)fromIndexPath
    didMoveToIndexPath: (NSIndexPath *)toIndexPath;

- (BOOL)collectionView: (UICollectionView *)collectionView
       itemAtIndexPath: (NSIndexPath *)fromIndexPath
    canMoveToIndexPath: (NSIndexPath *)toIndexPath;

// TODO add can, will, didDelete

@end

@protocol OCAEditableCollectionViewDelegateFlowLayout <UICollectionViewDelegateFlowLayout>

@required

- (void)didBeginEditingForCollectionView: (UICollectionView *)collectionView
                                  layout: (UICollectionViewLayout *)collectionViewLayout;

- (void)didEndEditingForCollectionView: (UICollectionView *)collectionView
                                layout: (UICollectionViewLayout *)collectionViewLayout;

- (void)            collectionView: (UICollectionView *)collectionView
                            layout: (UICollectionViewLayout *)collectionViewLayout
   didBeginDraggingItemAtIndexPath: (NSIndexPath *)indexPath;

- (void)            collectionView: (UICollectionView *)collectionView
                            layout: (UICollectionViewLayout *)collectionViewLayout
     didEndDraggingItemAtIndexPath: (NSIndexPath *)indexPath;

@optional

- (void)            collectionView: (UICollectionView *)collectionView
                            layout: (UICollectionViewLayout *)collectionViewLayout
  willBeginDraggingItemAtIndexPath: (NSIndexPath *)indexPath;

- (void)            collectionView: (UICollectionView *)collectionView
                            layout: (UICollectionViewLayout *)collectionViewLayout
    willEndDraggingItemAtIndexPath: (NSIndexPath *)indexPath;

- (BOOL)shouldEnableEditingForCollectionView: (UICollectionView *)collectionView
                                      layout: (UICollectionViewLayout *)collectionViewLayout;


@end
