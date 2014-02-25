//
//  OCRPackagesViewController.m
//  KOResume
//
//  Created by Kevin O'Mara on 7/14/13.
//  Copyright (c) 2013 O'Mara Consulting Associates. All rights reserved.
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
 The UIViewController manages Packages objects
 
 It uses a UICollectionView to display the list of Packages, and dispatches OCRCoverLtrViewController or OCRResumeViewController.
 
 Credits:
 
 Akiehl Kahn's "Springboard-like layout with Collection Views" - http://mobile.tutsplus.com/tutorials/iphone/uicollectionview-layouts/
 
 Stan Chang, Khin Boon's "LXReorderableCollectionViewFlowLayout" https://github.com/lxcid/LXReorderableCollectionViewFlowLayout
 */

#define k_tblHdrHeight      50.0f

#define k_cover_ltrRow      0
#define k_resumeRow         1

// TODO - implement UITextkit resizing and -collectionView: layout: sizeForItemAtIndexPath:

@interface OCRPackagesViewController ()
{
@private
    /**
     
     */
    NSMutableArray *_sectionChanges;
    NSMutableArray *_objectChanges;
}

/**
 
 */
@property (nonatomic, strong) NSString                      *packageName;
@property (nonatomic, strong) UIPopoverController           *packagesPopoverController;
@property (nonatomic, strong) UIBarButtonItem               *rootPopoverButtonItem;

@property (nonatomic, strong) NSFetchedResultsController    *fetchedResultsController;



- (void)promptForPackageName;
- (void)addPackage;
- (void)configureCell:(UICollectionViewCell *)cell
          atIndexPath:(NSIndexPath *)indexPath;
- (void)configureDefaultNavBar;
- (BOOL)saveMoc:(NSManagedObjectContext *)moc;

@end

@implementation OCRPackagesViewController

@synthesize packagesPopoverController = _packagesPopoverController;

BOOL isEditModeActive;

#pragma mark - View lifecycle

//----------------------------------------------------------------------------------------------------------
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
//    [layout setItemSize: CGSizeMake(kPackagesCellWidth, kPackagesCellHeight)];
    
    // Set our layout on the collectionView
    self.collectionView.collectionViewLayout = layout;
    // ...and set the collectionView into paging mode
    self.collectionView.pagingEnabled = YES;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear    = NO;
        self.preferredContentSize               = CGSizeMake(320.0, 600.0);
    }
    
    [super awakeFromNib];
}

//----------------------------------------------------------------------------------------------------------
- (void)viewDidLoad
{
    DLog();
    [super viewDidLoad];
    
    // Set the App name as the Title in the Navigation bar
    NSString *title = NSLocalizedString(@"Packages", nil);
#ifdef DEBUG
    // Include the version in the title for debug builds
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleVersion"];
    self.navigationItem.title = [NSString stringWithFormat:@"%@-%@", title, version];
#else
    self.navigationItem.title = title;
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
- (void)viewDidUnload
{
    DLog();
    [super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}


//----------------------------------------------------------------------------------------------------------
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
    ALog();
}


//----------------------------------------------------------------------------------------------------------
- (void)viewWillAppear:(BOOL)animated
{
    DLog();
    
    [self.navigationItem setHidesBackButton: NO];
    self.fetchedResultsController.delegate = self;
    
    // Observe the app delegate telling us when it's finished asynchronously adding the store coordinator
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(reloadFetchedResults:)
                                                 name: kOCRApplicationDidAddPersistentStoreCoordinatorNotification
                                               object: nil];
    
    // ...add an observer for Dynamic Text size changes
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userTextSizeDidChange:)
                                                 name:UIContentSizeCategoryDidChangeNotification
                                               object:nil];
    
    
    // ...add an observer for asynchronous iCloud merges - not used in this version
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(reloadFetchedResults:)
                                                 name: kOCRApplicationDidMergeChangesFrom_iCloudNotification
                                               object: nil];
    
    for (Packages *aPackage in [self.fetchedResultsController fetchedObjects]) {
        DLog(@"%@", [aPackage debugDescription]);
    }
    [self reloadFetchedResults: nil];
}


