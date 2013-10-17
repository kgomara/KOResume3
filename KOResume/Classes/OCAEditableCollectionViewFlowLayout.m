//
//  OCAEditableCollectionViewFlowLayout.m
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

#import "OCAEditableCollectionViewFlowLayout.h"
#import "OCAEditableLayoutAttributes.h"

#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

#define OCA_FRAMES_PER_SECOND           60.0
#define kOCAHighlightedImageViewTag     9797
#define kOCAUnHighlightedImageViewTag   9798

#ifndef CGGEOMETRY_OCASUPPORT_H_
CG_INLINE CGPoint OCA_CGPointAdd(CGPoint point1, CGPoint point2)
{
    return CGPointMake(point1.x + point2.x, point1.y + point2.y);
}
#endif

typedef NS_ENUM(NSInteger, OCAScrollingDirection) {
    OCAScrollingDirectionUnknown = 0,
    OCAScrollingDirectionUp,
    OCAScrollingDirectionDown,
    OCAScrollingDirectionLeft,
    OCAScrollingDirectionRight
};

/*
 These string constants are declared locally for two reasons:
    1. They are not referenced outside of this scope.
    2. I hope to make this class reusable beyond KOResume, so it needs to be self-contained.
 */
static NSString * const kOCAScrollingDirectionKey   = @"OCAScrollingDirection";
static NSString * const kOCACollectionViewKeyPath   = @"collectionView";

/*
 Category to allow adding variables
 */
@interface CADisplayLink (OCA_userInfo)

@property (nonatomic, copy) NSDictionary *OCA_userInfo;

@end

@implementation CADisplayLink (OCA_userInfo)

//----------------------------------------------------------------------------------------------------------
- (void) setOCA_userInfo:(NSDictionary *) OCA_userInfo
{
    /*
     objc_setAssociatedObject adds a key value store to each Objective-C object. It lets you store additional state 
     for the object, not reflected in its instance variables.
     
     It's really convenient when you want to store things belonging to an object outside of the main implementation. 
     One of the main use cases is in categories where you cannot add instance variables. Here you use 
     objc_setAssociatedObject to attach your additional variables to the self object.
     
     When using the right association policy your objects will be released when the main object is deallocated.
     */
    objc_setAssociatedObject(self, "OCA_userInfo", OCA_userInfo, OBJC_ASSOCIATION_COPY);
}

//----------------------------------------------------------------------------------------------------------
- (NSDictionary *) OCA_userInfo
{
    return objc_getAssociatedObject(self, "OCA_userInfo");
}

@end

/*
 Category to add capabilities to our UICollectionViewCell objects
 
 A UICollectionViewCell may be composed of an arbitrarily large number of subviews. Dragging the real cell
 would cause the system to re-draw (probably with animation) every subview on each move increment.
 Rasterizing "flattens" the cell into one image and thus improves app responsiveness for the user.
 */
@interface UICollectionViewCell (OCAEditableCollectionViewFlowLayout)

- (UIImage *)OCA_rasterizedImage;

@end

@implementation UICollectionViewCell (OCAEditableCollectionViewFlowLayout)

//----------------------------------------------------------------------------------------------------------
/**
 A UICollectionViewCell may be composed of an arbitrarily large number of subviews. Dragging the real cell
 would cause the system to re-draw, probably with animation, every subview on each move increment.
 Rasterizing "flattens" the cell into one image.
 */
- (UIImage *)OCA_rasterizedImage
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

@end

@interface OCAEditableCollectionViewFlowLayout ()

@property (strong, nonatomic) NSIndexPath   *selectedItemIndexPath;
@property (strong, nonatomic) UIView        *currentView;
@property (assign, nonatomic) CGPoint       currentViewCenter;
@property (assign, nonatomic) CGPoint       panTranslationViewCenter;
@property (assign, nonatomic) BOOL          isEditModeOn;
/**
 CADisplayLink is a timer object that allows us to synchronize drawing to the refresh rate of the display.
 
 see - https://developer.apple.com/library/ios/documentation/QuartzCore/Reference/CADisplayLink_ClassRef/Reference/Reference.html#//apple_ref/occ/instp/CADisplayLink/paused
 
 In our case, it is used to ensure a collectionView scrolling operation is called no more than once per screen update.
 Movement of individual cells (in handlePanGesture) could be invoked many times between screen updates. Limiting
 scrolling to the screen update cycle helps keep the app responsive to rapid dragging.
 */
