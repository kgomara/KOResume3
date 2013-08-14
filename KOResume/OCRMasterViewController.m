//
//  OCRMasterViewController.m
//  KOResume
//
//  Created by Kevin O'Mara on 7/14/13.
//  Copyright (c) 2013 O'Mara Consulting Associates. All rights reserved.
//

#import "OCRMasterViewController.h"
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

@interface OCRMasterViewController ()
{
@private
    NSString                    *_packageName;
}

@property (nonatomic, strong) NSString                      *packageName;

- (void)promptForPackageName;
- (void)addPackage;
- (void)configureCell:(UICollectionViewCell *)cell
          atIndexPath:(NSIndexPath *)indexPath;
- (void)configureDefaultNavBar;
- (BOOL)saveMoc:(NSManagedObjectContext *)moc;

@end

@implementation OCRMasterViewController

@synthesize managedObjectContext        = _managedObjectContext;
@synthesize fetchedResultsController    = _fetchedResultsController;

#pragma mark - View lifecycle

//----------------------------------------------------------------------------------------------------------
- (void)awakeFromNib
{
    DLog();
    
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
    
    // Observe the app delegate telling us when it's finished asynchronously adding the store coordinator
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(reloadFetchedResults:)
                                                 name: KOApplicationDidAddPersistentStoreCoordinatorNotification
                                               object: nil];
    
    // ...add an observer for Dynamic Text size changes
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(preferredContentSizeChanged:)
                                                 name:UIContentSizeCategoryDidChangeNotification
                                               object:nil];

    
    // ...add an observer for asynchronous iCloud merges - not used in this version
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(reloadFetchedResults:)
                                                 name: KOApplicationDidMergeChangesFrom_iCloudNotification
                                               object: nil];
    
    // Push the InfoViewController onto the stack so the user knows we're waiting for the persistentStoreCoordinator
    // to load the database. The user will be able to dismiss it once the coordinator posts an NSNotification
    // indicating we're ready.
//    InfoViewController *infoViewController = [[[InfoViewController alloc] initWithNibName: KOInfoViewController
//                                                                                   bundle: nil] autorelease];
//    [infoViewController setTitle: NSLocalizedString(@"Loading Database", nil)];
//    [infoViewController.navigationItem setHidesBackButton: YES];
//    [self.navigationController pushViewController: infoViewController
//                                         animated: YES];
    
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
//    static const CGFloat cellTitleTextScaleFactor = .85;
//    static const CGFloat cellBodyTextScaleFactor = .7;
//    
//    NSString *cellTitleTextStyle = [self.navigationItem.titleView OCATextStyle];
//    UIFont *cellTitleFont = [UIFont tkd_preferredFontWithTextStyle:cellTitleTextStyle scale:cellTitleTextScaleFactor];
//    
//    NSString *cellBodyTextStyle = [aCell.bodyTextView tkd_textStyle];
//    UIFont *cellBodyFont = [UIFont tkd_preferredFontWithTextStyle:cellBodyTextStyle scale:cellBodyTextScaleFactor];
//    
//    aCell.titleLabel.font = cellTitleFont;
//    aCell.bodyTextView.font = cellBodyFont;
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
    [[self.managedObjectContext undoManager] setActionName: KOUndoActionName];
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
    Packages *nuPackage = (Packages *)[NSEntityDescription insertNewObjectForEntityForName: KOPackagesEntity
                                                                    inManagedObjectContext: self.managedObjectContext];
    nuPackage.name                  = self.packageName;
    nuPackage.created_date          = [NSDate date];                    // TODO - need to resequence
    nuPackage.sequence_numberValue  = [[self.fetchedResultsController fetchedObjects] count];
    
    //  Add a Resume for the package
    Resumes *nuResume  = (Resumes *)[NSEntityDescription insertNewObjectForEntityForName: KOResumesEntity
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
    
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName: @"Main_iPhone"
                                                             bundle: nil];

    OCRCoverLtrViewController *coverLtrViewController = [mainStoryboard instantiateViewControllerWithIdentifier: OCACoverLtrID];
    
    /*
     See the comment in - configureCell:atIndexPath: to understand how we are using sender.tag with fetchedResultsController
     */
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex: aCell.tag];
    Packages *aPackage  = (Packages *) [sectionInfo.objects objectAtIndex:0];
    
    [coverLtrViewController setSelectedPackage:aPackage];
    [coverLtrViewController setManagedObjectContext: self.managedObjectContext];
    [coverLtrViewController setFetchedResultsController: self.fetchedResultsController];
    
    // Push the cover letter view controller
    [self presentViewController: coverLtrViewController
                       animated: YES
                     completion: nil];
}

