//
//  OCRPackagesViewController.m
//  KOResume
//
//  Created by Kevin O'Mara on 6/5/11.
//  Copyright (c) 2011-2014 O'Mara Consulting Associates. All rights reserved.
//

#import "OCRPackagesViewController.h"
#import "OCRBaseDetailViewController.h"
#import "OCRAppDelegate.h"
#import "OCRCoverLtrViewController.h"
#import "Packages.h"
#import "Resumes.h"
#import <CoreData/CoreData.h>
//#import "InfoViewController.h"

/**
 Manage Packages objects.
 
 It uses a UICollectionView to display the list of Packages, and dispatches OCRCoverLtrViewController or OCRResumeViewController.
 
 Credits:
 
 Akiehl Kahn's "Springboard-like layout with Collection Views" - http://mobile.tutsplus.com/tutorials/iphone/uicollectionview-layouts/
 
 Stan Chang, Khin Boon's "LXReorderableCollectionViewFlowLayout" https://github.com/lxcid/LXReorderableCollectionViewFlowLayout
 */

#define k_tblHdrHeight      50.0f

#define k_cover_ltrRow      0
#define k_resumeRow         1

@interface OCRPackagesViewController ()
{
@private
    /**
     Array to keep track of changes made to collectionView section.
     */
    NSMutableArray *_sectionChanges;
    
    /**
     Array to keep track of changes made to collectionView objects.
     */
    NSMutableArray *_objectChanges;
}

/**
 The popoverController of the for the splitView.
 */
@property (nonatomic, strong) UIPopoverController           *packagesPopoverController;

/**
 The back button for the root popover.
 */
@property (nonatomic, strong) UIBarButtonItem               *rootPopoverButtonItem;

/**
 Reference to the fetchResultsController.
 */
@property (nonatomic, strong) NSFetchedResultsController    *fetchedResultsController;

@end

@implementation OCRPackagesViewController

/**
 Flag to indicate the UI is in editing state.
 */
BOOL isEditModeActive;

#pragma mark - View lifecycle

//----------------------------------------------------------------------------------------------------------
/**
 Prepares the receiver for service after it has been loaded from an Interface Builder archive, or nib file.
 
 The nib-loading infrastructure sends an awakeFromNib message to each object recreated from a nib archive,
 but only after all the objects in the archive have been loaded and initialized. When an object receives an
 awakeFromNib message, it is guaranteed to have all its outlet and action connections already established.
 You must call the super implementation of awakeFromNib to give parent classes the opportunity to perform any
 additional initialization they require. Although the default implementation of this method does nothing,
 many UIKit classes provide non-empty implementations. You may call the super implementation at any point
 during your own awakeFromNib method.
 
 Note - During Interface Builder’s test mode, this message is also sent to objects instantiated from loaded
 Interface Builder plug-ins. Because plug-ins link against the framework containing the object definition code,
 Interface Builder is able to call their awakeFromNib method when present. The same is not true for custom
 objects that you create for your Xcode projects. Interface Builder knows only about the defined outlets and
 actions of those objects; it does not have access to the actual code for them.
 
 During the instantiation process, each object in the archive is unarchived and then initialized with the method
 befitting its type. Objects that conform to the NSCoding protocol (including all subclasses of UIView and
 UIViewController) are initialized using their initWithCoder: method. All objects that do not conform to the
 NSCoding protocol are initialized using their init method. After all objects have been instantiated and
 initialized, the nib-loading code reestablishes the outlet and action connections for all of those objects.
 It then calls the awakeFromNib method of the objects. For more detailed information about the steps followed
 during the nib-loading process, see “Nib Files” in Resource Programming Guide.
 
 Important - Because the order in which objects are instantiated from an archive is not guaranteed, your
 initialization methods should not send messages to other objects in the hierarchy. Messages to other objects
 can be sent safely from within an awakeFromNib method.
 
 Typically, you implement awakeFromNib for objects that require additional set up that cannot be done at
 design time. For example, you might use this method to customize the default configuration of any controls
 to match user preferences or the values in other controls. You might also use it to restore individual controls
 to some previous state of your application.
 */
- (void)awakeFromNib
{
    DLog();
    
    // Allocate our custom collectionView layout
    OCAEditableCollectionViewFlowLayout *layout = [[OCAEditableCollectionViewFlowLayout alloc] init];
    // ...set some parameters to control its behavior
    layout.minimumInteritemSpacing  = 6;
    layout.minimumLineSpacing       = 6;
    layout.scrollDirection          = UICollectionViewScrollDirectionVertical;
    layout.sectionInset             = UIEdgeInsetsMake(5, 5, 5, 5);
    
    // Set our layout on the collectionView
    self.collectionView.collectionViewLayout = layout;
    // ...and set the collectionView into paging mode
    self.collectionView.pagingEnabled = YES;
    
    // If the device is an iPad...
//    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        // Set the clearsSelectionOnViewWillAppear property to keep selected cells
        self.clearsSelectionOnViewWillAppear    = NO;
        // ...and set the content size of our view
        self.preferredContentSize               = CGSizeMake(320.0, 600.0);
//    }
    
    [super awakeFromNib];
}

//----------------------------------------------------------------------------------------------------------
/**
 Called after the controller’s view is loaded into memory.
 
 This method is called after the view controller has loaded its view hierarchy into memory. This method is
 called regardless of whether the view hierarchy was loaded from a nib file or created programmatically in
 the loadView method. You usually override this method to perform additional initialization on views that
 were loaded from nib files.
 */
