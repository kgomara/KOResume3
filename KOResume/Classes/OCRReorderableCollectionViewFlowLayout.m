//
//  OCRReorderableCollectionViewFlowLayout.m
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
//  And:
//  MobileTuts+, Akiel Khan
//  http://mobile.tutsplus.com/tutorials/iphone/uicollectionview-layouts/
//

#import "OCRReorderableCollectionViewFlowLayout.h"
#import "OCRReorderableLayoutAttributes.h"

#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

#define OCR_FRAMES_PER_SECOND 60.0

#ifndef CGGEOMETRY_OCRSUPPORT_H_
CG_INLINE CGPoint
OCRS_CGPointAdd(CGPoint point1, CGPoint point2) {
    return CGPointMake(point1.x + point2.x, point1.y + point2.y);
}
#endif

typedef NS_ENUM(NSInteger, OCRScrollingDirection) {
    OCRScrollingDirectionUnknown = 0,
    OCRScrollingDirectionUp,
    OCRScrollingDirectionDown,
    OCRScrollingDirectionLeft,
    OCRScrollingDirectionRight
};

/*
 These string constants are declared locally for two reasons:
    1. They are not referenced outside of this scope.
    2. I hope to make this class reusable beyond KOResume, so it needs to be self-contained.
 */
static NSString * const kOCRScrollingDirectionKey   = @"OCRScrollingDirection";
static NSString * const kOCRCollectionViewKeyPath   = @"collectionView";

/*
 Category to allow adding variables
 */
@interface CADisplayLink (OCR_userInfo)

@property (nonatomic, copy) NSDictionary *OCR_userInfo;

@end

@implementation CADisplayLink (OCR_userInfo)

//----------------------------------------------------------------------------------------------------------
- (void) setOCR_userInfo:(NSDictionary *) OCR_userInfo
{
    /*
     objc_setAssociatedObject adds a key value store to each Objective-C object. It lets you store additional state 
     for the object, not reflected in its instance variables.
     
     It's really convenient when you want to store things belonging to an object outside of the main implementation. 
     One of the main use cases is in categories where you cannot add instance variables. Here you use 
     objc_setAssociatedObject to attach your additional variables to the self object.
     
     When using the right association policy your objects will be released when the main object is deallocated.
     */
    objc_setAssociatedObject(self, "OCR_userInfo", OCR_userInfo, OBJC_ASSOCIATION_COPY);
}

//----------------------------------------------------------------------------------------------------------
- (NSDictionary *) OCR_userInfo
{
    return objc_getAssociatedObject(self, "OCR_userInfo");
}

@end

/*
 Category to add capabilities to our UICollectionViewCell objects
 
 A UICollectionViewCell may be composed of an arbitrarily large number of subviews. Dragging the real cell
 would cause the system to re-draw, probably with animation, every subview on each move increment.
 Rasterizing "flattens" the cell into one image.
 */
@interface UICollectionViewCell (OCRPackagesCollectionViewFlowLayout)

- (UIImage *)OCR_rasterizedImage;

@end

@implementation UICollectionViewCell (OCRPackagesCollectionViewFlowLayout)

//----------------------------------------------------------------------------------------------------------
/**
 A UICollectionViewCell may be composed of an arbitrarily large number of subviews. Dragging the real cell
 would cause the system to re-draw, probably with animation, every subview on each move increment.
 Rasterizing "flattens" the cell into one image.
 */
- (UIImage *)OCR_rasterizedImage
{
    DLog();
    
    /*
     This is a common pattern when making an image of some portion of what's on the screen - it this case,
     the view's layer, which contains all the visible elements of the cell.
     */
    // Create a bit-map context of the cell
    UIGraphicsBeginImageContextWithOptions( self.bounds.size, self.isOpaque, 0.0f);
    // ...render the cell
    [self.layer renderInContext: UIGraphicsGetCurrentContext()];
    // ...get the image just rendered
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    // ...and end the image context.
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)addDeleteButton
{
    DLog();
    
    
}

@end

@interface OCRReorderableCollectionViewFlowLayout ()