@property (strong, nonatomic) CADisplayLink *displayLink;

@property (assign, nonatomic, readonly) id<OCAEditableCollectionViewDataSource>          dataSource;
@property (assign, nonatomic, readonly) id<OCAEditableCollectionViewDelegateFlowLayout>  delegate;

@end

@implementation OCAEditableCollectionViewFlowLayout

#pragma mark - Lifecycle methods

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
             UIGestureRecognizerStateRecognized or UIGestureRecognizerStateBegan states, this forces the default 
             longPressGestureRecognizer to fail - meaning it won't interfere with what we're doing.
             */
            [gestureRecognizer requireGestureRecognizerToFail: _longPressGestureRecognizer];
        }
    }
    
    // ...add our long press recognizer to the collection view
    [self.collectionView addGestureRecognizer:_longPressGestureRecognizer];
    
    // Create a pan gesture recognizer to handle cell moves
    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget: self
                                                                    action: @selector(handlePanGesture:)];
    _panGestureRecognizer.delegate = self;
    [self.collectionView addGestureRecognizer: _panGestureRecognizer];
    
    // Create a tap gesture recognizer to detect user taps away from cells, signifying they are finished
    // moving or deleting
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget: self
                                                                    action: @selector(handleTapGesture:)];
    _tapGestureRecognizer.delegate = self;
    [self.collectionView addGestureRecognizer: _tapGestureRecognizer];
    
    // Register for notifications that an external event is causing us to resign active state
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
    
    _scrollingSpeed             = 300.0f;
    // Create an inset to trigger scrolling before the user's drag actually gets to the extreme edges of the screen
    _scrollingTriggerEdgeInsets = UIEdgeInsetsMake(50.0f, 50.0f, 50.0f, 50.0f);
    _isEditModeOn               = NO;
    
    // Register to be notified of any changes to self.collectionView.
    // see https://developer.apple.com/library/ios/documentation/cocoa/conceptual/KeyValueObserving/KeyValueObserving.html#//apple_ref/doc/uid/10000177-BCICJDHA
    [self addObserver: self
           forKeyPath: kOCACollectionViewKeyPath
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
              forKeyPath: kOCACollectionViewKeyPath];
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: UIApplicationWillResignActiveNotification
                                                  object: nil];
}


//----------------------------------------------------------------------------------------------------------
- (void)applyLayoutAttributes: (OCAEditableLayoutAttributes *)layoutAttributes
{
    DLog();
    
    if (_isEditModeOn) {
        layoutAttributes.deleteButtonHidden = NO;
    } else {
        layoutAttributes.deleteButtonHidden = YES;
    }
    
    // TODO - need to get the cells to re-draw. It seems like the cell implementation of applyLayoutAttributes isn't called (sometimes)
//    if (layoutAttributes.isDeleteButtonHidden) {
//        self.deleteButton.layer.opacity = 0.0;
//        [self stopQuivering];
//    } else {
//        self.deleteButton.layer.opacity = 1.0;
//        [self startQuivering];
//    }
 }

#pragma mark - Convenience methods to get delegate references

//----------------------------------------------------------------------------------------------------------
- (id<OCAEditableCollectionViewDataSource>)dataSource
{
    DLog();
    
    return (id<OCAEditableCollectionViewDataSource>)self.collectionView.dataSource;
}


//----------------------------------------------------------------------------------------------------------
- (id<OCAEditableCollectionViewDelegateFlowLayout>)delegate
{
    DLog();
    
    return (id<OCAEditableCollectionViewDelegateFlowLayout>)self.collectionView.delegate;
}

