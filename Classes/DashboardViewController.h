//
//  DashboardViewController.h
//  WordPress
//
//  Created by Gareth Townsend on 23/07/09.
//

#import <UIKit/UIKit.h>
#import "CommentsTableViewDelegate.h"
#import "RefreshButtonView.h"

@interface DashboardViewController : UIViewController <UITableViewDataSource, CommentsTableViewDelegate> {
@private
    IBOutlet UITableView *commentsTableView;
    
    IBOutlet UIToolbar *editToolbar;
    UIBarButtonItem *editButtonItem;
    RefreshButtonView *refreshButton;
    
    IBOutlet UIBarButtonItem *approveButton;
    IBOutlet UIBarButtonItem *unapproveButton;
    IBOutlet UIBarButtonItem *spamButton;
    IBOutlet UIButton *deleteButton;
    
    BOOL editing;
    
    NSMutableArray *commentsArray;
    NSMutableDictionary *commentsDict;
    NSMutableArray *selectedComments;
    
    UIAlertView *progressAlert;
    
    int indexForCurrentPost;
    
    NSMutableArray *sectionHeaders;
}

@property (readonly) UIBarButtonItem *editButtonItem;
@property (nonatomic, retain) NSMutableArray *selectedComments;
@property (nonatomic, retain) NSMutableArray *commentsArray;
@property (nonatomic, retain) NSMutableArray *sectionHeaders;

- (IBAction)deleteSelectedComments:(id)sender;
- (IBAction)approveSelectedComments:(id)sender;
- (IBAction)unapproveSelectedComments:(id)sender;
- (IBAction)spamSelectedComments:(id)sender;

- (void)setIndexForCurrentPost:(int)index;

@end