@property (strong, nonatomic) NSIndexPath   *selectedItemIndexPath;
@property (strong, nonatomic) UIView        *currentView;
@property (assign, nonatomic) CGPoint       currentViewCenter;
@property (assign, nonatomic) CGPoint       panTranslationInCollectionView;
@property (assign, nonatomic) BOOL          isEditModeOn;
/**
 CADisplayLink is a timer object that allows us to synchronize drawing to the refresh rate of the display.
 see - https://developer.apple.com/library/ios/documentation/QuartzCore/Reference/CADisplayLink_ClassRef/Reference/Reference.html#//apple_ref/occ/instp/CADisplayLink/paused
 */
@property (strong, nonatomic) CADisplayLink *displayLink;

@property (assign, nonatomic, readonly) id<OCRReorderableCollectionViewDataSource>          dataSource;
@property (assign, nonatomic, readonly) id<OCRReorderableCollectionViewDelegateFlowLayout>  delegate;

@end

@implementation OCRReorderableCollectionViewFlowLayout

//----------------------------------------------------------------------------------------------------------
- (void)setDefaults
{
    DLog();
    
    _scrollingSpeed             = 300.0f;
    _scrollingTriggerEdgeInsets = UIEdgeInsetsMake(50.0f, 50.0f, 50.0f, 50.0f);
    _isEditModeOn               = NO;
}


//----------------------------------------------------------------------------------------------------------
- (void)setupCollectionView
{
    DLog();
    
    // Create a custom long press gesture recognizer to handle moves and deletes
    _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget: self
                                                                                action: @selector(handleLongPressGesture:)];
    _longPressGestureRecognizer.delegate = self;
    
    // Iterate through all the gestureRecognizers in the collectionView
    for (UIGestureRecognizer *gestureRecognizer in self.collectionView.gestureRecognizers) {
        if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
            /*
             This call delay's the default longPressGestureRecognizer transition until our long press gesture recognizer
             enters the UIGestureRecognizerStateFailed state (meaning we are not handling the long press). If we enter
             UIGestureRecognizerStateRecognized or UIGestureRecognizerStateBegan states, it will fail - meaning it won't
             interfere with what we're doing.
             */
            [gestureRecognizer requireGestureRecognizerToFail: _longPressGestureRecognizer];
        }
    }
    
    // ...add our long press recognizer to the collection view
    [self.collectionView addGestureRecognizer:_longPressGestureRecognizer];
    
    // Create a pan gesture recognizer to handle swipes
    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget: self
                                                                    action: @selector(handlePanGesture:)];
    _panGestureRecognizer.delegate = self;
    [self.collectionView addGestureRecognizer: _panGestureRecognizer];
    
    // Create a tap gesture recognizer to detect user taps away from cells, signifying they are finished
    // reordering or deleting
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget: self
                                                                    action: @selector(handleTapGesture:)];
    _tapGestureRecognizer.delegate = self;
    [self.collectionView addGestureRecognizer: _tapGestureRecognizer];
    
    // Useful in multiple scenarios: one common scenario being when the Notification Center drawer is pulled down
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleApplicationWillResignActive:)
                                                 name: UIApplicationWillResignActiveNotification
                                               object: nil];
}


//----------------------------------------------------------------------------------------------------------
- (void)initialize
{
    DLog();
    [self setDefaults];
    
    // Register to be notified of any changes to self.collectionView (see Key-Value Observing methods)
    [self addObserver: self
           forKeyPath: kOCRCollectionViewKeyPath
              options: NSKeyValueObservingOptionNew
              context: nil];
}


//----------------------------------------------------------------------------------------------------------
- (id)init
{
    DLog();
    
    if (self = [super init]) {
        [self initialize];
    }
    
    return self;
}


//----------------------------------------------------------------------------------------------------------
- (id)initWithCoder: (NSCoder *)aDecoder
{
    DLog();
    
    if (self = [super initWithCoder:aDecoder]) {
        [self initialize];
    }
    
    return self;
}


//----------------------------------------------------------------------------------------------------------
- (void)dealloc
{
    DLog();
    
    // stop any timers
    [self invalidatesScrollTimer];
    
    // ...and remove ourself as observer as needed
    [self removeObserver: self
              forKeyPath: kOCRCollectionViewKeyPath];
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: UIApplicationWillResignActiveNotification
                                                  object: nil];
}