//----------------------------------------------------------------------------------------------------------
- (void)viewWillDisappear:(BOOL)animated
{
    // Save any changes
    DLog();
    
    [self saveMoc: self.managedObjectContext];
    
    // Remove ourself from observing notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


//----------------------------------------------------------------------------------------------------------
- (BOOL)shouldAutorotate
{
    return YES;
}

//----------------------------------------------------------------------------------------------------------
- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}


//----------------------------------------------------------------------------------------------------------
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
- (void)userTextSizeDidChange:(NSNotification *)aNotification
{
    DLog();
    
    [self.collectionView reloadData];
}


#pragma mark - UI handlers

//----------------------------------------------------------------------------------------------------------
- (void)addPackage
{
    DLog();
    Packages *nuPackage = (Packages *)[NSEntityDescription insertNewObjectForEntityForName: kOCRPackagesEntity
                                                                    inManagedObjectContext: [kAppDelegate managedObjectContext]];
    nuPackage.name                  = self.packageName;
    nuPackage.created_date          = [NSDate date];                    // TODO - need to resequence
    nuPackage.sequence_numberValue  = [[self.fetchedResultsController fetchedObjects] count];
    
    //  Add a Resume for the package
    Resumes *nuResume  = (Resumes *)[NSEntityDescription insertNewObjectForEntityForName: kOCRResumesEntity
                                                                  inManagedObjectContext: [kAppDelegate managedObjectContext]];
    nuResume.name                 = NSLocalizedString(@"Resume", nil);
    nuResume.created_date         = [NSDate date];
    nuResume.sequence_numberValue = 1;
    nuPackage.resume              = nuResume;
    
    [kAppDelegate saveContextAndWait: [kAppDelegate managedObjectContext]];
        
    [self reloadFetchedResults: nil];
    [self.collectionView reloadData];
}


//----------------------------------------------------------------------------------------------------------
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
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    DLog();
    if (buttonIndex == 1) {
        // OK
        self.packageName = [[alertView textFieldAtIndex: 0] text];
        [self addPackage];
    } else {
        // User cancelled
        [self configureDefaultNavBar];
    }
}

#pragma mark - OCRPackagesCellDelegate methods

//----------------------------------------------------------------------------------------------------------
- (IBAction)coverLtrButtonTapped: (id)sender
{
    // configureCell:atIndexPath sets the tag on the button
    DLog(@"sender = %d", [(UIButton *)sender tag]);
    
    // Check to see if we're in editMode
    if (isEditModeActive) {
        // ignore the tap
    } else {
        [self performSegueWithIdentifier: kOCRCvrLtrSegue
                                  sender: sender];
    }
}


//----------------------------------------------------------------------------------------------------------
- (IBAction)resumeButtonTapped: (id)sender
{
    // configureCell:atIndexPath sets the tag on the button
    DLog(@"sender = %d", [(UIButton *)sender tag]);
    
    // Check to see if we're in editMode
    if (isEditModeActive) {
        // ignore the tap
    } else {
        [self performSegueWithIdentifier: kOCRResumeSegue
                                  sender: sender];
    }
}

#pragma mark - UICollectionView data source

//----------------------------------------------------------------------------------------------------------
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    /*
     We are hardcoding to 1 here because we want a single section containing all the packages.
     */
    return 1;
}


//----------------------------------------------------------------------------------------------------------
- (NSInteger)collectionView: (UICollectionView *)collectionView
     numberOfItemsInSection: (NSInteger)section
{
    DLog(@"section=%d", [[self.fetchedResultsController sections] count]);
    
    /*
     In our case, we only want a single section, so our fetchedResultsController is set up to retrieve everything
     in one section, and we just return the number of objects in section[0]
     */
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:0];
    NSUInteger rows = [sectionInfo numberOfObjects];
    DLog(@"rows=%d", rows);

    return rows;
}