- (void)viewDidLoad
{
    DLog();
    
    [super viewDidLoad];
    
    // Set the App name as the Title in the Navigation bar
    NSString *title = NSLocalizedString(@"Packages", nil);
#ifdef DEBUG
    // Include the version in the title for debug builds
    NSString *version           = [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"];
    self.navigationItem.title   = [NSString stringWithFormat: @"%@-%@", title, version];
#else
    self.navigationItem.title   = title;
#endif
    
    // Set up the defaults in the Navigation Bar
    [self configureDefaultNavBar];
    
    // Set tintColor on the collection view
    [self.collectionView setTintColor: [UIColor redColor]];
    
    // Push the InfoViewController onto the stack so the user knows we're waiting for the persistentStoreCoordinator
    // to load the database. The user will be able to dismiss it once the coordinator posts an NSNotification
    // indicating we're ready.
//    InfoViewController *infoViewController = [[[InfoViewController alloc] initWithNibName: OCRInfoViewController
//                                                                                   bundle: nil] autorelease];
//    [infoViewController setTitle: NSLocalizedString(@"Loading Database", nil)];
//    [infoViewController.navigationItem setHidesBackButton: YES];
//    [self.navigationController pushViewController: infoViewController
//                                         animated: YES];
    
}

//----------------------------------------------------------------------------------------------------------
/**
 Notifies the view controller that its view is about to be added to a view hierarchy.
 
 This method is called before the receiver’s view is about to be added to a view hierarchy and before any
 animations are configured for showing the view. You can override this method to perform custom tasks associated
 with displaying the view. For example, you might use this method to change the orientation or style of the
 status bar to coordinate with the orientation or style of the view being presented. If you override this method,
 you must call super at some point in your implementation.
 
 For more information about the how views are added to view hierarchies by a view controller, and the sequence of
 messages that occur, see “Responding to Display-Related Notifications”.
 
 Note
 If a view controller is presented by a view controller inside of a popover, this method is not invoked on the 
 presenting view controller after the presented controller is dismissed.
 
 @param animated        If YES, the view is being added to the window using an animation.
 */
- (void)viewWillAppear: (BOOL)animated
{
    DLog();
    
    [super viewWillAppear: animated];
    
    [self.navigationItem setHidesBackButton: NO];
    self.fetchedResultsController.delegate = self;
    
    // Observe the app delegate telling us when it's finished asynchronously adding the store coordinator
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(reloadFetchedResults:)
                                                 name: kOCRApplicationDidAddPersistentStoreCoordinatorNotification
                                               object: nil];
    
    // ...add an observer for Dynamic Text size changes
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(userTextSizeDidChange:)
                                                 name: UIContentSizeCategoryDidChangeNotification
                                               object: nil];
    
    
    // ...add an observer for asynchronous iCloud merges - not used in this version
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(reloadFetchedResults:)
                                                 name: kOCRApplicationDidMergeChangesFrom_iCloudNotification
                                               object: nil];
    
    // Loop through all the packages writing their debugDescription to the log
    for (Packages *aPackage in [self.fetchedResultsController fetchedObjects]) {
        DLog(@"%@", [aPackage debugDescription]);
    }
    
    // Reload the fetched results
    [self reloadFetchedResults: nil];
}


//----------------------------------------------------------------------------------------------------------
/**
 Notifies the view controller that its view is about to be removed from a view hierarchy.
 
 This method is called in response to a view being removed from a view hierarchy. This method is called before
 the view is actually removed and before any animations are configured.
 
 Subclasses can override this method and use it to commit editing changes, resign the first responder status of
 the view, or perform other relevant tasks. For example, you might use this method to revert changes to the
 orientation or style of the status bar that were made in the viewDidDisappear: method when the view was first
 presented. If you override this method, you must call super at some point in your implementation.
 
 @param animated        If YES, the disappearance of the view is being animated.
 */
- (void)viewWillDisappear: (BOOL)animated
{
    // Save any changes
    DLog();
    
    [super viewWillDisappear: animated];
    
    [kAppDelegate saveContext: _managedObjectContext];
    
    // Remove ourself from observing notifications
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}


//----------------------------------------------------------------------------------------------------------
/**
 Sent to the view controller when the app receives a memory warning.
 
 Your app never calls this method directly. Instead, this method is called when the system determines that the
 amount of available memory is low.
 
 You can override this method to release any additional memory used by your view controller. If you do, your
 implementation of this method must call the super implementation at some point.
 */
- (void)didReceiveMemoryWarning
{
    ALog();
    
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}


//----------------------------------------------------------------------------------------------------------
/**
 Returns whether the view controller’s contents should auto rotate.
 
 In iOS 5 and earlier, the default return value was NO.
 
 @return           YES if the content should rotate, otherwise NO. Default value is YES.
 */
- (BOOL)shouldAutorotate
{
    // Always support rotation
    return YES;
}

//----------------------------------------------------------------------------------------------------------
/**
 Returns all of the interface orientations that the view controller supports.
 
 When the user changes the device orientation, the system calls this method on the root view controller or the
 topmost presented view controller that fills the window. If the view controller supports the new orientation,
 the window and view controller are rotated to the new orientation. This method is only called if the view
 controller’s shouldAutorotate method returns YES.
 
 Override this method to report all of the orientations that the view controller supports. The default values
 for a view controller’s supported interface orientations is set to UIInterfaceOrientationMaskAll for the iPad
 idiom and UIInterfaceOrientationMaskAllButUpsideDown for the iPhone idiom.
 
 The system intersects the view controller’s supported orientations with the app's supported orientations (as
 determined by the Info.plist file or the app delegate's application:supportedInterfaceOrientationsForWindow:
 method) to determine whether to rotate.
 
 @return           A bit mask specifying which orientations are supported. See UIInterfaceOrientationMask for
 valid bit-mask values. The value returned by this method must not be 0.
 */
- (NSUInteger)supportedInterfaceOrientations
{
    // All interface orientations are supported
    return UIInterfaceOrientationMaskAll;
}


//----------------------------------------------------------------------------------------------------------
/**
 Configure the default items for the navigation bar.
 */
- (void)configureDefaultNavBar
{
    DLog();
    
    // Initialize the buttons
    UIBarButtonItem *addButton  = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemAdd
                                                                                target: self
                                                                                action: @selector(promptForPackageName)];
    
    // Set into the nav bar.
    self.navigationItem.rightBarButtonItem = addButton;
}

#pragma mark - UITextKit handlers

//----------------------------------------------------------------------------------------------------------
/**
 Called when the user changes the size of dynamic text.
 
 @param aNotification   The notification sent with the UIContentSizeCategoryDidChangeNotification notification
 */
- (void)userTextSizeDidChange: (NSNotification *)aNotification
{
    DLog();
    
    // Reload the collection view, which in turn causes the collectionView cells to update their fonts
    [self.collectionView reloadData];
}


#pragma mark - UI handlers

//----------------------------------------------------------------------------------------------------------
/**
 Add a new Package object.
 
 @param aPackage    The name of the Package to add.
 */