//----------------------------------------------------------------------------------------------------------
- (void)applyLayoutAttributes: (OCRReorderableLayoutAttributes *)layoutAttributes
{
    DLog(@"layoutAttributes.indexPath=%@", layoutAttributes.indexPath.stringForCollection);
    
    if ([layoutAttributes.indexPath isEqual: self.selectedItemIndexPath]) {
//        layoutAttributes.hidden = YES;
    }
    DLog(@"isDeleteButtonHidden=%@", layoutAttributes.isDeleteButtonHidden ? @"YES" : @"NO");
    
    // TODO - it seems like the cell implementation of applyLayoutAttributes isn't called (sometimes)
        
//    if (layoutAttributes.isDeleteButtonHidden) {
//        self.deleteButton.layer.opacity = 0.0;
//        [self stopQuivering];
//    } else {
//        self.deleteButton.layer.opacity = 1.0;
//        [self startQuivering];
//    }
    
 }


//----------------------------------------------------------------------------------------------------------
- (id<OCRReorderableCollectionViewDataSource>)dataSource
{
    DLog();
    
    return (id<OCRReorderableCollectionViewDataSource>)self.collectionView.dataSource;
}


//----------------------------------------------------------------------------------------------------------
- (id<OCRReorderableCollectionViewDelegateFlowLayout>)delegate
{
    DLog();
    
    return (id<OCRReorderableCollectionViewDelegateFlowLayout>)self.collectionView.delegate;
}


/*
 This method is called when the pan gesture recognizer wants to move an item in the collection view.
 */
//----------------------------------------------------------------------------------------------------------
- (void)invalidateLayoutIfNecessary
{
    DLog();
    
    NSIndexPath *newIndexPath       = [self.collectionView indexPathForItemAtPoint: self.currentView.center];
    NSIndexPath *previousIndexPath  = self.selectedItemIndexPath;
    
    // First, check to see if a move is really necessary
    if ((newIndexPath == nil) ||
        [newIndexPath isEqual:previousIndexPath]) {
        // Just return is there is no newIndexPath or no movement
        return;
    }
    
    // ...if the dataSource implements the canMoveToIndexPath delegate method,
    if ( [self.dataSource respondsToSelector: @selector(collectionView:itemAtIndexPath:canMoveToIndexPath:)] &&
        // ...call it
        ![self.dataSource collectionView: self.collectionView
                         itemAtIndexPath: previousIndexPath
                      canMoveToIndexPath: newIndexPath])
    {
        // ...and return if the delegate denies the move request
        return;
    }
    
    self.selectedItemIndexPath = newIndexPath;
    
    // ...if the datasource implements the willMoveToIndexPath delegate method,
    if ([self.dataSource respondsToSelector: @selector(collectionView:itemAtIndexPath:willMoveToIndexPath:)]) {
        // ...call it
        [self.dataSource collectionView: self.collectionView
                        itemAtIndexPath: previousIndexPath
                    willMoveToIndexPath: newIndexPath];
    }
    
    // ...and finally, do the move by deleting the item from where it was and inserting it where it is now
    // TODO document use of __weak and __strong
    __weak typeof(self) weakSelf = self;
    [self.collectionView performBatchUpdates: ^{
        __strong typeof(self) strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf.collectionView deleteItemsAtIndexPaths: @[ previousIndexPath ]];
            [strongSelf.collectionView insertItemsAtIndexPaths: @[ newIndexPath ]];
        }
    } completion: ^(BOOL finished) {
        // ...on completion, if the datasource implements the didMoveToIndexPath method,
        __strong typeof(self) strongSelf = weakSelf;
        if ([strongSelf.dataSource respondsToSelector: @selector(collectionView:itemAtIndexPath:didMoveToIndexPath:)]) {
            // ...call it
            [strongSelf.dataSource collectionView: strongSelf.collectionView
                                  itemAtIndexPath: previousIndexPath
                               didMoveToIndexPath:newIndexPath];
        }
    }];
}