//----------------------------------------------------------------------------------------------------------
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
- (void)configureCell: (OCRPackagesCell *)cell
          atIndexPath: (NSIndexPath *)indexPath
{
    DLog(@"%@", indexPath.debugDescription);
    
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:indexPath.section];
    Packages *aPackage  = (Packages *) [sectionInfo.objects objectAtIndex: indexPath.row];
    /*
     Set the tag for the cell and its buttons to the index of the Packages object.
     The tag property is often used to carry identifying information for later use, in our case, we'll use it in the
     button handling routines to know which cover_ltr or resume to segue to.
     */
    cell.tag                = indexPath.row;
    cell.coverLtrButton.tag = indexPath.row;
    cell.resumeButton.tag   = indexPath.row;

    cell.title.text = aPackage.name;
    
    // Set the title
    [cell.resumeButton setTitle: aPackage.resume.name
                       forState: UIControlStateNormal];
    // ...give it a different color when selected
    [cell.resumeButton setTitleColor: [UIColor greenColor]
                            forState: UIControlStateSelected];
    // ...and add us as target for the cell's resume button
    [cell.resumeButton addTarget: self
                          action: @selector(resumeButtonTapped:)
                forControlEvents: UIControlEventTouchUpInside];
    
    // Cover letters don't have a specific name attribute, so just
    // ...give it a different color when selected
    [cell.coverLtrButton setTitleColor: [UIColor greenColor]
                              forState: UIControlStateSelected];
    // ...and add us as target for the cell's resume button
    [cell.coverLtrButton addTarget: self
                            action: @selector(coverLtrButtonTapped:)
                  forControlEvents: UIControlEventTouchUpInside];
}


//----------------------------------------------------------------------------------------------------------
- (void)        collectionView: (UICollectionView *)collectionView
   didHighlightItemAtIndexPath: (NSIndexPath *)indexPath
{
    DLog();
    
}


//----------------------------------------------------------------------------------------------------------
- (void)        collectionView: (UICollectionView *)collectionView
 didUnhighlightItemAtIndexPath: (NSIndexPath *)indexPath
{
    DLog();
    
}


#pragma mark - UICollectionView delegates

//----------------------------------------------------------------------------------------------------------
- (BOOL)            collectionView:(UICollectionView *)collectionView
  shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath
{
    DLog();
    
    return NO;
}


//----------------------------------------------------------------------------------------------------------
- (BOOL)collectionView:(UICollectionView *)collectionView
      canPerformAction:(SEL)action
    forItemAtIndexPath:(NSIndexPath *)indexPath
            withSender:(id)sender
{
    DLog(@"action=%@", NSStringFromSelector(action));
    
    return NO;
}


//----------------------------------------------------------------------------------------------------------
- (BOOL)        collectionView:(UICollectionView *)collectionView
   shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    /*
     We want the buttons in the collectionView cells to perform all the actions, so we return NO.
     */
    DLog();
    
    if (isEditModeActive) {
        return NO;
    } else {
        return YES;
    }
}

//----------------------------------------------------------------------------------------------------------
- (void)   collectionView: (UICollectionView *)collectionView
 didSelectItemAtIndexPath: (NSIndexPath *)indexPath
{
    DLog();
}

