#import "BlogsViewController.h"
#import "BlogViewController.h"
#import "EditBlogViewController.h"
#import "BlogDataManager.h"
#import "Reachability.h"
#import "PostsListController.h"
#import "WordPressAppDelegate.h"
#import "UIViewController+WPAnimation.h"
#import <QuartzCore/QuartzCore.h>
#import "WPLogoView.h"
#import "Blog.h"
#import "BlogTabViewController.h"

@interface BlogsViewController (Private)
- (void)showBlogDetailModalViewForNewBlogWithAnimation;
- (void)showBlogDetailModalViewForNewBlogWithAnimation:(BOOL)annimate;
- (void)showBlogDetailModalViewWithAnimation:(BOOL)animate;
- (void)showBlog:(BOOL)animated;

- (void)edit:(id)sender;
- (void)cancel:(id)sender;
@end

@implementation BlogsViewController

#pragma mark -
#pragma mark View Methods

- (void)viewDidLoad 
{
	self.title = NSLocalizedString(@"Blogs", @"RootViewController_Title");
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd 
                                                                                           target:self 
                                                                                           action:@selector(showBlogDetailModalViewForNewBlogWithAnimation)] autorelease];
    self.tableView.allowsSelectionDuringEditing = YES;
    
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(blogsRefreshNotificationReceived:) name:@"BlogsRefreshNotification" object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    if ([[BlogDataManager sharedDataManager] currentBlog]) {
        [self showBlog:NO];
    }
    
    if ([[BlogDataManager sharedDataManager] countOfBlogs] == 0) {
        [self showBlogDetailModalViewForNewBlogWithAnimation:NO];
    }

    [super viewWillAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self cancel:self];
}

#pragma mark -
#pragma mark Editing life cycle methods

- (void)edit:(id)sender
{
    UIBarButtonItem *cancelButton = [[[UIBarButtonItem alloc] initWithTitle:@"Cancel" 
                                                                      style:UIBarButtonItemStyleDone 
                                                                     target:self 
                                                                     action:@selector(cancel:)] autorelease];
    [self.navigationItem setLeftBarButtonItem:cancelButton animated:YES];
    [self.tableView setEditing:YES animated:YES];
}

- (void)cancel:(id)sender
{
    UIBarButtonItem *editButton = [[[UIBarButtonItem alloc] initWithTitle:@"Edit" 
                                                                    style:UIBarButtonItemStylePlain 
                                                                   target:self 
                                                                   action:@selector(edit:)] autorelease];
    [self.navigationItem setLeftBarButtonItem:editButton animated:YES];
    [self.tableView setEditing:NO animated:YES];
}

#pragma mark -
#pragma mark Notification Centre Callbacks

- (void)blogsRefreshNotificationReceived:(id)notification
{
	[self.tableView reloadData];
}

#pragma mark -
#pragma mark Show Blog Detail Modal View

- (void)showBlogDetailModalViewForNewBlogWithAnimation
{
    [self showBlogDetailModalViewForNewBlogWithAnimation:YES];
}

-(void)showBlogDetailModalViewForNewBlogWithAnimation:(BOOL)animate
{
    [[BlogDataManager sharedDataManager] makeNewBlogCurrent];
    [self showBlogDetailModalViewWithAnimation:animate];
}

- (void)showBlogDetailModalViewWithAnimation:(BOOL)animate
{
	EditBlogViewController *blogDetailViewController = [[[EditBlogViewController alloc] initWithNibName:@"EditBlogViewController" bundle:nil] autorelease];
    UINavigationController *modalNavigationController = [[UINavigationController alloc] initWithRootViewController:blogDetailViewController];
    
    [self.navigationController presentModalViewController:modalNavigationController animated:animate];
	
	[modalNavigationController release];
}

#pragma mark -
#pragma mark Open Blog Main View

- (void)showBlog:(BOOL)animated
{
    BlogDataManager *dataManager = [BlogDataManager sharedDataManager];
    NSString *url = [dataManager.currentBlog valueForKey:@"url"];
    
    if(url != nil && [url length] >= 7 && [url hasPrefix:@"http://"]) {
        url = [url substringFromIndex:7];
    }
    
    if(url != nil && [url length]) {
        url = @"wordpress.com";
    }
    
    [Reachability sharedReachability].hostName = url;
        
    BlogTabViewController  *blogTabViewController = [[BlogTabViewController alloc] initWithNibName:@"BlogTabViewController" bundle:nil];
    [self.navigationController pushViewController:blogTabViewController animated:animated];
    [blogTabViewController release];
}


#pragma mark -
#pragma mark UITableView Delegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
  return [[BlogDataManager sharedDataManager] countOfBlogs];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *rootviewcell = @"rootviewcell";
	
	UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:rootviewcell];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:rootviewcell] autorelease];
	}
	
	cell.text = [[[BlogDataManager sharedDataManager] blogAtIndex:(indexPath.row)] valueForKey:@"blogName"];
    
    cell.image = [[[[Blog alloc] initWithIndex:indexPath.row] autorelease] favicon];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

	return cell;
}

// Show PostList when row is selected
- (void)tableView:(UITableView *)atableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
    BlogDataManager *dataManager = [BlogDataManager sharedDataManager];
	
    if ([self.tableView cellForRowAtIndexPath:indexPath].editing) {
        [[BlogDataManager sharedDataManager] copyBlogAtIndexCurrent:(indexPath.row)];
        
        [self showBlogDetailModalViewWithAnimation:YES];
    }
	else {		
        if( [[[dataManager blogAtIndex:indexPath.row] valueForKey:@"kIsSyncProcessRunning"] intValue] == 1 ) {
            [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
            return;
        }
        [dataManager makeBlogAtIndexCurrent:(indexPath.row)];
        [self showBlog:YES];
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [[BlogDataManager sharedDataManager] makeBlogAtIndexCurrent:indexPath.row];
        [[BlogDataManager sharedDataManager] removeCurrentBlog];
        
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
        
        if ([[BlogDataManager sharedDataManager] countOfBlogs] == 0) {
            self.navigationItem.leftBarButtonItem = nil;
        }
    }
}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"BlogsRefreshNotification" object:nil];
	
	[super dealloc];
}

- (void)didReceiveMemoryWarning {
	WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}

@end