//----------------------------------------------------------------------------------------------------------
- (void)invalidatesScrollTimer
{
    DLog();
    
    // Check to see if the display link is currently running
    if ( !self.displayLink.paused) {
        // ...the timer in not paused - invalidate it, which removes it from the run loop
        [self.displayLink invalidate];
    }
    self.displayLink = nil;
}


//----------------------------------------------------------------------------------------------------------
- (void)setupScrollTimerInDirection: (OCRScrollingDirection)direction
{
    DLog();
    
    // Check to see if the display link is currently running
    if (!self.displayLink.paused) {
        // it is running - check to see if we're going in the same direction as last time
        OCRScrollingDirection oldDirection = [self.displayLink.OCR_userInfo[kOCRScrollingDirectionKey] integerValue];
        if (direction == oldDirection) {
            // ...and just return if we are
            return;
        }
    }
    
    // Invalidate the timer
    [self invalidatesScrollTimer];
    
    // Instantiate a new CADisplayLink timer
    self.displayLink = [CADisplayLink displayLinkWithTarget: self
                                                   selector: @selector(handleScroll:)];
    // ...add the direction as our userInfo (see Category definition above)
    self.displayLink.OCR_userInfo = @{ kOCRScrollingDirectionKey : @(direction) };
    
    // ...and add it to the mainRunLoop so we start getting notifications
    [self.displayLink addToRunLoop: [NSRunLoop mainRunLoop]
                           forMode: NSRunLoopCommonModes];
}

#pragma mark - OCRReorderableLayoutAttributes helper methods

//----------------------------------------------------------------------------------------------------------
+ (Class)layoutAttributesClass
{
    return [OCRReorderableLayoutAttributes class];
}

#pragma mark - Target/Action methods

//----------------------------------------------------------------------------------------------------------
/**
 Handle scrolling in either horizontal or vertical direction. Called from the run loop
 via CADisplayLink mechanism (see other comments)
 @param displayLink - the displayLink that is invoking us (see setupScrollTimerInDirection:)
 */
- (void)handleScroll: (CADisplayLink *)displayLink
{
//    DLog();
    
    OCRScrollingDirection direction = (OCRScrollingDirection)[displayLink.OCR_userInfo[kOCRScrollingDirectionKey] integerValue];
    if (direction == OCRScrollingDirectionUnknown) {
        return;
    }
    
    CGSize frameSize        = self.collectionView.bounds.size;
    CGSize contentSize      = self.collectionView.contentSize;
    CGPoint contentOffset   = self.collectionView.contentOffset;
    CGFloat distance        = self.scrollingSpeed / OCR_FRAMES_PER_SECOND;
    CGPoint translation     = CGPointZero;
    
    /*
     In the switch statement, we determine a translation point, allowing for top, bottom, right, left as appropriate
     */
    switch(direction) {
        case OCRScrollingDirectionUp: {
            distance = -distance;
            CGFloat minY = 0.0f;
            
            if ((contentOffset.y + distance) <= minY) {
                distance = -contentOffset.y;
            }
            
            translation = CGPointMake(0.0f, distance);
            break;
        }
            
        case OCRScrollingDirectionDown: {
            CGFloat maxY = MAX(contentSize.height, frameSize.height) - frameSize.height;
            
            if ((contentOffset.y + distance) >= maxY) {
                distance = maxY - contentOffset.y;
            }
            
            translation = CGPointMake(0.0f, distance);
            break;
        }
            
        case OCRScrollingDirectionLeft: {
            distance = -distance;
            CGFloat minX = 0.0f;
            
            if ((contentOffset.x + distance) <= minX) {
                distance = -contentOffset.x;
            }
            
            translation = CGPointMake(distance, 0.0f);
            break;
        }
            
        case OCRScrollingDirectionRight: {
            CGFloat maxX = MAX(contentSize.width, frameSize.width) - frameSize.width;
            
            if ((contentOffset.x + distance) >= maxX) {
                distance = maxX - contentOffset.x;
            }
            
            translation = CGPointMake(distance, 0.0f);
            break;
        }
            
        default:
            break;
    }
    
    // translation now has a deltaX or deltaY for the scroll
    self.currentViewCenter              = OCRS_CGPointAdd(self.currentViewCenter, translation);
    self.currentView.center             = OCRS_CGPointAdd(self.currentViewCenter, self.panTranslationInCollectionView);
    self.collectionView.contentOffset   = OCRS_CGPointAdd(contentOffset, translation);
}