#pragma mark - OCAEditableCollectionViewDelegateFlowLayout methods

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize result;

    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:indexPath.section];
    Packages *aPackage  = (Packages *) [sectionInfo.objects objectAtIndex: indexPath.row];
    NSString *stringToSize  = aPackage.name;
	CGRect titleRect        = [stringToSize boundingRectWithSize:CGSizeMake(280.0f, 100.0f)
                                                         options:NSStringDrawingUsesLineFragmentOrigin
                                                      attributes:@{NSFontAttributeName: [UIFont preferredFontForTextStyle:[OCRPackagesCell titleFont]]}
                                                         context:nil];
    stringToSize            = NSLocalizedString(@"Cover Letter", nil);
	CGRect coverLtrRect     = [stringToSize boundingRectWithSize:CGSizeMake(280.0f, 100.0f)
                                                         options:NSStringDrawingUsesLineFragmentOrigin
                                                      attributes:@{NSFontAttributeName: [UIFont preferredFontForTextStyle:[OCRPackagesCell detailFont]]}
                                                         context:nil];
    stringToSize            = NSLocalizedString(@"Resume", nil);
	CGRect resumeRect       = [stringToSize boundingRectWithSize:CGSizeMake(280.0f, 100.0f)
                                                         options:NSStringDrawingUsesLineFragmentOrigin
                                                      attributes:@{NSFontAttributeName: [UIFont preferredFontForTextStyle:[OCRPackagesCell detailFont]]}
                                                         context:nil];
    result.height       = titleRect.size.height + coverLtrRect.size.height + resumeRect.size.height + 50.0f;
    CGFloat cellWidth   = MAX(titleRect.size.width, coverLtrRect.size.width);
    cellWidth           = MAX(resumeRect.size.width, cellWidth);
    result.width        = MIN(cellWidth + 20.0f, 280.0f);
    
	return result;
}

//----------------------------------------------------------------------------------------------------------
- (void) didBeginEditingForCollectionView: (UICollectionView *)collectionView
                                   layout: (UICollectionViewLayout*)collectionViewLayout
{
    DLog();
    
    isEditModeActive = YES;
}


//----------------------------------------------------------------------------------------------------------
- (void) didEndEditingForCollectionView: (UICollectionView *)collectionView
                                 layout: (UICollectionViewLayout*)collectionViewLayout
{
    DLog();
    
    isEditModeActive = NO;

    [self resequencePackages];
    [self saveMoc: _managedObjectContext];
}


//----------------------------------------------------------------------------------------------------------
- (void)            collectionView: (UICollectionView *)collectionView
                            layout: (UICollectionViewLayout *)collectionViewLayout
  willBeginDraggingItemAtIndexPath: (NSIndexPath *)indexPath
{
    DLog(@"will begin drag");
}


//----------------------------------------------------------------------------------------------------------
- (void)            collectionView: (UICollectionView *)collectionView
                            layout: (UICollectionViewLayout *)collectionViewLayout
   didBeginDraggingItemAtIndexPath: (NSIndexPath *)indexPath
{
    DLog(@"did begin drag");
    
    [self performSelector: @selector(invalidateLayout:)
               withObject: collectionViewLayout
               afterDelay: 0.1f];
}


//----------------------------------------------------------------------------------------------------------
- (void)        collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout *)collectionViewLayout
 didEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath
{
    DLog(@"did end drag");
    
    [self performSelector: @selector(invalidateLayout:)
               withObject: collectionViewLayout
               afterDelay: 0.1f];
}


//----------------------------------------------------------------------------------------------------------
- (void)invalidateLayout: (UICollectionViewLayout *)collectionViewLayout
{
    [self.collectionViewLayout invalidateLayout];
}


//----------------------------------------------------------------------------------------------------------
- (void)        collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout *)collectionViewLayout
willEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath
{
    DLog(@"will end drag");
}


//----------------------------------------------------------------------------------------------------------
- (BOOL)shouldEnableEditingForCollectionView:(UICollectionView *)collectionView
                                      layout:(UICollectionViewLayout *)collectionViewLayout
{
    return YES;
}

#pragma mark - OCAEditableCollectionViewDataSource methods

//----------------------------------------------------------------------------------------------------------
- (BOOL)collectionView:(UICollectionView *)collectionView
canMoveItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}


//----------------------------------------------------------------------------------------------------------
- (BOOL)collectionView: (UICollectionView *)collectionView
       itemAtIndexPath: (NSIndexPath *)fromIndexPath
    canMoveToIndexPath: (NSIndexPath *)toIndexPath
{
    DLog();
    
    return YES;
}


//----------------------------------------------------------------------------------------------------------
- (void)collectionView: (UICollectionView *)collectionView
       itemAtIndexPath: (NSIndexPath *)fromIndexPath
   willMoveToIndexPath: (NSIndexPath *)toIndexPath
{
    DLog();
}


