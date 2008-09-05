//
//  CommentsListController.h
//  WordPress
//
//  Created by Janakiram on 02/09/08.
//  Copyright 2008 Effigent. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface CommentsListController : UIViewController {

	IBOutlet UITableView *commentsTableView;

	IBOutlet UIBarButtonItem *syncPostsButton;
	IBOutlet UIBarButtonItem *commentStatusButton;
	
	NSMutableArray *commentsList;
//    NSMutableArray *commentDetails;
    
	BOOL connectionStatus;
}

//@property (nonatomic, retain) NSMutableArray *commentDetails;

- (IBAction)downloadRecentComments:(id)sender;

@end