//----------------------------------------------------------------------------------------------------------
- (void)handleLongPressGesture: (UILongPressGestureRecognizer *)gestureRecognizer
{
    DLog();
    
    switch(gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            if (_isEditModeOn) {
                DLog(@"StateBegan with isEditModeOn");
            } else {
                DLog(@"setting editMode On");
                _isEditModeOn = YES;
                if ([self.delegate respondsToSelector: @selector(didBeginEditingForCollectionView:layout:)]) {
                    [self.delegate didBeginEditingForCollectionView: self.collectionView
                                                             layout: self];
                }
                [self invalidateLayout];
            }
//            break;
//        }
//            
//        case UIGestureRecognizerStateChanged: {
//            DLog(@"StateChanged");
            NSIndexPath *currentIndexPath = [self.collectionView indexPathForItemAtPoint: [gestureRecognizer locationInView: self.collectionView]];
            
            if ( [self.dataSource respondsToSelector: @selector(collectionView:canMoveItemAtIndexPath:)] &&
                ![self.dataSource collectionView: self.collectionView
                          canMoveItemAtIndexPath: currentIndexPath])
            {
                return;
            }
            
            self.selectedItemIndexPath = currentIndexPath;
            
            if ([self.delegate respondsToSelector: @selector(collectionView:layout:willBeginDraggingItemAtIndexPath:)]) {
                [self.delegate collectionView: self.collectionView
                                       layout: self
             willBeginDraggingItemAtIndexPath: self.selectedItemIndexPath];
            }
            
            UICollectionViewCell *collectionViewCell = [self.collectionView cellForItemAtIndexPath: self.selectedItemIndexPath];
            
            self.currentView = [[UIView alloc] initWithFrame: collectionViewCell.frame];
            
            collectionViewCell.highlighted          = YES;
            UIImageView *highlightedImageView       = [[UIImageView alloc] initWithImage: [collectionViewCell OCR_rasterizedImage]];
            highlightedImageView.autoresizingMask   = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            highlightedImageView.alpha              = 1.0f;
            
            collectionViewCell.highlighted  = NO;
            UIImageView *imageView          = [[UIImageView alloc] initWithImage: [collectionViewCell OCR_rasterizedImage]];
            imageView.autoresizingMask      = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            imageView.alpha                 = 0.0f;
            
            [self.currentView addSubview: imageView];
            [self.currentView addSubview: highlightedImageView];
            [self.collectionView addSubview: self.currentView];
            
            self.currentViewCenter = self.currentView.center;
            
            __weak typeof(self) weakSelf = self;
            [UIView animateWithDuration: 0.3
                                  delay: 0.0
                                options: UIViewAnimationOptionBeginFromCurrentState
                             animations: ^{
                 __strong typeof(self) strongSelf = weakSelf;
                 if (strongSelf) {
                     strongSelf.currentView.transform   = CGAffineTransformMakeScale(1.1f, 1.1f);
                     highlightedImageView.alpha         = 0.0f;
                     imageView.alpha                    = 1.0f;
                 }
             }
             completion: ^(BOOL finished) {
                 __strong typeof(self) strongSelf = weakSelf;
                 if (strongSelf) {
                     [highlightedImageView removeFromSuperview];
                     
                     if ([strongSelf.delegate respondsToSelector: @selector(collectionView:layout:didBeginDraggingItemAtIndexPath:)]) {
                         [strongSelf.delegate collectionView: strongSelf.collectionView
                                                      layout: strongSelf
                             didBeginDraggingItemAtIndexPath: strongSelf.selectedItemIndexPath];
                     }
                 }
             }];
            
            [self invalidateLayout];
            break;
        }
            
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded: {
            DLog(@"StateEnded or Cancelled");
            NSIndexPath *currentIndexPath = self.selectedItemIndexPath;
            
            if (currentIndexPath) {
                if ([self.delegate respondsToSelector: @selector(collectionView:layout:willEndDraggingItemAtIndexPath:)]) {
                    [self.delegate collectionView: self.collectionView
                                           layout: self
                   willEndDraggingItemAtIndexPath: currentIndexPath];
                }
                
                self.selectedItemIndexPath  = nil;
                self.currentViewCenter      = CGPointZero;
                
                UICollectionViewLayoutAttributes *layoutAttributes = [self layoutAttributesForItemAtIndexPath: currentIndexPath];
                
                __weak typeof(self) weakSelf = self;
                [UIView animateWithDuration: 0.3
                                      delay: 0.0
                                    options: UIViewAnimationOptionBeginFromCurrentState
                                 animations: ^{
                     __strong typeof(self) strongSelf = weakSelf;
                     if (strongSelf) {
                         strongSelf.currentView.transform   = CGAffineTransformMakeScale(1.0f, 1.0f);
                         strongSelf.currentView.center      = layoutAttributes.center;
                     }
                 }
                 completion: ^(BOOL finished) {
                     __strong typeof(self) strongSelf = weakSelf;
                     if (strongSelf) {
                         [strongSelf.currentView removeFromSuperview];
                         strongSelf.currentView = nil;
                         [strongSelf invalidateLayout];
                         
                         if ([strongSelf.delegate respondsToSelector: @selector(collectionView:layout:didEndDraggingItemAtIndexPath:)]) {
                             [strongSelf.delegate collectionView: strongSelf.collectionView
                                                          layout: strongSelf
                                   didEndDraggingItemAtIndexPath: currentIndexPath];
                         }
                     }
                 }];
            }
            break;
        }
            
        default:
            break;
    }
}