//----------------------------------------------------------------------------------------------------------
- (void)resumeButtonTapped: (UICollectionViewCell *)aCell
{
    // configureCell:atIndexPath sets the tag on the cell
    DLog(@"button %d", aCell.tag);
    
}

#pragma mark - Table view data source

//----------------------------------------------------------------------------------------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    DLog();
    
    return 1;
}


//----------------------------------------------------------------------------------------------------------
- (NSInteger)collectionView: (UICollectionView *)collectionView
     numberOfItemsInSection: (NSInteger)section
{
    DLog(@"section=%d", [[self.fetchedResultsController sections] count]);
    
    /*
     Hardcoded to 2 here because we want to want to show the cover_ltr from Packages (first row)
     and resume (second row).
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
    //        Packages *aPackage = (Packages *) [self.fetchedResultsController objectAtIndexPath: indexPath];
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
//	cell.accessoryType  = UITableViewCellAccessoryNone;
}

#pragma mark - Table view delegates

//----------------------------------------------------------------------------------------------------------
//- (BOOL)    tableView:(UITableView *)tableView
//canEditRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    // Return NO if you do not want the specified item to be editable.
//    return YES;
//}


//----------------------------------------------------------------------------------------------------------
//-  (void)tableView:(UITableView *)tableView
//commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
// forRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    DLog();
//    
//    if (editingStyle == UITableViewCellEditingStyleDelete) {
//        // Delete the row from the data source
//        [self editButtonTapped];
//        // Delete the managed object at the given index path.
//        NSManagedObject *packageToDelete = [self.fetchedResultsController objectAtIndexPath: indexPath];
//        [self.managedObjectContext deleteObject: packageToDelete];
//        
//        [self.tableView reloadData];
//    }
//}


//----------------------------------------------------------------------------------------------------------
//- (BOOL)     tableView:(UITableView *)tableView
//canMoveRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return YES;
//}


//----------------------------------------------------------------------------------------------------------
//-  (void)tableView:(UITableView *)tableView
//moveRowAtIndexPath:(NSIndexPath *)fromIndexPath
//       toIndexPath:(NSIndexPath *)toIndexPath
//{
//    DLog();
//    
//    NSMutableArray *packages = [[self.fetchedResultsController fetchedObjects] mutableCopy];
//    
//    // Grab the item we're moving.
//    NSManagedObject *movedPackage = [[self fetchedResultsController] objectAtIndexPath: fromIndexPath];
//    
//    // Remove the object we're moving from the array.
//    [packages removeObject: movedPackage];
//    // Now re-insert it at the destination.
//    [packages insertObject: movedPackage
//                   atIndex: toIndexPath.row];
//    
//    // All of the objects are now in their correct order. Update each
//    // object's sequence_number field by iterating through the array.
//    int i = 0;
//    for (Packages *aPackage in packages) {
//        [aPackage setSequence_numberValue: i++];
//    }
//    
//    [self doneButtonTapped];
//}


//----------------------------------------------------------------------------------------------------------
- (void)   collectionView: (UICollectionView *)collectionView
 didSelectItemAtIndexPath: (NSIndexPath *)indexPath
{
    DLog();
    
    /*
     See the comment in - configureCell:atIndexPath: to understand why we are only using the section with fetchedResultsController
     */
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:indexPath.section];
    Packages *aPackage  = (Packages *) [sectionInfo.objects objectAtIndex: indexPath.section];
    DLog(@"aPackage.name=%@", aPackage.name);
    
    switch (indexPath.row) {
        case k_cover_ltrRow:
            // setup the cover_ltr view controller and segue to it
            break;
            
        case k_resumeRow:
            // set up the resume view controller and segue to it
            break;
            
        default:
            ALog(@"unexpected row=%d", indexPath.row);
            break;
    }
}


//----------------------------------------------------------------------------------------------------------
- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    // TODO: Deselect item
}


//-       (void)tableView:(UITableView *)tableView
//didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    DLog();
//    
//    /*
//     See the comment in - configureCell:atIndexPath: to understand why we are only using the section with fetchedResultsController
//     */
//    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:indexPath.section];
//    Packages *aPackage  = (Packages *) [sectionInfo.objects objectAtIndex: indexPath.section];
//    DLog(@"aPackage.name=%@", aPackage.name);
//
//    switch (indexPath.row) {
//        case k_cover_ltrRow:
//            // setup the cover_ltr view controller and segue to it
//            break;
//            
//        case k_resumeRow:
//        // set up the resume view controller and segue to it
//        break;
//            
//        default:
//            ALog(@"unexpected row=%d", indexPath.row);
//            break;
//    }