#pragma mark - Support for Springboard-like movement

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
        [newIndexPath isEqual: previousIndexPath]) {
        // Just return as there is no newIndexPath or no movement
        return;
    }
    
    // ...if the dataSource implements the canMoveToIndexPath delegate method,
    if ( [self.dataSource respondsToSelector: @selector(collectionView:itemAtIndexPath:canMoveToIndexPath:)]) {
        // ...call it
        if (![self.dataSource collectionView: self.collectionView
                             itemAtIndexPath: previousIndexPath
                          canMoveToIndexPath: newIndexPath])
        {
            // ...and return if the delegate denies the move request
            return;
        }
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
    /*
     To understand the purpose of declaring the __weak reference to self, see:
     https://developer.apple.com/library/ios/documentation/cocoa/conceptual/ProgrammingWithObjectiveC/WorkingwithBlocks/WorkingwithBlocks.html#//apple_ref/doc/uid/TP40011210-CH8-SW16
     */
    __weak typeof(self) weakSelf = self;
    [self.collectionView performBatchUpdates: ^{
        DLog();
        __strong typeof(self) strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf.collectionView deleteItemsAtIndexPaths: @[ previousIndexPath ]];
            [strongSelf.collectionView insertItemsAtIndexPaths: @[ newIndexPath ]];
        }
    } completion: ^(BOOL finished) {
        DLog();
        // ...on completion, if the datasource implements the didMoveToIndexPath method,
        __strong typeof(self) strongSelf = weakSelf;
        if ([strongSelf.dataSource respondsToSelector: @selector(collectionView:itemAtIndexPath:didMoveToIndexPath:)]) {
            // ...call it
            [strongSelf.dataSource collectionView: strongSelf.collectionView
                                  itemAtIndexPath: previousIndexPath
                               didMoveToIndexPath: newIndexPath];
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
- (void)setupScrollTimerInDirection: (OCAScrollingDirection)direction
{
    DLog();
    
    // Check to see if the display link is currently running
    if (!self.displayLink.paused) {
        // it is running - check to see if we're going in the same direction as last time
        OCAScrollingDirection oldDirection = [self.displayLink.OCA_userInfo[kOCAScrollingDirectionKey] integerValue];
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
    self.displayLink.OCA_userInfo = @{ kOCAScrollingDirectionKey : @(direction) };
    
    // ...and add it to the mainRunLoop so handleScroll: starts getting notifications
    [self.displayLink addToRunLoop: [NSRunLoop mainRunLoop]
                           forMode: NSRunLoopCommonModes];
}

#pragma mark - OCAEditableLayoutAttributes helper methods

//----------------------------------------------------------------------------------------------------------
+ (Class)layoutAttributesClass
{
    return [OCAEditableLayoutAttributes class];
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
    
    OCAScrollingDirection direction = (OCAScrollingDirection)[displayLink.OCA_userInfo[kOCAScrollingDirectionKey] integerValue];
    if (direction == OCAScrollingDirectionUnknown) {
        return;
    }
    
    CGSize frameSize        = self.collectionView.bounds.size;
    CGSize contentSize      = self.collectionView.contentSize;
    CGPoint contentOffset   = self.collectionView.contentOffset;
    CGFloat distance        = self.scrollingSpeed / OCA_FRAMES_PER_SECOND;
    CGPoint translation     = CGPointZero;
    
    /*
     In the switch statement, we determine a translation point, allowing for top, bottom, right, left as appropriate
     */
    switch(direction) {
        case OCAScrollingDirectionUp: {
            distance = -distance;
            CGFloat minY = 0.0f;
            
            if ((contentOffset.y + distance) <= minY) {
                distance = -contentOffset.y;
            }
            
            translation = CGPointMake(0.0f, distance);
            break;
        }
            
        case OCAScrollingDirectionDown: {
            CGFloat maxY = MAX(contentSize.height, frameSize.height) - frameSize.height;
            
            if ((contentOffset.y + distance) >= maxY) {
                distance = maxY - contentOffset.y;
            }
            
            translation = CGPointMake(0.0f, distance);
            break;
        }
            
        case OCAScrollingDirectionLeft: {
            distance = -distance;
            CGFloat minX = 0.0f;
            
            if ((contentOffset.x + distance) <= minX) {
                distance = -contentOffset.x;
            }
            
            translation = CGPointMake(distance, 0.0f);
            break;
        }
            
        case OCAScrollingDirectionRight: {
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
    
    // Finally, update center points and content offset
    self.currentViewCenter              = OCA_CGPointAdd(self.currentViewCenter, translation);
    self.currentView.center             = OCA_CGPointAdd(self.currentViewCenter, self.panTranslationViewCenter);
    self.collectionView.contentOffset   = OCA_CGPointAdd(contentOffset, translation);
}


//----------------------------------------------------------------------------------------------------------
- (void)handleLongPressGesture: (UILongPressGestureRecognizer *)gestureRecognizer
{
    DLog();
    
    switch(gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            // TODO - ideally, user should be able to long tap and begin dragging
            if (_isEditModeOn) {
                DLog(@"StateBegan with isEditModeOn");
            } else {
                DLog(@"setting editMode On");
                _isEditModeOn = YES;
                // Check if the delegate wants to know editing began
                if ([self.delegate respondsToSelector: @selector(didBeginEditingForCollectionView:layout:)]) {
                    // ...if so, inform delegate we're editing
                    [self.delegate didBeginEditingForCollectionView: self.collectionView
                                                             layout: self];
                }
            }

            /*
             Communicate with the delegate methods (if implemented) to inform of the user's (potential) move gesture
             */
            NSIndexPath *currentIndexPath = [self.collectionView indexPathForItemAtPoint: [gestureRecognizer locationInView: self.collectionView]];
            DLog(@"currentIndexPath=%@", currentIndexPath.debugDescription);
            //TODO - should be check to make sure we have long-tapped a cell?
            
            // If the delegate wants to OK moving items
            if ([self.dataSource respondsToSelector: @selector(collectionView:canMoveItemAtIndexPath:)]) {
                // ...ask for permission to move this item
                if (![self.dataSource collectionView: self.collectionView
                              canMoveItemAtIndexPath: currentIndexPath]) {
                    // ...delegate says NO, just return
                    return;
                }
            }
            
            self.selectedItemIndexPath = currentIndexPath;
            
            // Check if the delegate wants to know dragging began
            if ([self.delegate respondsToSelector: @selector(collectionView:layout:willBeginDraggingItemAtIndexPath:)]) {
                // ...if so, inform the we are starting a drag with the item at indexPath
                [self.delegate collectionView: self.collectionView
                                       layout: self
             willBeginDraggingItemAtIndexPath: self.selectedItemIndexPath];
            }
            
            /*
             Animate the selected cell 10% larger than normal
             */
            // First, get the cell selected cell
            UICollectionViewCell *collectionViewCell = [self.collectionView cellForItemAtIndexPath: self.selectedItemIndexPath];
            
            // Make a new UIView with a frame matching the selected cell's
            self.currentView = [[UIView alloc] initWithFrame: collectionViewCell.frame];
            
            // ...first we'll get the highlighted image, start by setting highlighted state YES, in case there is a different
            //    visual effect for highlighted
            collectionViewCell.highlighted          = YES;
            // ...make an imageView of it
            UIImageView *highlightedImageView       = [[UIImageView alloc] initWithImage: [collectionViewCell OCA_rasterizedImage]];
            // ...and set autoresizing mask to flexible width and height
            highlightedImageView.autoresizingMask   = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            highlightedImageView.alpha              = 1.0f;
            // ...assign a value to the highlighted view to make it easy to identify when we want to remove it (see the cancelled and ended states below)
            highlightedImageView.tag                = kOCAHighlightedImageViewTag;
            
            // ...second, we get the normal image
            collectionViewCell.highlighted          = NO;
            // ...make an imageView of it
            UIImageView *unHighlightedImageView     = [[UIImageView alloc] initWithImage: [collectionViewCell OCA_rasterizedImage]];
            // ...and set autoresizing mask to flexible width and height
            unHighlightedImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            unHighlightedImageView.alpha            = 0.0f;
            
            // ...add the two imageViews to the new UIView
            [self.currentView addSubview: unHighlightedImageView];
            [self.currentView addSubview: highlightedImageView];        // Note - highlighted image is the topmost view
            // ...and add the new UIView to the collection view
            [self.collectionView addSubview: self.currentView];
            
            self.currentViewCenter = self.currentView.center;
            
            // ...Now that all the setup is complete, do the animation
            __weak typeof(self) weakSelf = self;
            /*
             The purpose of declaring the __weak reference to self is to avoid a strong reference cycle warning, see:
             https://developer.apple.com/library/ios/documentation/cocoa/conceptual/ProgrammingWithObjectiveC/WorkingwithBlocks/WorkingwithBlocks.html#//apple_ref/doc/uid/TP40011210-CH8-SW16
             */
            [UIView animateWithDuration: 0.3
                                  delay: 0.0
                                options: UIViewAnimationOptionBeginFromCurrentState
                             animations: ^{
                                 DLog();
                                 __strong typeof(self) strongSelf = weakSelf;
                                 if (strongSelf) {
                                     // Set the make scale transform to 1.1 (or 110%) in both height and width
                                     strongSelf.currentView.transform   = CGAffineTransformMakeScale(1.1f, 1.1f);
                                     // ...fade in the highlightedImageView
                                     highlightedImageView.alpha         = 1.0f;
                                     // ...and fade out the regular view
                                     unHighlightedImageView.alpha       = 0.0f;
                                 }
                             } completion: ^(BOOL finished) {
                                 DLog();
                                 // When the animation completes,
                                 __strong typeof(self) strongSelf = weakSelf;
                                 if (strongSelf) {
                                     /*
                                      Check if the delegate has implemented collectionView:layout:didBeginDraggingItemAtIndexPath:
                                      Using an assertion allows the check to be performed (at runtime) during the development process.
                                      
                                      We are using 3 "guards" to ensure the required methods are implemented:
                                          1.  In the OCAEditableCollectionViewDelegateFlowLayout protocol definiton, we declare the method
                                              required. However the compiler only flags this as a warning.
                                          2.  The assert statement will throw an Assertion failed exception identifying the missing method.
                                              This should catch 99.999% of coding mistakes, but assertions are NOT compiled into Release builds.
                                          3.  To cover the Release build, we throw our own "Required method not implemented" exception. There is
                                              an argument to be made that throwing an exception is not only unnecessary (we could just fail on the
                                              method call), but actually undesirable. Throwing an exception means the app WILL crash, and in this
                                              case, the respondsToSelector test could just skip the method. That would result in the UI not being
                                              updated correctly, but the user could work-around the error. I implemented an exception to illustrate
                                              the technique - knowing that I've implemented the method and the exception will never be raised.
                                      */
                                     assert([strongSelf.delegate respondsToSelector: @selector(collectionView:layout:didBeginDraggingItemAtIndexPath:)]);
                                     if ([strongSelf.delegate respondsToSelector: @selector(collectionView:layout:didBeginDraggingItemAtIndexPath:)]) {
                                         // ...if so, inform the delegate we're dragging
                                         [strongSelf.delegate collectionView: strongSelf.collectionView
                                                                      layout: strongSelf
                                             didBeginDraggingItemAtIndexPath: strongSelf.selectedItemIndexPath];
                                     } else {
                                         [NSException raise: @"Required method not implemented"
                                                     format: @"collectionView:layout:didBeginDraggingItemAtIndexPath:"];
                                     }
                                     [self.collectionView reloadData];       // TODO - this seems like overkill, why can't we just invalidate ourself?
                                 }
                             }];
            break;
        }
            
        case UIGestureRecognizerStateCancelled:     // This case falls through into UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateEnded: {
            DLog(@"StateEnded or Cancelled");
            NSIndexPath *currentIndexPath = self.selectedItemIndexPath;
            
            if (currentIndexPath) {
                // Check if the delegate wants to know if dragging will end
                if ([self.delegate respondsToSelector: @selector(collectionView:layout:willEndDraggingItemAtIndexPath:)]) {
                    // ...if so, inform the delegate dragging this item will end
                    [self.delegate collectionView: self.collectionView
                                           layout: self
                   willEndDraggingItemAtIndexPath: currentIndexPath];
                }
                
                __weak typeof(self) weakSelf = self;                // See above discussion regarding strong reference cycle warning
                // Animate the highlighted, enlarged cell back to normal
                [UIView animateWithDuration: 0.3
                                      delay: 0.0
                                    options: UIViewAnimationOptionBeginFromCurrentState
                                 animations: ^{
                                     __strong typeof(self) strongSelf = weakSelf;
                                     if (strongSelf) {
                                         // Set the make scale transform to 1.1 (or 110%) in both height and width
                                         strongSelf.currentView.transform   = CGAffineTransformMakeScale(1.0f, 1.0f);
                                         // ...get the layout attributes for the cell
                                         UICollectionViewLayoutAttributes *layoutAttributes = [self layoutAttributesForItemAtIndexPath: currentIndexPath];
                                         // ...and set its center point
                                         strongSelf.currentView.center      = layoutAttributes.center;
                                         // ...find the views we're interested in using the tags we set above (see comments above)
                                         UIView *hilightedView              = [self.currentView viewWithTag: kOCAHighlightedImageViewTag];
                                         UIView *unHilightedView            = [self.currentView viewWithTag: kOCAUnHighlightedImageViewTag];
                                         // ...fade out the highlightedImageView
                                         hilightedView.alpha                = 0.0f;
                                         // ...and fade in the regular view
                                         unHilightedView.alpha              = 1.0f;
                                     }
                                 } completion: ^(BOOL finished) {
                                     // When the animation completes,
                                     __strong typeof(self) strongSelf = weakSelf;
                                     if (strongSelf) {
                                         // ...remove the highlighted view
                                         UIView *hilightedView      = [self.currentView viewWithTag: kOCAHighlightedImageViewTag];
                                         DLog(@"removing highlightedImageView=%@", hilightedView);
                                         [hilightedView removeFromSuperview];
                                         UICollectionViewCell *collectionViewCell = [self.collectionView cellForItemAtIndexPath: self.selectedItemIndexPath];
                                         [collectionViewCell setHighlighted: NO];
                                         // ...and invalidate
                                         [strongSelf invalidateLayout];
                                         // ...remove the rasterized image (if we don't, it would cover the real buttons and make them unclickable)
                                         [strongSelf.currentView removeFromSuperview];
                                         strongSelf.currentView = nil;
                                         // ...and invalidate
                                         [strongSelf.collectionView reloadData];
                                         
                                         /*
                                          Check if the delegate has implemented collectionView:layout:didBeginDraggingItemAtIndexPath:
                                          Using an assertion allows the check to be performed (at runtime) during the development process.
                                          
                                          We are using 3 "guards" to ensure the required methods are implemented:
                                              1.  In the OCAEditableCollectionViewDelegateFlowLayout protocol definiton, we declare the method
                                                  required. However the compiler only flags this as a warning.
                                              2.  The assert statement will throw an Assertion failed exception identifying the missing method.
                                                  This should catch 99.999% of coding mistakes, but assertions are NOT compiled into Release builds.
                                              3.  To cover the Release build, we throw our own "Required method not implemented" exception. There is
                                                  an argument to be made that throwing an exception is not only unnecessary (we could just fail on the
                                                  method call), but actually undesirable. Throwing an exception means the app WILL crash, and in this
                                                  case, the respondsToSelector test could just skip the method. That would result in the UI not being
                                                  updated correctly, but the user could work-around the error. I implemented an exception to illustrate
                                                  the technique - knowing that I've implemented the method and the exception will never be raised.
                                          */
                                         assert([strongSelf.delegate respondsToSelector: @selector(collectionView:layout:didEndDraggingItemAtIndexPath:)]);
                                         if ([strongSelf.delegate respondsToSelector: @selector(collectionView:layout:didEndDraggingItemAtIndexPath:)]) {
                                             // ...inform the delegate dragging has ended
                                             [strongSelf.delegate collectionView: strongSelf.collectionView
                                                                          layout: strongSelf
                                                   didEndDraggingItemAtIndexPath: currentIndexPath];
                                         } else {
                                             [NSException raise: @"Required method not implemented"
                                                         format: @"collectionView:layout:didEndDraggingItemAtIndexPath:"];
                                         }
                                         self.selectedItemIndexPath  = nil;
                                         self.currentViewCenter      = CGPointZero;
                                     }
                                 }];
            }
            break;
        }

        default:        // Several states (changed, failed, possible, recognized) are ignored
            break;
    }
}

/**
 Handles dragging a cell around the screen, modeling Springboard behavior.
 
 Note - animating the cell larger is handled in handleLongPressGesture's UIGestureRecognizerStateBegan switch
 
 @param gestureRecognizer the gestureRecognizer for which we are the action target
 */
//----------------------------------------------------------------------------------------------------------
- (void)handlePanGesture: (UIPanGestureRecognizer *)gestureRecognizer
{
//    DLog();
    
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:         // This case falls through into UIGestureRecognizerStateChanged:
        case UIGestureRecognizerStateChanged: {
            // First, move the cell by updating its center point
            // Get the "translation point" - i.e., the delta, of the new center point
            self.panTranslationViewCenter = [gestureRecognizer translationInView: self.collectionView];
            // ...add the delta to our tracking variable
            self.currentView.center = OCA_CGPointAdd(self.currentViewCenter, self.panTranslationViewCenter);
            // ...and create a local variable
            CGPoint viewCenter      = self.currentView.center;
            // Check to see if we need to re-layout
            [self invalidateLayoutIfNecessary];
            
            // Second, check to see if the collectionView needs to be scrolled
            switch (self.scrollDirection) {
                case UICollectionViewScrollDirectionVertical: {
                    // The collectionView is setup for vertical scrolling, is the cell center above the collectionView bounds + inset?
                    if (viewCenter.y < (CGRectGetMinY(self.collectionView.bounds) + self.scrollingTriggerEdgeInsets.top)) {
                        // Yes - the user is moving the cell upwards and has gone beyond the top of the currently visible view
                        // ...start the scroll timer
                        [self setupScrollTimerInDirection: OCAScrollingDirectionUp];
                    } else {
                        // ...is the cell center below the collectionView bounds - inset?
                        if (viewCenter.y > (CGRectGetMaxY(self.collectionView.bounds) - self.scrollingTriggerEdgeInsets.bottom)) {
                            // Yes - user is moving the cell downwards and has gone beyond the bottom of the currently visible view
                            // ...start the scroll timer
                            [self setupScrollTimerInDirection: OCAScrollingDirectionDown];
                        } else {
                            // ...the cell is somewhere between top and bottom - no scrolling required, so invalidate the scroll timer
                            [self invalidatesScrollTimer];
                        }
                    }
                    break;
                }
                    
                case UICollectionViewScrollDirectionHorizontal: {
                    // The collectionView is setup for horizontal scrolling, is the cell center to the left of collectionView bounds + inset?
                    if (viewCenter.x < (CGRectGetMinX(self.collectionView.bounds) + self.scrollingTriggerEdgeInsets.left)) {
                        // Yes - the user is moving the cell leftwards and has gone beyond the left edge of the currently visible view
                        // ...start the scroll timer
                        [self setupScrollTimerInDirection: OCAScrollingDirectionLeft];
                    } else {
                        // ...is the cell center to the right of collectionView bounds - inset?
                        if (viewCenter.x > (CGRectGetMaxX(self.collectionView.bounds) - self.scrollingTriggerEdgeInsets.right)) {
                            // Yes - the user is moving the cell rightwards and has gone beyond the right edge of the currently visible view
                            // ...start the scroll timer
                            [self setupScrollTimerInDirection: OCAScrollingDirectionRight];
                        } else {
                            // ...the cell is somewhere between left and right - no scrolling required, so invalidate the scroll timer
                            [self invalidatesScrollTimer];
                        }
                    }
                    break;
                }
                default:
                    break;
            }
            break;
        }
            
        case UIGestureRecognizerStateCancelled:     // This case falls through into UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateEnded: {
            // User has finished dragging, invalidate the scroll timer
            [self invalidatesScrollTimer];
            break;
        }
            
        default:        // Several states (failed, possible, recognized) are ignored
            break;
    }
}

//----------------------------------------------------------------------------------------------------------
/**
 Determine whether or not we want to handle the gesture.
 In particular, we want to "fail" on single taps in the cell so the tap event is passed on to the cell button handlers.
 
 @param gestureRecognizer the gestureRecognizer in question (could be longPress, pan, or tap)
 @return BOOL   NO if we don't want to handle it, YES otherwise
 */
- (BOOL)gestureRecognizer: (UIGestureRecognizer *)gestureRecognizer
       shouldReceiveTouch: (UITouch *)touch
{
    DLog();
    
    CGPoint touchPoint      = [touch locationInView: self.collectionView];
    NSIndexPath *indexPath  = [self.collectionView indexPathForItemAtPoint: touchPoint];
    
    if (indexPath) {
        // If indexPath is not NULL, the tap is inside a cell.
        if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
            // If the gestureRecognizer is a tap recognizer, fail the event
            return NO;
        }
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
    
    // The only purpose of a tap is to end editing, so first check to ensure editModeOn is YES
    if (_isEditModeOn) {
        // The above gestureRecognizer:shouldReceiveTouch: should prevent us from being invoked if the tap was on a cell, but just in case...
        NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint: [gestureRecognizer locationInView: self.collectionView]];
        if (!indexPath) {
            // Tap is not on any cell, end editing
            self.isEditModeOn = NO;
            // Inform the delegate (if it wants to know)
            if ([self.delegate respondsToSelector: @selector(didEndEditingForCollectionView:layout:)]) {
                // ...the delegate wants to know
                [self.delegate didEndEditingForCollectionView: self.collectionView
                                                       layout: self];
            }
            // Tell the collectionView to reload the visible cells, which will remove our delete button and stop the quivering
            [self.collectionView reloadData];
        }
    }
}