- (void)addPackage: (NSString *)aPackage
{
    DLog();
    
    // Insert a new Package into the managed object context
    Packages *nuPackage = (Packages *)[NSEntityDescription insertNewObjectForEntityForName: kOCRPackagesEntity
                                                                    inManagedObjectContext: [kAppDelegate managedObjectContext]];
    // Set the name of the Package (provided by the user)
    nuPackage.name                  = aPackage;
    // ...the created_date to "now"
    nuPackage.created_date          = [NSDate date];
    // ...and set its sequence_number to be the last Package
    nuPackage.sequence_numberValue  = [[self.fetchedResultsController fetchedObjects] count];
    
    // Add a Resume for the package
    // First, insert a new Resume into the managed object context
    Resumes *nuResume  = (Resumes *)[NSEntityDescription insertNewObjectForEntityForName: kOCRResumesEntity
                                                                  inManagedObjectContext: [kAppDelegate managedObjectContext]];
    // Set the default name of the resume
    nuResume.name                   = NSLocalizedString(@"Resume", nil);
    // ...the created_date to "now"
    nuResume.created_date           = [NSDate date];
    // ...and set its sequence_number to 1 (there can be only 1)
    nuResume.sequence_numberValue   = 1;

    // Set the relationship between the Package and Resume objects
    nuPackage.resume                = nuResume;
    
    // Save all the changes to the context, and wait for the operation to complete...
    [kAppDelegate saveContextAndWait: [kAppDelegate managedObjectContext]];
    // ...when the save completes, reload the data
    [self reloadFetchedResults: nil];
    // ...and collectionView
    [self.collectionView reloadData];
}


//----------------------------------------------------------------------------------------------------------
/**
 Prompt the user to enter a name for the new Package object
 */
- (void)promptForPackageName
{
    DLog();
    
    UIAlertView *packageNameAlert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Enter Package Name", nil)
                                                               message: nil
                                                              delegate: self
                                                     cancelButtonTitle: NSLocalizedString(@"Cancel", nil)
                                                     otherButtonTitles: NSLocalizedString(@"OK", nil), nil];
    packageNameAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    [packageNameAlert show];
}


//----------------------------------------------------------------------------------------------------------
/**
 Sent to the delegate when the user clicks a button on an alert view.
 
 The receiver is automatically dismissed after this method is invoked.
 
 @param alertView       The alert view containing the button.
 @param buttonIndex     The index of the button that was clicked. The button indices start at 0.
 */
- (void)    alertView:(UIAlertView *)alertView
 clickedButtonAtIndex: (NSInteger)buttonIndex
{
    DLog();
    
    // Check whether the user entered a Package name or cancelled
    if (buttonIndex == 1) {
        // OK - get the Package name from the alertView and pass it to addPackage
        [self addPackage: [[alertView textFieldAtIndex: 0] text]];
    } else {
        // Cancel - reset the UI to "normal" state
        [self configureDefaultNavBar];
    }
}

#pragma mark - OCRPackagesCellDelegate methods

//----------------------------------------------------------------------------------------------------------
/**
 Handle the cover letter button.
 
 @param sender  The UIButton pressed.
 */
- (IBAction)didPressCoverLtrButton: (id)sender
{
    // configureCell:atIndexPath sets the tag on the button
    DLog(@"sender = %@", @([(UIButton *)sender tag]));
    
    // Check to see if we're in editMode
    if (isEditModeActive) {
        // ignore the tap
    } else {
        // Perform the segue using the identifier in the Storyboard
        [self performSegueWithIdentifier: kOCRCvrLtrSegue
                                  sender: sender];
    }
}


//----------------------------------------------------------------------------------------------------------
/**
 Handle the resume button.
 
 @param sender  The UIButton pressed.
 */
- (IBAction)didPressResumeButton: (id)sender
{
    // configureCell:atIndexPath sets the tag on the button
    DLog(@"sender = %@", @([(UIButton *)sender tag]));
    
    // Check to see if we're in editMode
    if (isEditModeActive) {
        // ignore the tap
    } else {
        // Perform the segue using the identifier in the Storyboard
        [self performSegueWithIdentifier: kOCRResumeSegue
                                  sender: sender];
    }
}

#pragma mark - UICollectionView data source

//----------------------------------------------------------------------------------------------------------
/**
 Return the number of sections in the collection view.
 
 @param collectionView  The collection view object.
 @return                The number of sections
 */
- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView
{
    /*
     We are hardcoding to 1 here because we want a single section containing all the packages.
     */
    return 1;
}


//----------------------------------------------------------------------------------------------------------
/**
 Return the number of items in a section of the collection view.
 
 @param collectionView  The collection view object
 @param section         The section for which the number of items is needed.
 @return                The number of items in the section
 */
- (NSInteger)collectionView: (UICollectionView *)collectionView
     numberOfItemsInSection: (NSInteger)section
{
    DLog(@"section=%@", @([[self.fetchedResultsController sections] count]));
    
    /*
     In our case, we only want a single section, so our fetchedResultsController is set up to retrieve everything
     in one section, and we just return the number of objects in section[0]
     */
    id <NSFetchedResultsSectionInfo> sectionInfo = (self.fetchedResultsController.sections)[0];
    NSUInteger rows = [sectionInfo numberOfObjects];
    DLog(@"rows=%@", @(rows));

    return rows;
}



//----------------------------------------------------------------------------------------------------------
/**
 Return a collection view cell configured for the indexPath.
 
 @param collectionView  The collection view object.
 @param indexPath       The indexPath for the cell needed.
 @return                A configured cell.
 */