//    PackagesViewController *packagesViewController = [[[PackagesViewController alloc] initWithNibName: KOPackagesViewController
//                                                                                               bundle: nil] autorelease];
//    // Pass the selected object to the new view controller.
//    packagesViewController.title                    = [[self.fetchedResultsController objectAtIndexPath: indexPath] name];
//    packagesViewController.selectedPackage          = [self.fetchedResultsController objectAtIndexPath: indexPath];
//    packagesViewController.managedObjectContext     = self.managedObjectContext;
//    packagesViewController.fetchedResultsController = self.fetchedResultsController;
//    [self.navigationController pushViewController: packagesViewController
//                                         animated: YES];
    
    // Clear the selected row
//	[self.collectionView deselectRowAtIndexPath: indexPath
//                                       animated: YES];
//}

#pragma mark - Seque handling

//----------------------------------------------------------------------------------------------------------
- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [[self.collectionView indexPathsForSelectedItems] lastObject];

        /*
         See the comment in - configureCell:atIndexPath: to understand why we are only using the section with fetchedResultsController
         */
        id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:indexPath.section];
        Packages *aPackage  = (Packages *) [sectionInfo.objects objectAtIndex:0];
        
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
    NSEntityDescription *entity  = [NSEntityDescription entityForName: @"Packages"
                                               inManagedObjectContext: self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number
    [fetchRequest setFetchBatchSize: 25];
    // Sort by package sequence_number
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: KOSequenceNumberAttributeName
                                                                   ascending: YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects: sortDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Alloc and initialize the controller
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest: fetchRequest
                                                                                               managedObjectContext: self.managedObjectContext
                                                                                                 sectionNameKeyPath: nil
                                                                                                          cacheName: @"Root"];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
//    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Master"];
    fetchedResultsController.delegate = self;
    self.fetchedResultsController = fetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	     // Replace this implementation with code to handle the error appropriately.
	     // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
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

//----------------------------------------------------------------------------------------------------------
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    DLog();
    
//    [self.collectionView beginUpdates];
}


//----------------------------------------------------------------------------------------------------------
//- (void)controller:(NSFetchedResultsController *)controller
//  didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo
//           atIndex:(NSUInteger)sectionIndex
//     forChangeType:(NSFetchedResultsChangeType)type
//{
//    DLog();
//    
//    switch (type) {
//        case NSFetchedResultsChangeInsert:
//            [self.collectionView insertSections: [NSIndexSet indexSetWithIndex: sectionIndex]
//                          withRowAnimation: UITableViewRowAnimationFade];
//            break;
//        case NSFetchedResultsChangeDelete:
//            [self.collectionView deleteSections: [NSIndexSet indexSetWithIndex: sectionIndex]
//                          withRowAnimation: UITableViewRowAnimationFade];
//            break;
//        default:
//            ALog();
//            break;
//    }
//    
//    [self.collectionView reloadData];
//}


//----------------------------------------------------------------------------------------------------------
//- (void)controller:(NSFetchedResultsController *)controller
//   didChangeObject:(id)anObject
//       atIndexPath:(NSIndexPath *)indexPath
//     forChangeType:(NSFetchedResultsChangeType)type
//      newIndexPath:(NSIndexPath *)newIndexPath
//{
//    DLog();
//    
//    switch (type) {
//        case NSFetchedResultsChangeInsert:
//            [self.collectionView insertRowsAtIndexPaths: [NSArray arrayWithObject: newIndexPath]
//                                  withRowAnimation: UITableViewRowAnimationFade];
//            break;
//        case NSFetchedResultsChangeDelete:
//            [self.collectionView deleteRowsAtIndexPaths: [NSArray arrayWithObject: indexPath]
//                                  withRowAnimation: UITableViewRowAnimationFade];
////            // Clear the selected row
////            [self.tableView deselectRowAtIndexPath: indexPath
////                                          animated: YES];
//            break;
//        case NSFetchedResultsChangeUpdate:
//            [self collectionView: [self.tableView cellForRowAtIndexPath: indexPath]
//                    atIndexPath: indexPath];
//            break;
//        case NSFetchedResultsChangeMove:
//            [self.collectionView deleteRowsAtIndexPaths: [NSArray arrayWithObject: indexPath]
//                                  withRowAnimation: UITableViewRowAnimationFade];
//            [self.collectionView insertRowsAtIndexPaths: [NSArray arrayWithObject: newIndexPath]
//                                  withRowAnimation: UITableViewRowAnimationFade];
//            break;
//            
//        default:
//            break;
//    }
//    
//    [self.tableView reloadData];
//}


//----------------------------------------------------------------------------------------------------------
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    DLog();
    
//    [self.collectionView endUpdates];
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
