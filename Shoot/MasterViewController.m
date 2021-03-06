//
//  MasterViewController.m
//  Shoot
//
//  Created by LV on 12/10/14.
//  Copyright (c) 2014 Shoot. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "ShootTableViewCell.h"
#import "AppDelegate.h"
#import "SWRevealViewController.h"
#import "ImageUtil.h"
#import "ColorDefinition.h"
#import "BlurView.h"
#import <RestKit/RestKit.h>
#import "UserTagShoot.h"

@interface MasterViewController () <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@property (retain, nonatomic) UITableView * tableView;
@property (nonatomic,retain) UIRefreshControl *refreshControl;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@end

@implementation MasterViewController

static NSString * TABEL_CELL_REUSE_ID = @"ShootTableViewCell";
static CGFloat ADD_BUTTON_SIZE = 40;
static CGFloat ADD_BUTTON_PADDING = 20;

- (void)awakeFromNib {
    [super awakeFromNib];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    SWRevealViewController *revealViewController = self.revealViewController;
    if ( revealViewController )
    {
        [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    }
    
    [self initFetchController];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:self.tableView];
    [self.tableView setContentInset:UIEdgeInsetsMake(self.tableView.contentInset.top, self.tableView.contentInset.left, ADD_BUTTON_SIZE + ADD_BUTTON_PADDING * 2, self.tableView.contentInset.right)];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView setSeparatorColor:[UIColor clearColor]];
    self.tableView.showsHorizontalScrollIndicator = false;
    self.tableView.showsVerticalScrollIndicator = false;
    [self.tableView registerClass:[ShootTableViewCell class] forCellReuseIdentifier:TABEL_CELL_REUSE_ID];
    
    CGFloat customRefreshControlHeight = 50.0f;
    CGFloat customRefreshControlWidth = 100.0;
    CGRect customRefreshControlFrame = CGRectMake(0.0f, -customRefreshControlHeight, customRefreshControlWidth, customRefreshControlHeight);
    self.refreshControl = [[UIRefreshControl alloc] initWithFrame:customRefreshControlFrame];
    [self.refreshControl addTarget:self action:@selector(refreshView:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    [self.tableView sendSubviewToBack:self.refreshControl];
    
    UIButton *addButton = [[UIButton alloc] initWithFrame:CGRectMake((self.view.frame.size.width - ADD_BUTTON_SIZE)/2.0, self.view.frame.size.height - ADD_BUTTON_PADDING - ADD_BUTTON_SIZE, ADD_BUTTON_SIZE, ADD_BUTTON_SIZE)];
    [self.view addSubview:addButton];
    [addButton setImage:[ImageUtil renderImage:[ImageUtil colorImage:[UIImage imageNamed:@"camera-filled"] color:[UIColor whiteColor]] atSize:CGSizeMake(20, 20)] forState:UIControlStateNormal];
    addButton.backgroundColor = [ColorDefinition lightRed];
    [addButton.layer setBorderColor:[UIColor whiteColor].CGColor];
    addButton.layer.cornerRadius = addButton.frame.size.width/2.0;
    addButton.layer.borderWidth = 2;
    addButton.layer.shadowOffset = CGSizeMake(0, 0);
    addButton.layer.shadowRadius = 10;
    addButton.layer.shadowColor = [UIColor whiteColor].CGColor;
    addButton.layer.shadowOpacity = 1.0;
    
    [self loadData];
    [self.refreshControl beginRefreshing];
    [self refreshView:self.refreshControl];
}

-(void)refreshView:(UIRefreshControl *)refresh {
    refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Refreshing..."];
    [self fetchData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) initFetchController
{
    NSString *sectionNameKeyPath = @"shootAndUser";
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"UserTagShoot"];
    NSSortDescriptor *timeSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"time" ascending:NO];
    fetchRequest.sortDescriptors = @[timeSortDescriptor];

    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"is_feed == 1"];
    fetchRequest.predicate = predicate;
    // Setup fetched results
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext sectionNameKeyPath:sectionNameKeyPath cacheName:nil];
    
    [self.fetchedResultsController setDelegate:self];
}

- (void) fetchData {
    @synchronized(self) {
        [[RKObjectManager sharedManager] getObjectsAtPath:@"shoot/query"  parameters:nil success:^
         (RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
             [self loadData];
             [self.refreshControl endRefreshing];
         } failure:^(RKObjectRequestOperation *operation, NSError *error) {
             RKLogError(@"Failed to call shoot/query due to error: %@", error);
             [self.refreshControl endRefreshing];
         }];
    }
}

- (void) loadData {
    @synchronized(self) {
        NSError *error = nil;
        BOOL fetchSuccessful = [self.fetchedResultsController performFetch:&error];
        if (! fetchSuccessful) {
            NSLog(@"Fetch Error: %@",error);
        }
        [self.tableView reloadData];
    }
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSArray *userTagShoots = [[[self.fetchedResultsController sections] objectAtIndex:indexPath.section] objects];
        UserTagShoot *userTagShoot = [userTagShoots objectAtIndex:0];
        DetailViewController *controller = (DetailViewController *)[segue destinationViewController];
        controller.shootID = userTagShoot.shootID;
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ShootTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:TABEL_CELL_REUSE_ID forIndexPath:indexPath];
    cell.userInteractionEnabled = true;
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [ShootTableViewCell height];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"showDetail" sender:self];
}

- (void)configureCell:(ShootTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    NSArray *userTagShoots = [[[self.fetchedResultsController sections] objectAtIndex:indexPath.section] objects];
    UserTagShoot *userTagShoot = [userTagShoots objectAtIndex:0];
    [cell decorateWith:userTagShoot.shoot user:userTagShoot.user userTagShoots:userTagShoots parentController:self];
}

#pragma mark - Fetched results controller

//- (NSFetchedResultsController *)fetchedResultsController
//{
//    if (_fetchedResultsController != nil) {
//        return _fetchedResultsController;
//    }
//    
//    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
//    // Edit the entity name as appropriate.
//    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:self.managedObjectContext];
//    [fetchRequest setEntity:entity];
//    
//    // Set the batch size to a suitable number.
//    [fetchRequest setFetchBatchSize:20];
//    
//    // Edit the sort key as appropriate.
//    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:NO];
//    NSArray *sortDescriptors = @[sortDescriptor];
//    
//    [fetchRequest setSortDescriptors:sortDescriptors];
//    
//    // Edit the section name key path and cache name if appropriate.
//    // nil for section name key path means "no sections".
//    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Master"];
//    aFetchedResultsController.delegate = self;
//    self.fetchedResultsController = aFetchedResultsController;
//    
//	NSError *error = nil;
//	if (![self.fetchedResultsController performFetch:&error]) {
//	     // Replace this implementation with code to handle the error appropriately.
//	     // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
//	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
//	    abort();
//	}
//    
//    return _fetchedResultsController;
//}    
//
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        default:
            return;
    }
}

//- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
//       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
//      newIndexPath:(NSIndexPath *)newIndexPath
//{
//    UITableView *tableView = self.tableView;
//    
//    switch(type) {
//        case NSFetchedResultsChangeInsert:
//            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
//            break;
//            
//        case NSFetchedResultsChangeDelete:
//            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
//            break;
//            
//        case NSFetchedResultsChangeUpdate:
//            [self configureCell:(ShootTableViewCell *)[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
//            break;
//            
//        case NSFetchedResultsChangeMove:
//            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
//            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
//            break;
//    }
//}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

/*
// Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed. 
 
 - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    // In the simplest, most efficient, case, reload the table view.
    [self.tableView reloadData];
}
 */

@end
