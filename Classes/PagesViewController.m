//
//  PagesViewController.m
//  WordPress
//
//  Created by Janakiram on 01/11/08.
//

#import "PagesViewController.h"

#import "BlogDataManager.h"
#import "EditPageViewController.h"
#import "LocalDraftsTableViewCell.h"
#import "PagePhotosViewController.h"
#import "PagesDraftsViewController.h"
#import "PostTableViewCell.h"
#import "Reachability.h"
#import "WordPressAppDelegate.h"

#define LOCAL_DRAFTS_ROW        0
#define PAGE_ROW                1

#define REFRESH_BUTTON_ICON     @"sync.png"
#define REFRESH_BUTTON_HEIGHT   50

@interface PagesViewController (Private)
- (void)setPageDetailsController;
- (void)downloadRecentPages;
- (void)showAddNewPage;
@end

@implementation PagesViewController

@synthesize pageDetailViewController, pageDetailsController;

- (void)addRefreshButton {
    CGRect frame = CGRectMake(0, 0, self.tableView.bounds.size.width, REFRESH_BUTTON_HEIGHT);
    UIButton *refreshButton = [[UIButton alloc] initWithFrame:frame];
    
    [refreshButton setImage:[UIImage imageNamed:REFRESH_BUTTON_ICON] forState:UIControlStateNormal];
    [refreshButton addTarget:self action:@selector(downloadRecentPages) forControlEvents:UIControlEventTouchUpInside];
    
    self.tableView.tableHeaderView = refreshButton;
}

- (void)viewDidLoad {
    self.tableView.backgroundColor = kTableBackgroundColor;
    
    [self addRefreshButton];
    
	[self setPageDetailsController];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged) name:@"kNetworkReachabilityChangedNotification" object:nil];
}

- (void)dealloc {	
	if (pageDetailViewController != nil) {
		[pageDetailViewController autorelease];
		pageDetailViewController = nil;
	}
    
	[pageDetailsController release];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"kNetworkReachabilityChangedNotification" object:nil];
    
	[super dealloc];
}

#pragma mark -

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor whiteColor];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [[BlogDataManager sharedDataManager] countOfPageTitles];
}

- (UITableViewCell *)localDraftsCell:(UITableView *)tableView forRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"DraftsCell";
	LocalDraftsTableViewCell *cell = (LocalDraftsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	
	if (cell == nil) {
		cell = [[[LocalDraftsTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
	}
    
	NSNumber *count = [dm.currentBlog valueForKey:@"kPageDraftsCount"];
    
	if ([count intValue]) {
		int c = (count == nil ? 0 : [count intValue]);
		cell.badgeLabel.text = [NSString stringWithFormat:@"(%d)", c];
	} else {
		cell.badgeLabel.text = [NSString stringWithFormat:@""];
	}
	
	return cell;
}

- (UITableViewCell *)pageCell:(UITableView *)tableView forRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"PageCell";
    PostTableViewCell *cell = (PostTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	
	if (cell == nil) {
        cell = [[[PostTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
	}
	
	if ([dm countOfPageTitles]) {
		id currentPage = [dm pageTitleAtIndex:indexPath.row - PAGE_ROW];
		cell.post = currentPage;
	}
	
	return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row == LOCAL_DRAFTS_ROW) {
		return [self localDraftsCell:tableView forRowAtIndexPath:indexPath];
	} else {
		return [self pageCell:tableView forRowAtIndexPath:indexPath];
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    BlogDataManager *dataManager = [BlogDataManager sharedDataManager];
	dataManager.isLocaDraftsCurrent = (indexPath.row == LOCAL_DRAFTS_ROW);
    
	if (indexPath.row == LOCAL_DRAFTS_ROW) {
		PagesDraftsViewController *pagesDraftsListController = [[PagesDraftsViewController alloc] initWithNibName:@"PagesDraftsViewController" bundle:nil];
		pagesDraftsListController.pagesListController = self;
		
		[dataManager loadPageDraftTitlesForCurrentBlog];
		
        // Get the navigation controller from the delegate
        WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
        [delegate.navigationController pushViewController:pagesDraftsListController animated:YES];
        
		[pagesDraftsListController release];
		return;
	} else {
		if (!connectionStatus) {
			UIAlertView *alert1 = [[UIAlertView alloc] initWithTitle:@"No connection to host."
															 message:@"Editing is not supported now."
															delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
			
			[alert1 show];
			WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
			[delegate setAlertRunning:YES];
			
			[alert1 release];		
			
			[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
			return;
		}
		
		[dataManager makePageAtIndexCurrent:indexPath.row - PAGE_ROW];	
		
		self.pageDetailsController.mode = 1;
		self.pageDetailsController.hasChanges = NO; 	
        
        // Get the navigation controller from the delegate
        WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
        [delegate.navigationController pushViewController:self.pageDetailsController animated:YES];
        
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row == LOCAL_DRAFTS_ROW) {
		return LOCAL_DRAFTS_ROW_HEIGHT;
	} else {
		return POST_ROW_HEIGHT;
    }
}

- (void)reachabilityChanged {
	connectionStatus = ( [[Reachability sharedReachability] remoteHostStatus] != NotReachable );
	[self.tableView reloadData];
}

#pragma mark -

- (void)viewWillAppear:(BOOL)animated {
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
	[dm loadPageTitlesForCurrentBlog];
	dm.isLocaDraftsCurrent = NO;
    
	self.title = @"Pages";
	
	connectionStatus = ( [[Reachability sharedReachability] remoteHostStatus] != NotReachable );
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}

- (void)downloadRecentPages {
	BlogDataManager *dm = [BlogDataManager sharedDataManager];
    
	[dm syncPagesForBlog:[dm currentBlog]];
	[dm loadPageTitlesForCurrentBlog];
	
	[self.tableView reloadData];
}


- (void)showAddNewPage {
	[[BlogDataManager sharedDataManager] makeNewPageCurrent];	
	self.pageDetailsController.mode = 0;
    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [delegate.navigationController pushViewController:self.pageDetailsController animated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	//Code to disable landscape when alert is raised.
	
	WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	if([delegate isAlertRunning] == YES)
		return NO;
	
	// Return YES for supported orientations
	return YES;
}

#pragma mark -

- (void)didReceiveMemoryWarning {
	WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
	[super didReceiveMemoryWarning];
}

-(void)setPageDetailsController {
	if (self.pageDetailsController == nil) {
		self.pageDetailsController = [[PagePhotosViewController alloc] initWithNibName:@"PagePhotosViewController" bundle:nil];
	}
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	[delegate setAlertRunning:NO];
}

@end