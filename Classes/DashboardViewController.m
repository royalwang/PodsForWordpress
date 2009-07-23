//
//  DashboardViewController.m
//  WordPress
//
//  Created by Gareth Townsend on 23/07/09.
//

#import "DashboardViewController.h"

#import "BlogDataManager.h"
#import "CommentTableViewCell.h"
#import "CommentViewController.h"
#import "WordPressAppDelegate.h"
#import "WPProgressHUD.h"

#define COMMENTS_SECTION        0
#define NUM_SECTIONS            1

@interface DashboardViewController (Private)

- (void)scrollToFirstCell;
- (void)setEditing:(BOOL)value;
- (void)updateSelectedComments;
- (void)refreshHandler;
- (void)syncComments;
- (BOOL)isConnectedToHost;
- (void)moderateCommentsWithSelector:(SEL)selector;
- (void)deleteComments;
- (void)approveComments;
- (void)markCommentsAsSpam;
- (void)unapproveComments;
- (void)refreshCommentsList;
- (void)addRefreshButton;
- (void)calculateSections;
@end

@implementation DashboardViewController

@synthesize editButtonItem, selectedComments, commentsArray, sectionHeaders;

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
    [commentsArray release];
    [commentsDict release];
    [selectedComments release];
    [editButtonItem release];
    [refreshButton release];
    [sectionHeaders release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark View Lifecycle Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    commentsDict = [[NSMutableDictionary alloc] init];
    selectedComments = [[NSMutableArray alloc] init];
    
    [commentsTableView setDataSource:self];
    commentsTableView.backgroundColor = TABLE_VIEW_BACKGROUND_COLOR;
    
    [self addRefreshButton];
    
    editButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered
                                                     target:self action:@selector(editComments)];
    
}

