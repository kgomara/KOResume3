//
//  OCRDetailViewManager.m
//  KOResume
//
//  Created by Kevin O'Mara on 11/17/13.
//  Copyright (c) 2013 O'Mara Consulting Associates. All rights reserved.
//

#import "OCRDetailViewManager.h"

@interface OCRDetailViewManager ()

/**
 Holds a reference to the split view controller's bar button item
 if the button should be shown (the device is in portrait).
 Will be nil otherwise.
 */
@property (nonatomic, strong) UIBarButtonItem *navigationPaneButtonItem;

/**
 Holds a reference to the popover that will be displayed
 when the navigation button is pressed.
 */
@property (nonatomic, strong) UIPopoverController *navigationPopoverController;

@end

@implementation OCRDetailViewManager

#pragma mark - Customer setter

/**
 Custom implementation of the setter for the detailViewController property.
 */
// -------------------------------------------------------------------------------
- (void)setDetailViewController:(UIViewController<SubstitutableDetailViewController> *)detailVC
{
    DLog();
    // Clear any bar button item from the detail view controller that is about to
    // no longer be displayed.
    self.detailViewController.navigationPaneBarButtonItem = nil;
    
    _detailViewController = detailVC;
    
    // Set the new detailViewController's navigationPaneBarButtonItem to the value of our
    // navigationPaneButtonItem.  If navigationPaneButtonItem is not nil, then the button
    // will be displayed.
    _detailViewController.navigationPaneBarButtonItem = self.navigationPaneButtonItem;
    
    // Update the split view controller's view controllers array.
    // This causes the new detail view controller to be displayed.
    UIViewController *navigationViewController  = [self.splitViewController.viewControllers objectAtIndex:0];
    NSArray *viewControllers                    = [[NSArray alloc] initWithObjects:navigationViewController, _detailViewController, nil];
    self.splitViewController.viewControllers    = viewControllers;
    
    // Dismiss the navigation popover if one was present.  This will
    // only occur if the device is in portrait.
    if (self.navigationPopoverController)
        [self.navigationPopoverController dismissPopoverAnimated:YES];
}

#pragma mark - UISplitViewDelegate methods

// -------------------------------------------------------------------------------
- (BOOL)splitViewController:(UISplitViewController *)splitViewController
   shouldHideViewController:(UIViewController *)aViewController
              inOrientation:(UIInterfaceOrientation)orientation
{
    return UIInterfaceOrientationIsPortrait(orientation);
}

// -------------------------------------------------------------------------------
- (void)splitViewController:(UISplitViewController *)splitViewController
     willHideViewController:(UIViewController *)aViewController
          withBarButtonItem:(UIBarButtonItem *)barButtonItem
       forPopoverController:(UIPopoverController *)popoverController
{
    DLog();
    
    // If the barButtonItem does not have a title (or image) adding it to a toolbar
    // will do nothing.
    barButtonItem.title                 = @"Navigation";
    
    self.navigationPaneButtonItem       = barButtonItem;
    self.navigationPopoverController    = popoverController;
    
    // Tell the detail view controller to show the navigation button.
    self.detailViewController.navigationPaneBarButtonItem = barButtonItem;
}

// -------------------------------------------------------------------------------
- (void)splitViewController:(UISplitViewController *)splitViewController
     willShowViewController:(UIViewController *)aViewController
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    DLog();
    
    self.navigationPaneButtonItem       = nil;
    self.navigationPopoverController    = nil;
    
    // Tell the detail view controller to remove the navigation button.
    self.detailViewController.navigationPaneBarButtonItem = nil;
}


@end