//----------------------------------------------------------------------------------------------------------
- (void)collectionView: (UICollectionView *)collectionView
       itemAtIndexPath: (NSIndexPath *)fromIndexPath
    didMoveToIndexPath: (NSIndexPath *)toIndexPath;
{
    DLog();
    
    [self moveItemAtIndexPath: fromIndexPath
                  toIndexPath: toIndexPath];
}

//----------------------------------------------------------------------------------------------------------
- (BOOL)    collectionView:(UICollectionView *)collectionView
  canDeleteItemAtIndexPath:(NSIndexPath *)indexPath
{
    DLog();
    
    return YES;
}


//----------------------------------------------------------------------------------------------------------
- (void)    collectionView:(UICollectionView *)collectionView
 willDeleteItemAtIndexPath:(NSIndexPath *)indexPath
{
    DLog();
    
    // Get the package that is that is about to be deleted from the collectionView
    Packages *packageToDelete   = [self.fetchedResultsController objectAtIndexPath:indexPath];
    // ...and the managed object context
    NSManagedObjectContext *moc = [self.fetchedResultsController managedObjectContext];
    // ...and delete it from the data model
    [moc deleteObject:packageToDelete];
    
    /*
     Here we save the context and wait for the operation to complete. If we invoked the asynchronous saveContext
     method it would return immediately and the collectionView throw an assertion error because the collectionView
     would be out of sync with the data model.
     */
    [kAppDelegate saveContextAndWait:moc];
}


//----------------------------------------------------------------------------------------------------------
- (void)    collectionView:(UICollectionView *)collectionView
  didDeleteItemAtIndexPath:(NSIndexPath *)indexPath
{
    DLog();
}

#pragma mark - UISplitViewControllerDelegate methods

//----------------------------------------------------------------------------------------------------------
- (BOOL)splitViewController:(UISplitViewController *)svc
   shouldHideViewController:(UIViewController *)vc
              inOrientation:(UIInterfaceOrientation)orientation
{
    if (UIInterfaceOrientationIsPortrait(orientation))
        return YES; // if you return NO, it will display side by side, not above.
    return NO;
}

//----------------------------------------------------------------------------------------------------------
- (void)splitViewController:(UISplitViewController*)aSplitViewController
     willHideViewController:(UIViewController *)aViewController
          withBarButtonItem:(UIBarButtonItem*)aBarButtonItem
       forPopoverController:(UIPopoverController*)aPopoverController
{
    DLog();
    
    // Keep references to the popover controller and the popover button, and tell the detail view controller to show the button.
    aBarButtonItem.title            = @"Packages";
    self.packagesPopoverController  = aPopoverController;
    self.rootPopoverButtonItem      = aBarButtonItem;
    
    OCRBaseDetailViewController <SubstitutableDetailViewController> *detailViewController = (OCRBaseDetailViewController<SubstitutableDetailViewController>*)[[aSplitViewController.viewControllers objectAtIndex:1] topViewController];
    [detailViewController showRootPopoverButtonItem:_rootPopoverButtonItem
                                     withController:aPopoverController];
}


//----------------------------------------------------------------------------------------------------------
- (void)splitViewController:(UISplitViewController*)aSplitViewController
     willShowViewController:(UIViewController *)aViewController
  invalidatingBarButtonItem:(UIBarButtonItem *)aBarButtonItem
{
    DLog();
    
    // Nil out references to the popover controller and the popover button, and tell the detail view controller to hide the button.
    OCRBaseDetailViewController <SubstitutableDetailViewController> *detailViewController = (OCRBaseDetailViewController<SubstitutableDetailViewController>*)[[aSplitViewController.viewControllers objectAtIndex:1] topViewController];
    [detailViewController invalidateRootPopoverButtonItem:_rootPopoverButtonItem];
    self.packagesPopoverController  = nil;
    self.rootPopoverButtonItem      = nil;
}


#pragma mark - Private methods

