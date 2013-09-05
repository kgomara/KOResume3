//
//  OCRPackagesViewController.m
//  KOResume
//
//  Created by Kevin O'Mara on 7/14/13.
//  Copyright (c) 2013 O'Mara Consulting Associates. All rights reserved.
//

/* Credits:
 
 Akiehl Kahn's "Springboard-like layout with Collection Views" - http://mobile.tutsplus.com/tutorials/iphone/uicollectionview-layouts/
 
 Stan Chang, Khin Boon's "LXReorderableCollectionViewFlowLayout" https://github.com/lxcid/LXReorderableCollectionViewFlowLayout
 */

#import "OCRPackagesViewController.h"
#import "OCRDetailViewController.h"
#import "OCRAppDelegate.h"
#import "OCRCoverLtrViewController.h"
#import "Packages.h"
#import "Resumes.h"
#import <CoreData/CoreData.h>
#import "OCAExtensions.h"
//#import "InfoViewController.h"

#define k_tblHdrHeight      50.0f

#define k_cover_ltrRow      0
#define k_resumeRow         1

@interface OCRPackagesViewController ()
{
@private
    NSMutableArray *_sectionChanges;
    NSMutableArray *_objectChanges;
}

@property (nonatomic, strong) NSString  *packageName;

- (void)promptForPackageName;
- (void)addPackage;
- (void)configureCell:(UICollectionViewCell *)cell
          atIndexPath:(NSIndexPath *)indexPath;
- (void)configureDefaultNavBar;
- (BOOL)saveMoc:(NSManagedObjectContext *)moc;

@end

@implementation OCRPackagesViewController

@synthesize managedObjectContext        = _managedObjectContext;
@synthesize fetchedResultsController    = _fetchedResultsController;

BOOL isEditModeActive;

#pragma mark - View lifecycle

//----------------------------------------------------------------------------------------------------------
- (void)awakeFromNib
{
    DLog();
    
    // Allocate our customer collectionView layout
    OCRReorderableCollectionViewFlowLayout *layout = [[OCRReorderableCollectionViewFlowLayout alloc] init];
    // ...set some parameters to control its behavior
    layout.minimumInteritemSpacing  = 6;
    layout.minimumLineSpacing       = 6;
    layout.scrollDirection          = UICollectionViewScrollDirectionHorizontal;
    layout.sectionInset             = UIEdgeInsetsMake(5, 5, 5, 5);
    
    // Set our layout on the collectionView
    self.collectionView.collectionViewLayout = layout;
    // ...and set the collectionView into paging mode
    self.collectionView.pagingEnabled = YES;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
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
    
    [self.collectionView setTintColor: [UIColor redColor]];
    [(UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout setItemSize: CGSizeMake(150.0f, 150.0f)];
    
    // Observe the app delegate telling us when it's finished asynchronously adding the store coordinator
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(reloadFetchedResults:)
                                                 name: OCRApplicationDidAddPersistentStoreCoordinatorNotification
                                               object: nil];
    
    // ...add an observer for Dynamic Text size changes
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(preferredContentSizeChanged:)
                                                 name:UIContentSizeCategoryDidChangeNotification
                                               object:nil];

    
    // ...add an observer for asynchronous iCloud merges - not used in this version
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(reloadFetchedResults:)
                                                 name: OCRApplicationDidMergeChangesFrom_iCloudNotification
                                               object: nil];
    
    // Push the InfoViewController onto the stack so the user knows we're waiting for the persistentStoreCoordinator
    // to load the database. The user will be able to dismiss it once the coordinator posts an NSNotification
    // indicating we're ready.
//    InfoViewController *infoViewController = [[[InfoViewController alloc] initWithNibName: OCRInfoViewController
//                                                                                   bundle: nil] autorelease];
//    [infoViewController setTitle: NSLocalizedString(@"Loading Database", nil)];
//    [infoViewController.navigationItem setHidesBackButton: YES];
//    [self.navigationController pushViewController: infoViewController
//                                         animated: YES];
    
    // TODO patch up master/detail business
    self.detailViewController = (OCRDetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
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
    
    for (Packages *aPackage in [self.fetchedResultsController fetchedObjects]) {
        [aPackage logAllFields];
    }
    [self reloadFetchedResults: nil];
}


//----------------------------------------------------------------------------------------------------------
- (void)viewWillDisappear:(BOOL)animated
{
    // Save any changes
    DLog();
    
    [self saveMoc: self.managedObjectContext];
}


//----------------------------------------------------------------------------------------------------------
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}


//----------------------------------------------------------------------------------------------------------
- (void)configureDefaultNavBar
{
    DLog();
    // Initialize the buttons
    UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemEdit
                                                                                target: self
                                                                                action: @selector(editButtonTapped)];
    UIBarButtonItem *addButton  = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemAdd
                                                                                target: self
                                                                                action: @selector(promptForPackageName)];
    
    // Set them into the nav bar.
    self.navigationItem.rightBarButtonItem = addButton;
    self.navigationItem.leftBarButtonItem  = editButton;
    