#pragma mark - UICollectionViewLayout overridden methods

//----------------------------------------------------------------------------------------------------------
- (NSArray *)layoutAttributesForElementsInRect: (CGRect)rect
{
    DLog(@"rect=%@", NSStringFromCGRect(rect));
    
    // First, call super to get all elements attributes in the rect
    NSArray *layoutAttributesForElementsInRect = [super layoutAttributesForElementsInRect: rect];
    
    for (OCAEditableLayoutAttributes *layoutAttributes in layoutAttributesForElementsInRect) {
        // For each element's attributes, update our custom attribute(s)
        switch (layoutAttributes.representedElementCategory) {
            case UICollectionElementCategoryCell: {
                if (_isEditModeOn) {
                    layoutAttributes.deleteButtonHidden = NO;
                } else {
                    layoutAttributes.deleteButtonHidden = YES;
                }
                break;
            }
            // There are no custom attributes for supplementary or decoration views, if there were
            //  they would be handled with the corresponding case statements here.
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
    
    // First, call super to get the attributes of the cell at indexPath
    OCAEditableLayoutAttributes *layoutAttributes = (OCAEditableLayoutAttributes *)[super layoutAttributesForItemAtIndexPath: indexPath];
    
    switch (layoutAttributes.representedElementCategory) {
        // Update our custom attribute
        case UICollectionElementCategoryCell: {
            if (_isEditModeOn) {
                layoutAttributes.deleteButtonHidden = NO;
            } else {
                layoutAttributes.deleteButtonHidden = YES;
            }
            break;
        }
        // There are no custom attributes for supplementary or decoration views, if there were
        //  they would be handled with the corresponding case statements here.
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
        // Check to see if we're currently handling a pan, return YES if so, NO otherwise
        return (self.selectedItemIndexPath != nil);
    }
    
    if ([self.longPressGestureRecognizer isEqual:gestureRecognizer]) {
        // Check to see if the long press is on a cell
        NSIndexPath *currentIndexPath = [self.collectionView indexPathForItemAtPoint: [gestureRecognizer locationInView: self.collectionView]];
        if (!currentIndexPath) {
            // ...it's not on a cell. "Fail" our long press handler and allow the default handler to process
            return NO;
        }
    }
    
    return YES;
}

/**
 Determine if the two gestureRecognizers allow simultaneous recognition
 
 see https://developer.apple.com/library/ios/documentation/uikit/reference/UIGestureRecognizerDelegate_Protocol/Reference/Reference.html#//apple_ref/occ/intfm/UIGestureRecognizerDelegate/gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:
 @param   gestureRecognizer sending the message
 @param   otherGestureRecognizer  the candidate to receive simultaneous events
 @return  YES if simultaneous recognition is OK, NO otherwise
 */
//----------------------------------------------------------------------------------------------------------
- (BOOL)                            gestureRecognizer: (UIGestureRecognizer *)gestureRecognizer
   shouldRecognizeSimultaneouslyWithGestureRecognizer: (UIGestureRecognizer *)otherGestureRecognizer
{
    DLog();
    
    /**
     * Note the two if statements are complementary. This is just a precaution. If either recognizer returns YES for the "other"
     * simultaneous recognition will be allowed
     */
    if ([self.longPressGestureRecognizer isEqual: gestureRecognizer]) {
        return [self.panGestureRecognizer isEqual: otherGestureRecognizer];
    }
    
    if ([self.panGestureRecognizer isEqual: gestureRecognizer]) {
        return [self.longPressGestureRecognizer isEqual: otherGestureRecognizer];
    }
    
    return NO;
}

#pragma mark - Notifications

/**
 Called when the observed object changes. (We registered for in our initialize method.)
 
 @param keyPath   the string we assigned to this notification
 @param object    the object that changed (in our case, the collectionView)
 @param change    an NSDictionary of changes
 @param context   the context we provided (in our case, nil)
 */
//----------------------------------------------------------------------------------------------------------
- (void)observeValueForKeyPath: (NSString *)keyPath
                      ofObject: (id)object
                        change: (NSDictionary *)change
                       context: (void *)context
{
    DLog();
    
    // Check to make sure its the notification we expected
    if ([keyPath isEqualToString: kOCACollectionViewKeyPath]) {
        // If we have a reference to a collection view...
        if (self.collectionView != nil) {
            // ...something happened like a rotation or the collectionView was just "popped" into view
            [self setupCollectionView];
        } else {
            // ...we're probably going away
            [self invalidatesScrollTimer];
        }
    }
}


//----------------------------------------------------------------------------------------------------------
- (void)handleApplicationWillResignActive:(NSNotification *)notification
{
    DLog();
    
    self.panGestureRecognizer.enabled = NO;
    self.panGestureRecognizer.enabled = YES;
}

@end