//----------------------------------------------------------------------------------------------------------
- (void)resequencePackages
{
    DLog();
    
    NSArray *packages = [self.fetchedResultsController fetchedObjects];
    
    NSInteger sectionCount = [self.collectionView numberOfSections];
    NSIndexPath *indexPath;
    OCRPackagesCell *packagesCell;
    Packages *aPackage;
    
    int i = 1;
    for (NSInteger section = 0; section < sectionCount; section++) {
        NSInteger itemCount = [self.collectionView numberOfItemsInSection: section];
        for (NSInteger item = 0; item < itemCount; item++) {
            indexPath       = [NSIndexPath indexPathForItem: item
                                                  inSection: section];
            packagesCell    = (OCRPackagesCell *)[self.collectionView cellForItemAtIndexPath: indexPath];

            DLog(@"indexPath=%@, tag=%d", indexPath, packagesCell.tag);
            aPackage = [packages objectAtIndex: packagesCell.tag];
            [aPackage setSequence_number: [NSNumber numberWithInt: i++]];       // TODO - sequence number does not seem to stick
            DLog(@"%@", [aPackage debugDescription]);
        }
    }
}


//----------------------------------------------------------------------------------------------------------
- (void)moveItemAtIndexPath:(NSIndexPath *)indexPath
                toIndexPath:(NSIndexPath *)newIndexPath
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
- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender
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
         
         The segue differs between iPad and iPhone.
         On iPad, the detail view is governed by its own navigation controller, and the segue is replacing
         the navigation controller.
         OniPhone, the segue is a relationship segue.
         */
        OCRBaseDetailViewController *cvrLtrController;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            /*
             On the iPad, we are getting a UIStoryboardReplaceSegue, so the destinationViewController is a UINavigationController.
             We need to get the detail view controller, which is the first controller in the navigation controller's stack.

             The UINavigationController cast isn't strictly necessary, but helps make the code more self-documenting
             */
            cvrLtrController = [[(UINavigationController *)[segue destinationViewController] viewControllers] objectAtIndex: 0];
            /*
             Update the splitViewController's delegate
             */            
            if (_rootPopoverButtonItem != nil) {
                OCRBaseDetailViewController<SubstitutableDetailViewController>* detailViewController = (OCRBaseDetailViewController<SubstitutableDetailViewController>*)[[[segue destinationViewController] viewControllers] objectAtIndex:0];
                [detailViewController showRootPopoverButtonItem:_rootPopoverButtonItem
                                                 withController:_packagesPopoverController];
            }
            
            if (self.packagesPopoverController) {
                [self.packagesPopoverController dismissPopoverAnimated:YES];
            }
        } else {
            // On the iPhone, the cover letter controller is the destination of the segue
            cvrLtrController = [segue destinationViewController];
        }
        /*
         A common strategy for passing data between controller objects is to declare public properties in the receiving object
         and have the instantiator set those properties.
         Here we pass the Package represented by the cell the user tapped, as well as the ManagedObjectContext and FetchedResultsController
         
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
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            // Get a reference to the resume controller
            resumeController = [[(UINavigationController *)[segue destinationViewController] viewControllers] objectAtIndex: 0];
            // Update the splitViewController's delegate
            if (_rootPopoverButtonItem != nil) {
                OCRBaseDetailViewController<SubstitutableDetailViewController>* detailViewController = (OCRBaseDetailViewController<SubstitutableDetailViewController>*)[[[segue destinationViewController] viewControllers] objectAtIndex:0];
                [detailViewController showRootPopoverButtonItem:_rootPopoverButtonItem
                                                 withController:_packagesPopoverController];
            }
            
            if (self.packagesPopoverController) {
                [self.packagesPopoverController dismissPopoverAnimated:YES];
            }
        } else {
            // On the iPhone, the resume controller is the destination of the segue
            resumeController = [segue destinationViewController];
        }
        [resumeController setSelectedManagedObject: aPackage.resume];
        [resumeController setBackButtonTitle: NSLocalizedString(@"Packages", nil)];
        [resumeController setFetchedResultsController: self.fetchedResultsController];
    }
}

#pragma mark - Fetched results controller

//----------------------------------------------------------------------------------------------------------
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
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects: sortDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Alloc and initialize the controller
    /*
     By setting sectionNameKeyPath to nil, we are stating we want everything in a single section
     */
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest: fetchRequest
                                                                                               managedObjectContext: [kAppDelegate managedObjectContext]
                                                                                                 sectionNameKeyPath: nil
                                                                                                          cacheName: @"Root"];
    // Set the delegate as self
    fetchedResultsController.delegate = self;
    
    // Save the just created fetchedResultsController as a property of our class
    self.fetchedResultsController = fetchedResultsController;
    
    // ...and start fetching results
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	     /*
          This is a case where something serious has gone wrong. Let the user know and try to give them some options that might actually help.
          I'm providing my direct contact information in the hope I can help the user and avoid a bad review.
          */
	    ELog(error, @"Unresolved error");
	    [OCAUtilities showErrorWithMessage: NSLocalizedString(@"Could not read the database. Try quitting the app. If that fails, try deleting KOResume and restoring from iCould or iTunes backup. Please contact the developer by emailing kevin@omaraconsultingassoc.com", nil)];
	}
    
    return _fetchedResultsController;
}    