//    [self.collectionView setEditing:NO];
}

#pragma mark - UITextKit handlers

//----------------------------------------------------------------------------------------------------------
- (void)preferredContentSizeChanged:(NSNotification *)aNotification
{
    DLog();
    
    [self.collectionView reloadData];
}


#pragma mark - UI handlers

//----------------------------------------------------------------------------------------------------------
- (void)editButtonTapped
{
    DLog();
//    [self.collectionView setEditing:YES];
    
    // Set up the navigation item and save button
    UIBarButtonItem *doneButton   = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
                                                                                  target: self
                                                                                  action: @selector(doneButtonTapped)];
    UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel
                                                                               target: self
                                                                               action: @selector(cancelButtonTapped)];
    self.navigationItem.leftBarButtonItem  = cancelBtn;
    self.navigationItem.rightBarButtonItem = doneButton;
    
    // Start an undo group...it will either be commited in doneButtonTapped or
    //    undone in cancelButtonTapped
    [[self.managedObjectContext undoManager] beginUndoGrouping];
}


//----------------------------------------------------------------------------------------------------------
- (void)doneButtonTapped
{
    DLog();
    
    // Save the changes
    [[self.managedObjectContext undoManager] endUndoGrouping];
    
    if (![self saveMoc: self.managedObjectContext]) {
        ALog(@"Failed to save data");
        NSString* msg = NSLocalizedString(@"Failed to save data.", nil);
        [OCAExtensions showErrorWithMessage: msg];
    }
    
    // Cleanup the undoManager
    [[self.managedObjectContext undoManager] removeAllActionsWithTarget: self];
    // ...and reset the NavigationBar defaults
    [self configureDefaultNavBar];
    [self.collectionView reloadData];
}


//----------------------------------------------------------------------------------------------------------
- (void)cancelButtonTapped
{
    DLog();
    // Undo any changes the user has made
    [[self.managedObjectContext undoManager] setActionName: OCRUndoActionName];
    [[self.managedObjectContext undoManager] endUndoGrouping];
    
    if ([[self.managedObjectContext undoManager] canUndo]) {
        // Changes were made - discard them
        [[self.managedObjectContext undoManager] undoNestedGroup];
    }
    
    // Cleanup the undoManager
    [[self.managedObjectContext undoManager] removeAllActionsWithTarget: self];
    // ...and reset Packages tableView
    [self configureDefaultNavBar];
    [self.collectionView reloadData];
}


//----------------------------------------------------------------------------------------------------------
- (void)addPackage
{
    DLog();
    Packages *nuPackage = (Packages *)[NSEntityDescription insertNewObjectForEntityForName: OCRPackagesEntity
                                                                    inManagedObjectContext: self.managedObjectContext];
    nuPackage.name                  = self.packageName;
    nuPackage.created_date          = [NSDate date];                    // TODO - need to resequence
    nuPackage.sequence_numberValue  = [[self.fetchedResultsController fetchedObjects] count];
    
    //  Add a Resume for the package
    Resumes *nuResume  = (Resumes *)[NSEntityDescription insertNewObjectForEntityForName: OCRResumesEntity
                                                                  inManagedObjectContext: self.managedObjectContext];
    nuResume.name                 = NSLocalizedString(@"Resume", nil);
    nuResume.created_date         = [NSDate date];
    nuResume.sequence_numberValue = 1;
    nuPackage.resume              = nuResume;
    
    if (![self saveMoc: self.managedObjectContext]) {
        ALog(@"Failed to save");
        NSString* msg = NSLocalizedString(@"Failed to save data.", nil);
        [OCAExtensions showErrorWithMessage: msg];
    }
    
    [self reloadFetchedResults: nil];
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
- (void)coverLtrButtonTapped: (UICollectionViewCell *)aCell
{
    // configureCell:atIndexPath sets the tag on the cell
    DLog(@"tag = %d", aCell.tag);
    
    // Check to see if we're in editMode
    if (isEditModeActive) {
        // ignore the tap
    } else {
        [self performSegueWithIdentifier: OCRCvrLtrSegue
                                  sender: aCell];
    }
}


//----------------------------------------------------------------------------------------------------------
- (void)resumeButtonTapped: (UICollectionViewCell *)aCell
{
    // configureCell:atIndexPath sets the tag on the cell
    DLog(@"button %d", aCell.tag);
    
    // Check to see if we're in editMode
    if (isEditModeActive) {
        // ignore the tap
    } else {
        // perform segue
    }
}


//----------------------------------------------------------------------------------------------------------
- (void)deleteButtonTapped: (UICollectionViewCell *)aCell
{
    // configureCell:atIndexPath sets the tag on the cell
    DLog(@"button %d", aCell.tag);
    
    // We shouldn't get here if we're not editing, but...
    if (isEditModeActive) {
        // TODO implement an alertview for confirmation before actually deleting
//    NSIndexPath *indexPath = [self.collectionView indexPathForCell: (OCRPackagesCell *)aCell.superview.superview];
//    [self.collectionView deleteItemsAtIndexPaths: [NSArray arrayWithObject: indexPath]];
    } else {
        ALog(@"[ERROR] delete button tapped while editMode false");
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
    
    OCRPackagesCell *cell = (OCRPackagesCell *)[collectionView dequeueReusableCellWithReuseIdentifier: OCRPackagesCellID
                                                                                         forIndexPath: indexPath];
    
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
     Set the tag for the cell to the index of the Packages object.
     The tag property is often used carry identifying information for later use, in our case, we'll use it in the
     button handling routines to know which cover_ltr or resume to segue to.
     */
    cell.tag        = indexPath.row;
    cell.delegate   = self;

    cell.title.text = aPackage.name;
    [cell.resumeButton setTitle: aPackage.resume.name
                       forState: UIControlStateSelected];
    [cell.resumeButton setTitleColor: [UIColor redColor]
                            forState: UIControlStateSelected];
    [cell.resumeButton setTitle: aPackage.resume.name
                       forState: UIControlStateNormal];
    [cell.coverLtrButton setTitleColor: [UIColor redColor]
                              forState: UIControlStateSelected];
    if (isEditModeActive) {
        [cell.deleteButton setHidden: NO];
    } else {
        [cell.deleteButton setHidden: YES];
    }
}

#pragma mark - UICollectionView delegates

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
    
    [self doneButtonTapped];
}


//----------------------------------------------------------------------------------------------------------
- (BOOL)            collectionView:(UICollectionView *)collectionView
  shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath
{
    DLog();
    
    return YES;
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
    DLog(@"Don't think this should be called");
    
    /*
     As above, the cells handle all the action, given we return NO above - this method should never be called.
     */
}

#pragma mark - OCRReorderableCollectionViewDelegateFlowLayout methods

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
}


