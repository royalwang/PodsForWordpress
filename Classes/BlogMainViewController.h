//
//  BlogMainViewController.h
//  WordPress
//
//  Created by Janakiram on 01/09/08.
//  Copyright 2008 Effigent. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BlogDataManager, WordPressAppDelegate, BlogDetailModalViewController, BlogMainViewController,PostsListController,CommentsListController;

@interface BlogMainViewController : UIViewController {
	IBOutlet UITableView *postsTableView;
	PostsListController *postsListController;	
	CommentsListController *commentsListController;	
	NSArray *blogMainMenuContents;
}

@property (nonatomic, retain) PostsListController *postsListController;
@property (nonatomic, retain) CommentsListController *commentsListController;

@end