//----------------------------------------------------------------------------------------------------------
- (void)reloadFetchedResults:(NSNotification*)note
{
    DLog();
    
    // because the app delegate now loads the NSPersistentStore into the NSPersistentStoreCoordinator asynchronously
    // the NSManagedObjectContext is set up before any persistent stores are registered
    // we need to fetch again after the persistent store is loaded
    
    NSError *error = nil;
    
    if (![[self fetchedResultsController] performFetch: &error]) {
        ELog(error, @"Fetch failed!");
        NSString* msg = NSLocalizedString( @"Failed to reload data after syncing with iCloud.", nil);
        [OCAUtilities showErrorWithMessage: msg];
    }
    DLog(@"reloadingData");
//    [self.collectionView reloadData];
}

#pragma mark - Fetched results controller delegate

// TODO need to throughly comment this section

/**
 The fetched results controller can "batch" updates to improve performance and preserve battery life.
 
 See http://ashfurrow.com/blog/uicollectionview-example for a tutorial on how this processs works.
 
 @param controller      the NSFetchResultsController
 @param sectionInfo     the sectionInfo for the changed section
 @param sectionIndex    the index of the changed section
 @param type            the NSFetchedResultsChangeType of the change
 */

//----------------------------------------------------------------------------------------------------------
- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
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
    
    [_sectionChanges addObject:change];
}



//----------------------------------------------------------------------------------------------------------
- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
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
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    DLog();
    
    
    if ([_sectionChanges count] > 0) {
        [self.collectionView performBatchUpdates: ^{
            
            for (NSDictionary *change in _sectionChanges) {
                [change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {
                    
                    NSFetchedResultsChangeType type = [key unsignedIntegerValue];
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
    
    if ([_objectChanges count] > 0 && [_sectionChanges count] == 0) {
        [self.collectionView performBatchUpdates: ^{
            
            for (NSDictionary *change in _objectChanges) {
                [change enumerateKeysAndObjectsUsingBlock: ^(NSNumber *key, id obj, BOOL *stop) {
                    
                    NSFetchedResultsChangeType type = [key unsignedIntegerValue];
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
    
    [_sectionChanges removeAllObjects];
    [_objectChanges removeAllObjects];
}

//----------------------------------------------------------------------------------------------------------
- (BOOL)saveMoc:(NSManagedObjectContext *)moc
{
    DLog();
    
    BOOL result = YES;
    NSError *error = nil;
    
    if (moc) {
        if ([moc hasChanges]) {
            if (![moc save: &error]) {
                ELog(error, @"Failed to save");
                result = NO;
            } else {
                DLog(@"Save successful");
            }
        } else {
            DLog(@"No changes to save");
        }
    } else {
        ALog(@"managedObjectContext is null");
        result = NO;
    }
    
    return result;
}


@end