//----------------------------------------------------------------------------------------------------------
- (void)handlePanGesture: (UIPanGestureRecognizer *)gestureRecognizer
{
    DLog();
    
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged: {
            self.panTranslationInCollectionView = [gestureRecognizer translationInView: self.collectionView];
            CGPoint viewCenter = self.currentView.center = OCRS_CGPointAdd(self.currentViewCenter, self.panTranslationInCollectionView);
            
            [self invalidateLayoutIfNecessary];
            
            switch (self.scrollDirection) {
                case UICollectionViewScrollDirectionVertical: {
                    if (viewCenter.y < (CGRectGetMinY(self.collectionView.bounds) + self.scrollingTriggerEdgeInsets.top)) {
                        [self setupScrollTimerInDirection: OCRScrollingDirectionUp];
                    } else {
                        if (viewCenter.y > (CGRectGetMaxY(self.collectionView.bounds) - self.scrollingTriggerEdgeInsets.bottom)) {
                            [self setupScrollTimerInDirection: OCRScrollingDirectionDown];
                        } else {
                            [self invalidatesScrollTimer];
                        }
                    }
                }
                    break;
                    
                case UICollectionViewScrollDirectionHorizontal: {
                    if (viewCenter.x < (CGRectGetMinX(self.collectionView.bounds) + self.scrollingTriggerEdgeInsets.left)) {
                        [self setupScrollTimerInDirection: OCRScrollingDirectionLeft];
                    } else {
                        if (viewCenter.x > (CGRectGetMaxX(self.collectionView.bounds) - self.scrollingTriggerEdgeInsets.right)) {
                            [self setupScrollTimerInDirection: OCRScrollingDirectionRight];
                        } else {
                            [self invalidatesScrollTimer];
                        }
                    }
                }
                    break;
            }
        }
            break;
            
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded: {
            [self invalidatesScrollTimer];
        }
            break;
            
        default:
            break;
    }
}

//----------------------------------------------------------------------------------------------------------
/**
 Determine whether or not we want to handle the gesture.
 In particular, we want to "fail" on single taps so the tap event is passed on to the cell button handlers.
 
 @param gestureRecognizer the gestureRecognizer in question (could be longPress, pan, or tap
 @return BOOL   NO if we are fail - i.e., we don't want to handle it, YES otherwise
 */