- (UICollectionViewCell *)collectionView: (UICollectionView *)collectionView
                  cellForItemAtIndexPath: (NSIndexPath *)indexPath
{
    DLog();
    
    OCRPackagesCell *cell = (OCRPackagesCell *)[collectionView dequeueReusableCellWithReuseIdentifier: kOCRPackagesCellID
                                                                                         forIndexPath: indexPath];
    // Set OCACollectionViewFlowLayoutCell properties required for deletion
    cell.deleteDelegate = (OCAEditableCollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    
	// Configure the cell.
    [self configureCell: cell
            atIndexPath: indexPath];
    
    return cell;
}

//----------------------------------------------------------------------------------------------------------
/**
 Helper method to configure a cell when asked by the collection view.
 
 @param cell            The cell to configure.
 @param indexPath       The indexPath for the cell needed.
 @return                A configured cell.
 */
- (void)configureCell: (OCRPackagesCell *)cell
          atIndexPath: (NSIndexPath *)indexPath
{
    DLog(@"%@", indexPath.debugDescription);
    
    id <NSFetchedResultsSectionInfo> sectionInfo    = (self.fetchedResultsController.sections)[indexPath.section];
    Packages *aPackage                              = (Packages *) (sectionInfo.objects)[indexPath.row];
    /*
     Set the tag for the cell and its buttons to the row of the Packages object.
     The tag property is often used to carry identifying information for later use. In our case, we'll use it in the
     button handling routines to know which cover_ltr or resume to segue to.
     */
    cell.tag                = indexPath.row;
    cell.coverLtrButton.tag = indexPath.row;
    cell.resumeButton.tag   = indexPath.row;

    cell.title.text = aPackage.name;
    
    // Set the title of the resume button
    [cell.resumeButton setTitle: aPackage.resume.name
                       forState: UIControlStateNormal];
}


#pragma mark - UICollectionView delegates

//----------------------------------------------------------------------------------------------------------
/**
 Asks the delegate if the specified item should be selected.
 
 The collection view calls this method when the user tries to select an item in the collection view. It does 
 not call this method when you programmatically set the selection.
 
 If you do not implement this method, the default return value is YES.
 
 @param collectionView  The collection view object that is asking whether the selection should change.
 @param indexPath       The index path of the cell to be selected.
 @return                YES if the item should be selected or NO if it should not.
 */
- (BOOL)        collectionView: (UICollectionView *)collectionView
   shouldSelectItemAtIndexPath: (NSIndexPath *)indexPath
{
    DLog();
    
    if (isEditModeActive) {
        return NO;
    } else {
        return YES;
    }
}

#pragma mark - OCAEditableCollectionViewDelegateFlowLayout methods

//----------------------------------------------------------------------------------------------------------
/**
 Asks the delegate for the size of the specified item’s cell.
 
 If you do not implement this method, the flow layout uses the values in its itemSize property to set the size 
 of items instead. Your implementation of this method can return a fixed set of sizes or dynamically adjust 
 the sizes based on the cell’s content.
 
 The flow layout does not crop a cell’s bounds to make it fit into the grid. Therefore, the values you return 
 must allow for the item to be displayed fully in the collection view. For example, in a vertically scrolling 
 grid, the width of a single item must not exceed the width of the collection view view (minus any section 
 insets) itself. However, in the scrolling direction, items can be larger than the collection view because the 
 remaining content can always be scrolled into view.
 
 @param collectionView          The collection view object displaying the flow layout.
 @param collectionViewLayout    The layout object requesting the information.
 @param indexPath               The index path of the item.
 @return                        The width and height of the specified item. Both values must be greater than 0.
 */
- (CGSize)collectionView: (UICollectionView *)collectionView
                  layout: (UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath: (NSIndexPath *)indexPath
{
    CGSize result;

    // Get the Package represented by the cell at indexPath
    id <NSFetchedResultsSectionInfo> sectionInfo    = (self.fetchedResultsController.sections)[indexPath.section];
    Packages *aPackage                              = (Packages *) (sectionInfo.objects)[indexPath.row];
    
    /*
     To support Dynamic Text, we need to calculate the size required by the text at run time given the
     user's preferred dynamic text size.
     
     We use boundingRectWithSize:options:attributes:context on each of the text strings of the cell's UI 
     elements to determine the width required to show the content as completely as possible.
     
     Using this information we determine the largest width of the three (but not too large to fit in the
     content area) and return a CGSize structure.
     We use CGRectIntegral here to ensure the rect is actually large enough. Here's the "help" for CGRectIntegral:
        Returns the smallest rectangle that results from converting the source rectangle values to integers.
     
        Returns a rectangle with the smallest integer values for its origin and size that contains the source rectangle.
        That is, given a rectangle with fractional origin or size values, CGRectIntegral rounds the rectangle’s origin
        downward and its size upward to the nearest whole integers, such that the result contains the original rectangle.
     */
    
    // maxTextSize establishes bounds for the largest rect we can allow
    CGSize maxTextSize = CGSizeMake( collectionView.contentSize.width - 10.0f, kOCRPackagesCellHeight / 3);
    
    // First, determine the size required by the the name string, given the user's dynamic text size preference
    NSString *stringToSize  = aPackage.name;
    // ...get the bounding rect
	CGRect titleRect        = CGRectIntegral( [stringToSize boundingRectWithSize: maxTextSize
                                                                         options: NSStringDrawingUsesLineFragmentOrigin
                                                                      attributes: @{NSFontAttributeName: [UIFont preferredFontForTextStyle: [OCRPackagesCell titleFont]]}
                                                                         context: nil]);
    // Similarly, determine the size required by "Cover Letter"
    stringToSize            = NSLocalizedString(@"Cover Letter", nil);
	CGRect coverLtrRect     = CGRectIntegral( [stringToSize boundingRectWithSize: maxTextSize
                                                                         options: NSStringDrawingUsesLineFragmentOrigin
                                                                      attributes: @{NSFontAttributeName: [UIFont preferredFontForTextStyle: [OCRPackagesCell detailFont]]}
                                                                         context: nil]);
    // ...and the name of the resume
    stringToSize            = aPackage.resume.name;
	CGRect resumeRect       = CGRectIntegral( [stringToSize boundingRectWithSize: maxTextSize
                                                                         options: NSStringDrawingUsesLineFragmentOrigin
                                                                      attributes: @{NSFontAttributeName: [UIFont preferredFontForTextStyle: [OCRPackagesCell detailFont]]}
                                                                         context: nil]);
    
    // In our case we can keep the height constant because the 2 buttons already have sufficient vertical padding.
    result.height       = kOCRPackagesCellHeight;
    // ...and the width as the largest of the three strings (plus padding), but capped at the collection
    //    view's contentSize.width (minus padding)
    CGFloat cellWidth   = MAX(titleRect.size.width, coverLtrRect.size.width);
    cellWidth           = MAX(resumeRect.size.width, cellWidth);
    result.width        = MIN(cellWidth + kOCRPackagesCellWidthPadding, collectionView.contentSize.width - 10.0f);
    
	return result;
}

//----------------------------------------------------------------------------------------------------------
/**
 Inform the delegate editing of the collection view layout has begun.
 
 @param collectionView          The collection view object displaying the flow layout.
 @param collectionViewLayout    The layout object where editing has begun.
 */
- (void) didBeginEditingForCollectionView: (UICollectionView *)collectionView
                                   layout: (UICollectionViewLayout*)collectionViewLayout
{
    DLog();
    
    // Set the flag indicating we are in edit mode
    isEditModeActive = YES;
}


//----------------------------------------------------------------------------------------------------------
/**
 Inform the delegate editing of the collection view layout has ended.
 
 @param collectionView          The collection view object displaying the flow layout.
 @param collectionViewLayout    The layout object where editing has ended.
 */
- (void) didEndEditingForCollectionView: (UICollectionView *)collectionView
                                 layout: (UICollectionViewLayout*)collectionViewLayout
{
    DLog();
    
    // Unset the flag indicating we are in edit mode
    isEditModeActive = NO;

    // Resequence the Packages in case the order was changed in the UI
    [self resequencePackages];
    // Save the context
    [kAppDelegate saveContext: _managedObjectContext];
}


//----------------------------------------------------------------------------------------------------------
/**
 Ask the delegate if editing is allowed by this collectionview and layout.
 
 @param collectionView          The collection view object displaying the flow layout.
 @param collectionViewLayout    The layout object where editing will occur.
 @return                        YES if editing is allowed, NO otherwise.
 */
- (BOOL)shouldEnableEditingForCollectionView: (UICollectionView *)collectionView
                                      layout: (UICollectionViewLayout *)collectionViewLayout
{
    return YES;
}

#pragma mark - OCAEditableCollectionViewDataSource methods

//----------------------------------------------------------------------------------------------------------
/**
 Ask the delegate if the cell at indexPath can be moved.

 @param collectionView          The collection view object displaying the flow layout.
 @param indexPath               The index path of the item.
 @return                        YES if the cell can be moved, NO if not.
*/
- (BOOL)collectionView: (UICollectionView *)collectionView
canMoveItemAtIndexPath: (NSIndexPath *)indexPath
{
    return YES;
}


//----------------------------------------------------------------------------------------------------------
/**
 Ask the delegate if the cell at fromIndexPath can be moved to toIndexPath.
 
 @param collectionView          The collection view object displaying the flow layout.
 @param fromIndexPath           The index path the item will be move from.
 @param toIndexPath             The destination index path of the item.
 @return                        YES if the cell can be moved, NO if not.
 */
- (BOOL)collectionView: (UICollectionView *)collectionView
       itemAtIndexPath: (NSIndexPath *)fromIndexPath
    canMoveToIndexPath: (NSIndexPath *)toIndexPath
{
    DLog();
    
    // All moves are acceptable
    return YES;
}


//----------------------------------------------------------------------------------------------------------
/**
 Inform the delegate the cell at indexPath has moved.
 
 @param collectionView          The collection view object displaying the flow layout.
 @param fromIndexPath           The index path the item was moved from.
 @param toIndexPath             The destination index path of the item.
 */
- (void)collectionView: (UICollectionView *)collectionView
       itemAtIndexPath: (NSIndexPath *)fromIndexPath
    didMoveToIndexPath: (NSIndexPath *)toIndexPath;
{
    DLog();
    
    // This UI has been updated, now update the underlying data structures.
    [self moveItemAtIndexPath: fromIndexPath
                  toIndexPath: toIndexPath];
}

//----------------------------------------------------------------------------------------------------------
/**
 Ask the delegate if the cell at indexPath can be deleted.
 
 @param collectionView          The collection view object displaying the flow layout.
 @param indexPath               The index path of the cell to delete.
 @return                        YES if the cell can be deleted, NO if not.
 */
- (BOOL)    collectionView: (UICollectionView *)collectionView
  canDeleteItemAtIndexPath: (NSIndexPath *)indexPath
{
    DLog();
    
    // All cells can be deleted
    return YES;
}


//----------------------------------------------------------------------------------------------------------
/**
 Inform the delegate the cell at indexPath is about to be deleted.
 
 @param collectionView          The collection view object displaying the flow layout.
 @param indexPath               The index path of the cell about to be deleted.
 */
- (void)    collectionView: (UICollectionView *)collectionView
 willDeleteItemAtIndexPath: (NSIndexPath *)indexPath
{
    DLog();
    
    // Get the package that is that is about to be deleted from the collectionView
    Packages *packageToDelete   = [self.fetchedResultsController objectAtIndexPath: indexPath];
    // ...and the managed object context
    NSManagedObjectContext *moc = [self.fetchedResultsController managedObjectContext];
    // ...and delete it from the data model
    [moc deleteObject: packageToDelete];
    
    /*
     Here we save the context and wait for the operation to complete. If we invoked the asynchronous saveContext
     method it would return immediately and the collectionView throw an assertion error because the collectionView
     would be out of sync with the data model.
     */
    [kAppDelegate saveContextAndWait: moc];
}


#pragma mark - UISplitViewControllerDelegate methods

//----------------------------------------------------------------------------------------------------------
/**
 Asks the delegate whether the first view controller should be hidden for the specified orientation.
 
 The split view controller calls this method only for the first child view controller in its array. The second 
 view controller always remains visible regardless of the orientation.

 @param svc         The split view controller that owns the first view controller.
 @param vc          The first view controller in the array of view controllers.
 @param orientation The orientation being considered.
 @return            YES if the view controller should be hidden in the specified orientation or NO if it should 
                    be visible.
 */
- (BOOL)splitViewController: (UISplitViewController *)svc
   shouldHideViewController: (UIViewController *)vc
              inOrientation: (UIInterfaceOrientation)orientation
{
    if (UIInterfaceOrientationIsPortrait(orientation)) {
        return YES; // if you return NO, it will display side by side, not above.
    }
    
    return NO;
}

//----------------------------------------------------------------------------------------------------------
/**
 Tells the delegate that the specified view controller is about to be hidden.
 
 When the split view controller rotates from a landscape to portrait orientation, it normally hides one of its 
 view controllers. When that happens, it calls this method to coordinate the addition of a button to the toolbar 
 (or navigation bar) of the remaining custom view controller. If you want the soon-to-be hidden view controller 
 to be displayed in a popover, you must implement this method and use it to add the specified button to your 
 interface.

 @param svc                 The split view controller that owns the specified view controller.
 @param aViewController     The view controller being hidden.
 @param barButtonItem       A button you can add to your toolbar.
 @param aPopoverController  The popover controller that uses taps in barButtonItem to display the specified 
                            view controller.
 */
- (void)splitViewController: (UISplitViewController*)svc
     willHideViewController: (UIViewController *)aViewController
          withBarButtonItem: (UIBarButtonItem*)barButtonItem
       forPopoverController: (UIPopoverController*)aPopoverController
{
    DLog();
    
    // Keep references to the popover controller and the popover button, and tell the detail view controller to show the button.
    barButtonItem.title             = @"Packages";
    self.packagesPopoverController  = aPopoverController;
    self.rootPopoverButtonItem      = barButtonItem;
    
    OCRBaseDetailViewController <SubstitutableDetailViewController> *detailViewController = (OCRBaseDetailViewController<SubstitutableDetailViewController>*)[(svc.viewControllers)[1] topViewController];
    [detailViewController showRootPopoverButtonItem: _rootPopoverButtonItem
                                     withController: aPopoverController];
}


//----------------------------------------------------------------------------------------------------------
/**
 Tells the delegate that the specified view controller is about to be shown again.
 
 When the view controller rotates from a portrait to landscape orientation, it shows its hidden view controller 
 once more. If you added the specified button to your toolbar to facilitate the display of the hidden view 
 controller in a popover, you must implement this method and use it to remove that button.

 @param svc                 The split view controller that owns the specified view controller.
 @param aViewController     The view controller being hidden.
 @param button              The button used to display the view controller while it was hidden.
 */
- (void)splitViewController: (UISplitViewController*)svc
     willShowViewController: (UIViewController *)aViewController
  invalidatingBarButtonItem: (UIBarButtonItem *)button
{
    DLog();
    
    // Nil out references to the popover controller and the popover button, and tell the detail view controller to hide the button.
    OCRBaseDetailViewController <SubstitutableDetailViewController> *detailViewController = (OCRBaseDetailViewController<SubstitutableDetailViewController>*)[(svc.viewControllers)[1] topViewController];
    [detailViewController invalidateRootPopoverButtonItem: _rootPopoverButtonItem];
    self.packagesPopoverController  = nil;
    self.rootPopoverButtonItem      = nil;
}


#pragma mark - Private methods

//----------------------------------------------------------------------------------------------------------
/**
 Loop through the cells in the collection view and update their sequence_number.
 
 When and add, move, or delete operation completes call this method to update the sequence_number in the
 database.
 */
- (void)resequencePackages
{
    DLog();
    
    // Get the array of packages as they are after the add, move, or delete
#warning TODO - don't we want the UI's order?
    NSArray *packages = [self.fetchedResultsController fetchedObjects];
    
    // Get the number of sections in order to construct an indexPath
    NSInteger sectionCount = [self.collectionView numberOfSections];
    
    // Start our sequence numbers at 1
    int i = 1;
    for (NSInteger section = 0; section < sectionCount; section++) {
        NSInteger itemCount = [self.collectionView numberOfItemsInSection: section];
        for (NSInteger item = 0; item < itemCount; item++) {
            // Construct an NSIndexPath given the section and row
            NSIndexPath *indexPath          = [NSIndexPath indexPathForItem: item
                                                                  inSection: section];
            // ...and get the cooresponding cell from the collection view
            OCRPackagesCell *packagesCell   = (OCRPackagesCell *)[self.collectionView cellForItemAtIndexPath: indexPath];

            Packages *aPackage = packages[packagesCell.tag];    // TODO - backwards - we want to iterate this array?
            [aPackage setSequence_number: @(i++)];       // TODO - sequence number does not seem to stick
            DLog(@"%@", [aPackage debugDescription]);
        }
    }
}


//----------------------------------------------------------------------------------------------------------
/**
 Helper method called when a cell has moved to move the cooresponding package.
 
 After the user re-orders the cells representing packages, call this method to re-order the packages in the
 package array and resequence them.
 
 @param indexPath       The starting NSIndexPath of the cell.
 @param newIndexPath    The destination of the move.
 */
- (void)moveItemAtIndexPath: (NSIndexPath *)indexPath
                toIndexPath: (NSIndexPath *)newIndexPath
{
    DLog();
    
    NSMutableArray *packages = [[self.fetchedResultsController fetchedObjects] mutableCopy];
    
    // Grab the item we're moving.
    NSManagedObject *movedPackage = [[self fetchedResultsController] objectAtIndexPath: indexPath];
    
    // Remove the object we're moving from the array.
    [packages removeObject: movedPackage];
    // Now re-insert it at the destination.
    [packages insertObject: movedPackage
                   atIndex: newIndexPath.row];
    
    // All of the objects are now in their correct order. Update each
    // object's sequence_number field by iterating through the array.
    int i = 0;
    for (Packages *aPackage in packages) {
        [aPackage setSequence_numberValue: i++];
    }
}


#pragma mark - Seque handling

//----------------------------------------------------------------------------------------------------------
/**
 Notifies the view controller that a segue is about to be performed.
 
 The default implementation of this method does nothing. Your view controller overrides this method when it 
 needs to pass relevant data to the new view controller. The segue object describes the transition and includes 
 references to both view controllers involved in the segue.
 
 Because segues can be triggered from multiple sources, you can use the information in the segue and sender 
 parameters to disambiguate between different logical paths in your app. For example, if the segue originated 
 from a table view, the sender parameter would identify the table view cell that the user tapped. You could use 
 that information to set the data on the destination view controller.

 @param segue   The segue object containing information about the view controllers involved in the segue.
 @param sender  The object that initiated the segue. You might use this parameter to perform different actions 
                based on which control (or other object) initiated the segue.
 */
- (void)prepareForSegue: (UIStoryboardSegue *)segue
                 sender: (id)sender
{
    DLog();
    
    /*
     See the comment in - configureCell:atIndexPath: to understand how we are using sender.tag with fetchedResultsController

     The sender is one of the buttons in a UICollectionViewCell (not the cell itself). To construct the indexPath
     we use the tag on the UIButton
     */
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow: [(UIButton *)sender tag]
                                                inSection: 0];
    if ([[segue identifier] isEqualToString: kOCRCvrLtrSegue]) {
        Packages *aPackage = [self.fetchedResultsController objectAtIndexPath: indexPath];
        /*
         We want to pass a few data object references to the cover letter controller (discussed
         in more detail below) - so we must first get a reference to the cover letter controller.
         */
        OCRBaseDetailViewController *cvrLtrController;
//        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            /*
             On the iPad, we are getting a UIStoryboardReplaceSegue, so the destinationViewController is a UINavigationController.
             We need to get the detail view controller, which is the first controller in the navigation controller's stack.

             The UINavigationController cast isn't strictly necessary, but helps make the code more self-documenting
             */
            cvrLtrController = [(UINavigationController *)[segue destinationViewController] viewControllers][0];
            /*
             Update the splitViewController's delegate
             */            
            if (_rootPopoverButtonItem != nil) {
                OCRBaseDetailViewController<SubstitutableDetailViewController>* detailViewController = (OCRBaseDetailViewController<SubstitutableDetailViewController>*)[[segue destinationViewController] viewControllers][0];
                [detailViewController showRootPopoverButtonItem:_rootPopoverButtonItem
                                                 withController:_packagesPopoverController];
            }
            
            if (self.packagesPopoverController) {
                [self.packagesPopoverController dismissPopoverAnimated: YES];
            }
//        } else {
//            // On the iPhone, the cover letter controller is the destination of the segue
//            cvrLtrController = [segue destinationViewController];
//        }
        /*
         A common strategy for passing data between controller objects is to declare public properties in the receiving object
         and have the instantiator set those properties.
         
         Here we pass the Package represented by the cell the user tapped, as well as the ManagedObjectContext and 
         FetchedResultsController.
         
         An alternative strategy for data that is global scope by nature is to set those properties on the UIApplication
         delegate and reference them as [[[UIApplication sharedApplication] delegate] foo_bar]. In our case, there is only one
         managedObjectContext used throughout the app, so I reference it as a global variable:
         
            @property (nonatomic, strong, readonly) NSManagedObjectContext  *managedObjectContext;
         
         I also created a macro (see GlobalMacros.h):
         
            #define kAppDelegate    (OCRAppDelegate *)[[UIApplication sharedApplication] delegate]      // Note it DOES NOT end with a ';'
         
         Thus, in other source files [kAppDelegate managedObjectContext] returns a reference to our managedObjectContext
         */
        [cvrLtrController setSelectedManagedObject: aPackage];
        [cvrLtrController setBackButtonTitle: NSLocalizedString(@"Packages", nil)];
        [cvrLtrController setFetchedResultsController: self.fetchedResultsController];
    }
    else if ([[segue identifier] isEqualToString: kOCRResumeSegue]) {
        Packages *aPackage = [self.fetchedResultsController objectAtIndexPath: indexPath];
        /*
         This code follows the same pattern as kOCRCvrLtrSegue above.
         */
        OCRBaseDetailViewController *resumeController;
//        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            // Get a reference to the resume controller
            resumeController = [(UINavigationController *)[segue destinationViewController] viewControllers][0];
            // Update the splitViewController's delegate
            if (_rootPopoverButtonItem != nil) {
                OCRBaseDetailViewController<SubstitutableDetailViewController>* detailViewController = (OCRBaseDetailViewController<SubstitutableDetailViewController>*)[[segue destinationViewController] viewControllers][0];
                [detailViewController showRootPopoverButtonItem: _rootPopoverButtonItem
                                                 withController: _packagesPopoverController];
            }
            
            if (self.packagesPopoverController) {
                [self.packagesPopoverController dismissPopoverAnimated: YES];
            }
//        } else {
//            // On the iPhone, the resume controller is the destination of the segue
//            resumeController = [segue destinationViewController];
//        }
        [resumeController setSelectedManagedObject: aPackage.resume];
        [resumeController setBackButtonTitle: NSLocalizedString(@"Packages", nil)];
        [resumeController setFetchedResultsController: self.fetchedResultsController];
    }
}

#pragma mark - Fetched results controller

//----------------------------------------------------------------------------------------------------------
/**
 Singleton method to retrieve the fetchedResultsController, instantiating it if necessary.
 
 @return    An initialized NSFetchedResultsController.
 */
- (NSFetchedResultsController *)fetchedResultsController
{
    DLog();
    
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    // Create the fetch request for the entity
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity  = [NSEntityDescription entityForName: kOCRPackagesEntity
                                               inManagedObjectContext: [kAppDelegate managedObjectContext]];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number
    [fetchRequest setFetchBatchSize: 25];
    
    // Sort by package sequence_number
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: kOCRSequenceNumberAttributeName
                                                                   ascending: YES];
    NSArray *sortDescriptors = @[sortDescriptor];
    [fetchRequest setSortDescriptors: sortDescriptors];
    
    // Alloc and initialize the controller
    /*
     By setting sectionNameKeyPath to nil, we are stating we want everything in a single section
     */
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest: fetchRequest
                                                                        managedObjectContext: [kAppDelegate managedObjectContext]
                                                                          sectionNameKeyPath: nil
                                                                                   cacheName: @"Root"];
    // Set the delegate to self
    _fetchedResultsController.delegate = self;
    
    // ...and start fetching results
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	     /*
          This is a case where something serious has gone wrong. Let the user know and try to give them some options that might actually help.
          I'm providing my direct contact information in the hope I can help the user and avoid a bad review.
          */
	    ELog(error, @"Unresolved error");
	    [OCAUtilities showErrorWithMessage: NSLocalizedString(@"Could not read the database. Try quitting the app. If that fails, try deleting KOResume and restoring from iCloud or iTunes backup. Please contact the developer by emailing kevin@omaraconsultingassoc.com", nil)];
	}
    
    return _fetchedResultsController;
}    



