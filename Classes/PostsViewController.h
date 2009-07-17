#import <Foundation/Foundation.h>
#import "RefreshButtonView.h"

@class BlogDataManager, PostViewController, PostDetailEditController, DraftsListController;

@interface PostsViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate> {
    UIBarButtonItem *newButtonItem;

    IBOutlet UITableView *postsTableView;

    PostViewController *postDetailViewController;
    PostDetailEditController *postDetailEditController;
    RefreshButtonView *refreshButton;
}

@property (readonly) UIBarButtonItem *newButtonItem;
@property (nonatomic, retain) PostViewController *postDetailViewController;
@property (nonatomic, retain) PostDetailEditController *postDetailEditController;

@end