- (BOOL)gestureRecognizer: (UIGestureRecognizer *)gestureRecognizer
       shouldReceiveTouch: (UITouch *)touch
{
    DLog();
    
    CGPoint touchPoint      = [touch locationInView: self.collectionView];
    NSIndexPath *indexPath  = [self.collectionView indexPathForItemAtPoint: touchPoint];
    
    if (indexPath && [gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        return NO;
    }
    
    return YES;
}


//----------------------------------------------------------------------------------------------------------
/**
 Our tap gesture handler is looking for the case where the user has tapped away from any of the cells, 
 signifying end of editing.
 
 @param gestureRecognizer the UITapGestureRecognizer firing the event
 */
- (void)handleTapGesture: (UITapGestureRecognizer *)gestureRecognizer
{
    DLog();
    
    if (_isEditModeOn) {
        NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint: [gestureRecognizer locationInView: self.collectionView]];
        if (!indexPath) {
            self.isEditModeOn = NO;
//            OCRReorderableCollectionViewFlowLayout *layout = (OCRReorderableCollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
//            [layout invalidateLayout];              // TODO - does not seem to be forcing a layout
            [self invalidateLayout];
        }
    }
}

#pragma mark - UICollectionViewLayout overridden methods

//----------------------------------------------------------------------------------------------------------
- (NSArray *)layoutAttributesForElementsInRect: (CGRect)rect
{
    DLog(@"rect=%@", NSStringFromCGRect(rect));
    
    NSArray *layoutAttributesForElementsInRect = [super layoutAttributesForElementsInRect: rect];
    
    for (OCRReorderableLayoutAttributes *layoutAttributes in layoutAttributesForElementsInRect) {
        switch (layoutAttributes.representedElementCategory) {
            case UICollectionElementCategoryCell: {
                if (_isEditModeOn) {
                    layoutAttributes.deleteButtonHidden = NO;
                } else {
                    layoutAttributes.deleteButtonHidden = YES;
                }
                [self applyLayoutAttributes: layoutAttributes];
            }
                break;
            default:
                break;
        }
    }
    
    return layoutAttributesForElementsInRect;
}


//----------------------------------------------------------------------------------------------------------
- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    DLog();
    
    OCRReorderableLayoutAttributes *layoutAttributes = (OCRReorderableLayoutAttributes *)[super layoutAttributesForItemAtIndexPath: indexPath];
    
    switch (layoutAttributes.representedElementCategory) {
        case UICollectionElementCategoryCell: {
            if (_isEditModeOn) {
                layoutAttributes.deleteButtonHidden = NO;
            } else {
                layoutAttributes.deleteButtonHidden = YES;
            }
            [self applyLayoutAttributes: layoutAttributes];
        }
            break;
        default:
            break;
    }
    
    return layoutAttributes;
}


#pragma mark - UIGestureRecognizerDelegate methods

//----------------------------------------------------------------------------------------------------------
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    DLog();
    
    if ([self.panGestureRecognizer isEqual:gestureRecognizer]) {
        return (self.selectedItemIndexPath != nil);
    }
    return YES;
}


//----------------------------------------------------------------------------------------------------------
- (BOOL)                            gestureRecognizer: (UIGestureRecognizer *)gestureRecognizer
   shouldRecognizeSimultaneouslyWithGestureRecognizer: (UIGestureRecognizer *)otherGestureRecognizer
{
    DLog();
    
    if ([self.longPressGestureRecognizer isEqual: gestureRecognizer]) {
        return [self.panGestureRecognizer isEqual: otherGestureRecognizer];
    }
    
    if ([self.panGestureRecognizer isEqual: gestureRecognizer]) {
        return [self.longPressGestureRecognizer isEqual: otherGestureRecognizer];
    }
    
    return NO;
}

#pragma mark - Key-Value Observing methods

//----------------------------------------------------------------------------------------------------------
- (void)observeValueForKeyPath: (NSString *)keyPath
                      ofObject: (id)object
                        change: (NSDictionary *)change
                       context: (void *)context
{
    DLog();
    
    if ([keyPath isEqualToString: kOCRCollectionViewKeyPath]) {
        if (self.collectionView != nil) {
            [self setupCollectionView];
        } else {
            [self invalidatesScrollTimer];
        }
    }
}

#pragma mark - Notifications

//----------------------------------------------------------------------------------------------------------
- (void)handleApplicationWillResignActive:(NSNotification *)notification
{
    DLog();
    
    self.panGestureRecognizer.enabled = NO;
    self.panGestureRecognizer.enabled = YES;
}

@end