//----------------------------------------------------------------------------------------------------------
/**
 Loads a fresh copy of fetched results.
 
 This method is called when the underlying data in the persistent store (may have) changed.
 
 @param note    The NSNotification object associated with the event that triggered the need to reload.
 */
- (void)reloadFetchedResults: (NSNotification*)note
{
    DLog();
    
    /*
     Because the app delegate now loads the NSPersistentStore into the NSPersistentStoreCoordinator asynchronously
     the NSManagedObjectContext is set up before any persistent stores are registered we need to fetch again
     after the persistent store is loaded
     */
    
    NSError *error = nil;
    
    if (![[self fetchedResultsController] performFetch: &error]) {
        ELog(error, @"Fetch failed!");
        NSString* msg = NSLocalizedString( @"Failed to reload data after syncing with iCloud.", nil);
        [OCAUtilities showErrorWithMessage: msg];
    }
}

#pragma mark - Fetched results controller delegate

//----------------------------------------------------------------------------------------------------------
/**
 The fetched results controller can "batch" updates to improve performance and preserve battery life.
 
 See http://ashfurrow.com/blog/uicollectionview-example for a tutorial on how this processs works.
 
 @param controller      the NSFetchResultsController
 @param sectionInfo     the sectionInfo for the changed section
 @param sectionIndex    the index of the changed section
 @param type            the NSFetchedResultsChangeType of the change
 */