- (void)viewWillAppear:(BOOL)animated {  
    [self setEditing:NO];
    
    BlogDataManager *sharedDataManager = [BlogDataManager sharedDataManager];
    [sharedDataManager loadCommentTitlesForCurrentBlog];
    
    [self refreshCommentsList];
    [self scrollToFirstCell];
    [self refreshHandler];
    
    [editToolbar setHidden:YES];
    self.navigationItem.rightBarButtonItem = editButtonItem;
    [editButtonItem setEnabled:([commentsArray count] > 0)];
    
    if ([commentsTableView indexPathForSelectedRow]) {
        [commentsTableView scrollToRowAtIndexPath:[commentsTableView indexPathForSelectedRow] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
        [commentsTableView deselectRowAtIndexPath:[commentsTableView indexPathForSelectedRow] animated:animated];
    }
    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    editButtonItem.title = @"Edit";
    [super viewWillDisappear:animated];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [commentsTableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    
    if ([delegate isAlertRunning] == YES) {
        return NO;
    } else {
        return YES;
    }
}

#pragma mark -

- (void)addRefreshButton {
    CGRect frame = CGRectMake(0, 0, commentsTableView.bounds.size.width, REFRESH_BUTTON_HEIGHT);
    
    refreshButton = [[RefreshButtonView alloc] initWithFrame:frame];
    [refreshButton addTarget:self action:@selector(refreshHandler) forControlEvents:UIControlEventTouchUpInside];
    
    commentsTableView.tableHeaderView = refreshButton;
}

- (void)setEditing:(BOOL)value {
    editing = value;
    
    // Adjust comments table view height to fit toolbar (if it's visible).
    CGFloat toolbarHeight = editing ? editToolbar.bounds.size.height : 0;
    CGRect mainViewBounds = self.view.bounds;
    CGRect rect = CGRectMake(mainViewBounds.origin.x,
                             mainViewBounds.origin.y,
                             mainViewBounds.size.width,
                             mainViewBounds.size.height - toolbarHeight);
    
    commentsTableView.frame = rect;
    
    [editToolbar setHidden:!editing];
    [deleteButton setEnabled:!editing];
    [approveButton setEnabled:!editing];
    [unapproveButton setEnabled:!editing];
    [spamButton setEnabled:!editing];
    
    editButtonItem.title = editing ? @"Cancel" : @"Edit";
    
    [commentsTableView setEditing:value animated:YES];
}

- (void)editComments {
    [self setEditing:!editing];
}

#pragma mark -
#pragma mark Action Methods

- (void)scrollToFirstCell {
    NSIndexPath *indexPath = NULL;
    
    if ([self tableView:commentsTableView numberOfRowsInSection:COMMENTS_SECTION] > 0) {
        NSUInteger indexes[] = {0, 0};
        indexPath = [NSIndexPath indexPathWithIndexes:indexes length:2];
    }
    
    if (indexPath) {
        [commentsTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}

- (void)refreshHandler {
    [refreshButton startAnimating];
    [self performSelectorInBackground:@selector(syncComments) withObject:nil];
}

- (void)syncComments {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    BlogDataManager *sharedBlogDataManager = [BlogDataManager sharedDataManager];
    [sharedBlogDataManager syncCommentsForCurrentBlog];
    [sharedBlogDataManager loadCommentTitlesForCurrentBlog];
    
    [self refreshCommentsList];
    
    [editButtonItem setEnabled:([commentsArray count] > 0)];
    
    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    
    if ([delegate isAlertRunning]) {
        [progressAlert dismissWithClickedButtonIndex:0 animated:YES];
        [progressAlert release];
    } else {
        [refreshButton stopAnimating];
    }
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [pool release];
}

- (void)refreshCommentsList {
    BlogDataManager *sharedBlogDataManager = [BlogDataManager sharedDataManager];
    
    if (!selectedComments) {
        selectedComments = [[NSMutableArray alloc] init];
    } else {
        [selectedComments removeAllObjects];
    }
    
    NSMutableArray *commentsList = nil;
    if (indexForCurrentPost >= 0) {
        commentsList = [sharedBlogDataManager commentTitlesForBlog:[sharedBlogDataManager currentBlog] scopedToPostWithIndex:indexForCurrentPost];
    }
    else {
        commentsList = [sharedBlogDataManager commentTitlesForBlog:[sharedBlogDataManager currentBlog]];
    }
    
    
    [self setCommentsArray:commentsList];
    
    for (NSDictionary *dict in commentsArray) {
        NSString *str = [dict valueForKey:@"comment_id"];
        [commentsDict setValue:dict forKey:str];
    }
    
    if (([commentsArray count] > 0) && (![(NSDictionary *)[commentsArray objectAtIndex:0] objectForKey:@"author_url"])) {
        progressAlert = [[WPProgressHUD alloc] initWithLabel:@"updating"];
        [progressAlert show];
        
        [self performSelectorInBackground:@selector(downloadRecentComments) withObject:nil];
    }
    
    [self calculateSections];
    [commentsTableView reloadData];
}

- (IBAction)deleteSelectedComments:(id)sender {
    progressAlert = [[WPProgressHUD alloc] initWithLabel:@"deleting"];
    [progressAlert show];
    
    [self performSelectorInBackground:@selector(deleteComments) withObject:nil];
}

- (IBAction)approveSelectedComments:(id)sender {
    progressAlert = [[WPProgressHUD alloc] initWithLabel:@"moderating"];
    [progressAlert show];
    
    [self performSelectorInBackground:@selector(approveComments) withObject:nil];
}

- (IBAction)unapproveSelectedComments:(id)sender {
    progressAlert = [[WPProgressHUD alloc] initWithLabel:@"moderating"];
    [progressAlert show];
    
    [self performSelectorInBackground:@selector(unapproveComments) withObject:nil];
}

- (IBAction)spamSelectedComments:(id)sender {
    progressAlert = [[WPProgressHUD alloc] initWithLabel:@"moderating"];
    [progressAlert show];
    
    [self performSelectorInBackground:@selector(markCommentsAsSpam) withObject:nil];
}

- (void)moderateCommentsWithSelector:(SEL)selector {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    if ([self isConnectedToHost]) {
        BlogDataManager *sharedDataManager = [BlogDataManager sharedDataManager];
        
        NSArray *selectedItems = [self selectedComments];
        
        [sharedDataManager performSelector:selector withObject:selectedItems withObject:[sharedDataManager currentBlog]];
        
        [editButtonItem setEnabled:([commentsArray count] > 0)];
        [self setEditing:FALSE];
    }
    
    [progressAlert dismissWithClickedButtonIndex:0 animated:YES];
    [progressAlert release];
    [pool release];
}

- (void)deleteComments {
    [self moderateCommentsWithSelector:@selector(deleteComment:forBlog:)];
}

- (void)approveComments {
    [self moderateCommentsWithSelector:@selector(approveComment:forBlog:)];
}

- (void)markCommentsAsSpam {
    [self moderateCommentsWithSelector:@selector(spamComment:forBlog:)];
}

- (void)unapproveComments {
    [self moderateCommentsWithSelector:@selector(unApproveComment:forBlog:)];
}

- (void)updateSelectedComments {
    int i, approvedCount, unapprovedCount, spamCount, count = [selectedComments count];
    
    approvedCount = unapprovedCount = spamCount = 0;
    
    for (i = 0; i < count; i++) {
        NSDictionary *dict = [selectedComments objectAtIndex:i];
        
        if ([[dict valueForKey:@"status"] isEqualToString:@"hold"]) {
            unapprovedCount++;
        } else if ([[dict valueForKey:@"status"] isEqualToString:@"approve"]) {
            approvedCount++;
        } else if ([[dict valueForKey:@"status"] isEqualToString:@"spam"]) {
            spamCount++;
        }
    }
    
    [deleteButton setEnabled:(count > 0)];
    [approveButton setEnabled:((count - approvedCount) > 0)];
    [unapproveButton setEnabled:((count - unapprovedCount) > 0)];
    [spamButton setEnabled:((count - spamCount) > 0)];
    
    [approveButton setTitle:(((count - approvedCount) > 0) ? [NSString stringWithFormat:@"Approve (%d)", count - approvedCount]:@"Approve")];
    [unapproveButton setTitle:(((count - unapprovedCount) > 0) ? [NSString stringWithFormat:@"Unapprove (%d)", count - unapprovedCount]:@"Unapprove")];
    [spamButton setTitle:(((count - spamCount) > 0) ? [NSString stringWithFormat:@"Spam (%d)", count - spamCount]:@"Spam")];
}

- (void)showCommentAtIndex:(int)index {
    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    CommentViewController *commentsViewController = [[CommentViewController alloc] initWithNibName:@"CommentViewController" bundle:nil];
    
    [delegate.navigationController pushViewController:commentsViewController animated:YES];
    
    [commentsViewController showComment:commentsArray atIndex:index];
    [commentsViewController release];
}

#pragma mark -
#pragma mark UITableViewDataSource Methods

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = TABLE_VIEW_CELL_BACKGROUND_COLOR;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return ([sectionHeaders count] == 0) ? 1 : [sectionHeaders count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return ([sectionHeaders count] == 0) ? @"No Comments" : [[sectionHeaders objectAtIndex:section] objectForKey:@"date"];  
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return ([sectionHeaders count] == 0) ? 0 : [[[sectionHeaders objectAtIndex:section] objectForKey:@"numberOfComments"] intValue];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"PageCell";
    CommentTableViewCell *cell = (CommentTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    id comment = [[sectionHeaders objectAtIndex:indexPath.section] objectForKey:[NSString stringWithFormat:@"%i", indexPath.row]];
    
    if (cell == nil) {
        cell = [[[CommentTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
    }
    
    cell.comment = comment;
    cell.checked = [selectedComments containsObject:comment];
    cell.editing = editing;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return COMMENT_ROW_HEIGHT;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return kSectionHeaderHight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editing) {
        [self tableView:tableView didCheckRowAtIndexPath:indexPath];
    } else {
        [self showCommentAtIndex:indexPath.row];
    }
}

- (void)tableView:(UITableView *)tableView didCheckRowAtIndexPath:(NSIndexPath *)indexPath {
    CommentTableViewCell *cell = (CommentTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    NSDictionary *comment = cell.comment;
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if ([selectedComments containsObject:comment]) {
        cell.checked = NO;
        [selectedComments removeObject:comment];
    } else {
        cell.checked = YES;
        [selectedComments addObject:comment];
    }
    
    [self updateSelectedComments];
}

- (void)calculateSections {
    NSMutableDictionary *dates = [[NSMutableDictionary alloc] init];
    NSMutableArray *sectionDateMapping = [[NSMutableArray alloc] init];
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateStyle:NSDateFormatterLongStyle];
    
    for (NSDictionary *comment in commentsArray) {
        NSString *dateString = [dateFormat stringFromDate:[comment objectForKey:@"date_created_gmt"]];
        
        if ([dates objectForKey:dateString] == nil) {
            [dates setObject:[NSNumber numberWithInt:[dates count]] forKey:dateString];
            
            NSMutableDictionary *commentContainer = [[NSMutableDictionary alloc] init];
            [commentContainer setObject:dateString forKey:@"date"];
            [commentContainer setObject:[NSNumber numberWithInt:1] forKey:@"numberOfComments"];
            [commentContainer setObject:comment forKey:@"0"];
            
            [sectionDateMapping addObject:commentContainer];
            [commentContainer release];
        }
        else {
            int dateArrayIndex = [[dates objectForKey:dateString] intValue];
            NSNumber *numberOfComments = [NSNumber numberWithInt:[[[sectionDateMapping objectAtIndex:dateArrayIndex] objectForKey:@"numberOfComments"] intValue] +1];
            [[sectionDateMapping objectAtIndex:dateArrayIndex] setObject:numberOfComments forKey:@"numberOfComments"];
            [[sectionDateMapping objectAtIndex:dateArrayIndex] setObject:comment forKey:[NSString stringWithFormat:@"%i", [numberOfComments intValue] -1]];
        }
    }
    self.sectionHeaders = sectionDateMapping;
    
    [dateFormat release];
    [sectionDateMapping release];
    [dates release];
}

#pragma mark -
#pragma mark accessors

- (void)setIndexForCurrentPost:(int)index {
    indexForCurrentPost = index;
}

@end