//----------------------------------------------------------------------------------------------------------
- (void)        collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout *)collectionViewLayout
willEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath
{
    DLog(@"will end drag");
}


//----------------------------------------------------------------------------------------------------------
- (void)        collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout *)collectionViewLayout
 didEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath
{
    DLog(@"did end drag");
}


#pragma mark - Seque handling

//----------------------------------------------------------------------------------------------------------
- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender
{
    if ([[segue identifier] isEqualToString: OCRCvrLtrSegue]) {
        /*
         See the comment in - configureCell:atIndexPath: to understand how we are using sender.tag with fetchedResultsController
         */
        Packages *aPackage = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow: [(UICollectionViewCell *)sender tag]
                                                                                                 inSection: 0]];
        /*
         A common strategy for passing data between controller objects is to declare public properties in the receiving object
         and have the instantiator set those properties.
         Here we pass the Package represented by the cell the user tapped, as well as the ManagedObjectContext and FetchedResultsController
         
         An alternative strategy for data that is global scope by nature would be to set those properties on the UIApplication
         delegate and reference them as [[[UIApplication sharedApplication] delegate] foo_bar]. In our case, that's perfectly OK for
         ManagedObjectContext and FetchedResultsController, but probably not for the selected Package.
         
         My preference is to minimize globals, hence I pass all three references here.
         */
        [[segue destinationViewController] setSelectedPackage:aPackage];
        [[segue destinationViewController] setManagedObjectContext: self.managedObjectContext];
        [[segue destinationViewController] setFetchedResultsController: self.fetchedResultsController];
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
    NSEntityDescription *entity  = [NSEntityDescription entityForName: OCRPackagesEntity
                                               inManagedObjectContext: self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number
    [fetchRequest setFetchBatchSize: 25];
    
    // Sort by package sequence_number
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: OCRSequenceNumberAttributeName
                                                                   ascending: YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects: sortDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Alloc and initialize the controller
    /*
     By setting sectionNameKeyPath to nil, we are stating we want everything in a single section
     */
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest: fetchRequest
                                                                                               managedObjectContext: self.managedObjectContext
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
	    [OCAExtensions showErrorWithMessage: NSLocalizedString(@"Could not read the database. Try quitting the app. If that fails, try deleting KOResume and restoring from iCould or iTunes backup. Please contact the developer by emailing kevin@omaraconsultingassoc.com", nil)];
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
        [OCAExtensions showErrorWithMessage: msg];
    }
    
    [self.collectionView reloadData];
}

#pragma mark - Fetched results controller delegate

// TODO need to throughly comment this section

//----------------------------------------------------------------------------------------------------------
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    DLog();
    
//    [self.collectionView beginUpdates];
}


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