- (void)controller: (NSFetchedResultsController *)controller
  didChangeSection: (id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex: (NSUInteger)sectionIndex
     forChangeType: (NSFetchedResultsChangeType)type
{
    DLog();
    
    NSMutableDictionary *change = [NSMutableDictionary new];
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            change[@(type)] = @[@(sectionIndex)];
            break;
            
        case NSFetchedResultsChangeDelete:
            change[@(type)] = @[@(sectionIndex)];
            break;
    }
    
    [_sectionChanges addObject: change];
}



//----------------------------------------------------------------------------------------------------------
/**
 Notifies the receiver that a fetched object has been changed due to an add, remove, move, or update.
 
 The fetched results controller reports changes to its section before changes to the fetch result objects.
 
 Changes are reported with the following heuristics:
 * On add and remove operations, only the added/removed object is reported.
   It’s assumed that all objects that come after the affected object are also moved, but these moves are not reported.
 * A move is reported when the changed attribute on the object is one of the sort descriptors used in the fetch request.
   An update of the object is assumed in this case, but no separate update message is sent to the delegate.
 * An update is reported when an object’s state changes, but the changed attributes aren’t part of the sort keys.
 
 This method may be invoked many times during an update event (for example, if you are importing data on a background 
 thread and adding them to the context in a batch). You should consider carefully whether you want to update the table 
 view on receipt of each message.
 
 @param controller      The fetched results controller that sent the message.
 @param anObject        The object in controller’s fetched results that changed.
 @param indexPath       The index path of the changed object (this value is nil for insertions).
 @param type            The type of change. For valid values see “NSFetchedResultsChangeType”.
 @param newIndexPath    The destination path for the object for insertions or moves (this value is nil for a deletion).
 */
