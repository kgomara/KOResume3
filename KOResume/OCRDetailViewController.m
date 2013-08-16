//
//  OCRDetailViewController.m
//  KOResume
//
//  Created by Kevin O'Mara on 7/14/13.
//  Copyright (c) 2013 O'Mara Consulting Associates. All rights reserved.
//

#import "OCRDetailViewController.h"
#import "OCRAppDelegate.h"
#import <CoreData/CoreData.h>
//#import "CoverLtrViewController.h"
//#import "ResumeViewController.h"
#import "Resumes.h"

#define kSummaryTableCell   0
#define kResumeTableCell    1

@interface OCRDetailViewController ()

@property (strong, nonatomic) UIPopoverController *masterPopoverController;

- (void)configureView;

@end


@implementation OCRDetailViewController

@synthesize tblView                     = _tblView;
@synthesize selectedPackage             = _selectedPackage;

@synthesize managedObjectContext        = __managedObjectContext;
@synthesize fetchedResultsController    = __fetchedResultsController;

#pragma mark - Managing the detail item

//----------------------------------------------------------------------------------------------------------
- (void)setSelectedPackage:(Packages *)nuSelectedPackage
{
    if (_selectedPackage != nuSelectedPackage) {
        _selectedPackage = nuSelectedPackage;
        
        // Update the view.
        [self configureView];
    }

    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }        
}

#pragma mark - View lifecycle

//----------------------------------------------------------------------------------------------------------
- (void)viewDidLoad
{
    DLog();
    
    [super viewDidLoad];
	
    
//    [_selectedPackage logAllFields];
	self.view.backgroundColor = [UIColor clearColor];
    
    // Set an observer for iCloud changes
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(reloadFetchedResults:)
                                                 name: OCRApplicationDidMergeChangesFrom_iCloudNotification
                                               object: nil];
}


//----------------------------------------------------------------------------------------------------------
- (void)viewDidUnload
{
    DLog();
    
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
	self.tblView = nil;
}


//----------------------------------------------------------------------------------------------------------
- (void)didReceiveMemoryWarning
{
    DLog();
    
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
    ALog();
}

//----------------------------------------------------------------------------------------------------------
- (void)configureView
{
    // Update the user interface for the detail item.

    self.navigationItem.title = NSLocalizedString(@"Detail", nil);
}

//----------------------------------------------------------------------------------------------------------
#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController
     willHideViewController:(UIViewController *)viewController
          withBarButtonItem:(UIBarButtonItem *)barButtonItem
       forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Packages", nil);
    [self.navigationItem setLeftBarButtonItem:barButtonItem
                                     animated:YES];
    self.masterPopoverController = popoverController;
}

//----------------------------------------------------------------------------------------------------------
- (void)splitViewController:(UISplitViewController *)splitController
     willShowViewController:(UIViewController *)viewController
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil
                                     animated:YES];
    self.masterPopoverController = nil;
}

#pragma mark -
#pragma mark Table view data source

//----------------------------------------------------------------------------------------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}


//----------------------------------------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return [[[self.fetchedResultsController sections] objectAtIndex: section] numberOfObjects];
}


//----------------------------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DLog();
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: OCRCellID
                                                            forIndexPath: indexPath];
    
	// Configure the cell.
	switch (indexPath.row) {
            // There is only 1 section, so ignore it.
		case kSummaryTableCell:
			cell.textLabel.text = NSLocalizedString(@"Cover Letter", nil);
            cell.accessoryType  = UITableViewCellAccessoryDetailDisclosureButton;
			break;
		case kResumeTableCell:
			cell.textLabel.text = NSLocalizedString(@"Resume", nil);
            cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
			break;
		default:
            ALog(@"Unexpected row %d", indexPath.row);
			break;
	}
	cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}


//----------------------------------------------------------------------------------------------------------
- (void)viewWillDisappear:(BOOL)animated
{
    DLog();
    
    // Save any changes
    [kAppDelegate saveContext: self.managedObjectContext];
}

#pragma mark -
#pragma mark Table view delegates

//----------------------------------------------------------------------------------------------------------
-  (UIView *)tableView:(UITableView *)tableView
viewForHeaderInSection:(NSInteger)section
{
    DLog();
    
	UILabel *sectionLabel = [[UILabel alloc] init];
	[sectionLabel setFont:[UIFont fontWithName: @"Helvetica-Bold"
                                          size: 18.0]];
	[sectionLabel setTextColor: [UIColor whiteColor]];
	[sectionLabel setBackgroundColor: [UIColor clearColor]];
	
	sectionLabel.text = NSLocalizedString(@"Package Contents:", nil);
    
	return sectionLabel;
}


//----------------------------------------------------------------------------------------------------------
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return 44;
}


//----------------------------------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DLog();
    
    // There is only 1 section, so ignore it.
    switch (indexPath.row) {
		case kSummaryTableCell: {
//			CoverLtrViewController *coverLtrViewController = [[CoverLtrViewController alloc] initWithNibName: OCACoverLtrViewController
//                                                                                                      bundle: nil];
//			coverLtrViewController.title                    = NSLocalizedString(@"Cover Letter", nil);
//            coverLtrViewController.selectedPackage          = self.selectedPackage;
//            coverLtrViewController.managedObjectContext     = self.managedObjectContext;
//            coverLtrViewController.fetchedResultsController = self.fetchedResultsController;
//			
//			[self.navigationController pushViewController:coverLtrViewController
//                                                 animated:YES];
			break;
		}
		case kResumeTableCell: {
//			ResumeViewController* resumeViewController = [[ResumeViewController alloc] initWithNibName: OCRResumeViewController
//                                                                                                bundle: nil];
//			resumeViewController.title                      = NSLocalizedString(@"Resume", nil);
//            resumeViewController.selectedResume             = self.selectedPackage.resume;
//            resumeViewController.managedObjectContext       = self.managedObjectContext;
//            resumeViewController.fetchedResultsController   = self.fetchedResultsController;
//			
//			[self.navigationController pushViewController: resumeViewController
//                                                 animated: YES];
			break;
		}
	}
	[tableView deselectRowAtIndexPath: indexPath
							 animated: YES];
}


//----------------------------------------------------------------------------------------------------------
- (void)reloadFetchedResults:(NSNotification*)note
{
    DLog();
    
    NSError *error = nil;
    
    if (![[self fetchedResultsController] performFetch: &error]) {
        ELog(error, @"Fetch failed!");
        NSString* msg = NSLocalizedString(@"Failed to reload data.", nil);
        [OCAExtensions showErrorWithMessage: msg];
    }
    
    [self.tblView reloadData];
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