- (void)controller: (NSFetchedResultsController *)controller
   didChangeObject: (id)anObject
       atIndexPath: (NSIndexPath *)indexPath
     forChangeType: (NSFetchedResultsChangeType)type
      newIndexPath: (NSIndexPath *)newIndexPath
{
    DLog();
    
    NSMutableDictionary *change = [NSMutableDictionary new];
    switch(type) {
        case NSFetchedResultsChangeInsert:
            change[@(type)] = newIndexPath;
            break;
            
        case NSFetchedResultsChangeDelete:
            change[@(type)] = indexPath;
            break;
            
        case NSFetchedResultsChangeUpdate:
            change[@(type)] = indexPath;
            break;
            
        case NSFetchedResultsChangeMove:
            change[@(type)] = @[indexPath, newIndexPath];
            break;
    }
    
    [_objectChanges addObject:change];
}


//----------------------------------------------------------------------------------------------------------
/*
 Notifies the receiver that the fetched results controller has completed processing of one or more changes 
 due to an add, remove, move, or update.
 
 This method is invoked after all invocations of controller:didChangeObject:atIndexPath:forChangeType:newIndexPath: 
 and controller:didChangeSection:atIndex:forChangeType: have been sent for a given change event (such as the 
 controller receiving a NSManagedObjectContextDidSaveNotification notification).
 
 @param controller      The fetched results controller that sent the message.
 */
- (void)controllerDidChangeContent: (NSFetchedResultsController *)controller
{
    DLog();
    
    /*
     sectionChanges is an array of NSDictionary objects used to batch changes to sections in the fetch results.
     
     In the case of Packages, there is only 1 section so there will never be changes. Implemented for the
     sake of completeness.
     */
    // Check to see if there are section changes
    if ([_sectionChanges count] > 0) {
        // ...yes, we have changes to make
        [self.collectionView performBatchUpdates: ^{
            /*
             performBatchUpdates animates multiple insert, delete, reload, and move operations as a group.
             
             You can use this method in cases where you want to make multiple changes to the collection view in 
             one single animated operation, as opposed to in several separate animations. You might use this method 
             to insert, delete, reload or move cells or use it to change the layout parameters associated with one 
             or more cells. Use the blocked passed in the updates parameter to specify all of the operations you 
             want to perform.
             */
            for (NSDictionary *change in _sectionChanges) {
                // For each change dictionary, iterate through the changes
                [change enumerateKeysAndObjectsUsingBlock: ^(NSNumber *key, id obj, BOOL *stop) {
                    // ...get the type
                    NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                    // ...and perform the insert, delete, or update operation on the collection view
                    switch (type) {
                        case NSFetchedResultsChangeInsert:
                            [self.collectionView insertSections: [NSIndexSet indexSetWithIndex: [obj unsignedIntegerValue]]];
                            break;
                            
                        case NSFetchedResultsChangeDelete:
                            [self.collectionView deleteSections: [NSIndexSet indexSetWithIndex: [obj unsignedIntegerValue]]];
                            break;
                            
                        case NSFetchedResultsChangeUpdate:
                            [self.collectionView reloadSections: [NSIndexSet indexSetWithIndex: [obj unsignedIntegerValue]]];
                            break;
                    }
                }];
            }
        } completion:nil];
    }
    
    /*
     objectChanges is an array of NSDictionary objects used to batch changes to objects in the collection view
     */
    // Check to see if there are object changes -- but sectionChanges, if any, have all been applied
    if ([_objectChanges count] > 0 && [_sectionChanges count] == 0) {
        // ...yes, we have changes to make
        [self.collectionView performBatchUpdates: ^{
            /*
             see the performBatchUpdates comment above
             */
            for (NSDictionary *change in _objectChanges) {
                // For each change dictionary, iterate through the changes
                [change enumerateKeysAndObjectsUsingBlock: ^(NSNumber *key, id obj, BOOL *stop) {
                    // ...get the type
                    NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                    // ...and perform the insert, delete, update, or move operation on the collection view
                    switch (type) {
                        case NSFetchedResultsChangeInsert:
                            [self.collectionView insertItemsAtIndexPaths: @[obj]];
                            break;
                            
                        case NSFetchedResultsChangeDelete:
                            [self.collectionView deleteItemsAtIndexPaths: @[obj]];
                            break;
                            
                        case NSFetchedResultsChangeUpdate:
                            [self.collectionView reloadItemsAtIndexPaths: @[obj]];
                            break;
                            
                        case NSFetchedResultsChangeMove:
                            [self.collectionView moveItemAtIndexPath: obj[0]
                                                         toIndexPath: obj[1]];
                            break;
                    }
                }];
            }
        } completion:nil];
    }
    
    // We processed all the changes, empty the arrays
    [_sectionChanges removeAllObjects];
    [_objectChanges removeAllObjects];
}


@end
