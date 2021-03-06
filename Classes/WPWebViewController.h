//
//  WPWebViewController.h
//  WordPress
//
//  Created by Jorge Bernal on 6/16/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface WPWebViewController : UIViewController<UIWebViewDelegate, UIActionSheetDelegate> {
    BOOL isLoading;
}
@property (nonatomic,retain) NSURL *url;
@property (nonatomic,retain) NSString *username;
@property (nonatomic,retain) NSString *password;
@property (nonatomic,retain) IBOutlet UIWebView *webView;
@property (nonatomic,retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic,retain) IBOutlet UIView *loadingView;
@property (nonatomic,retain) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic,retain) IBOutlet UILabel *loadingLabel;
@property (nonatomic,assign) BOOL needsLogin;
@property (nonatomic,assign) BOOL isReader;
@property (nonatomic, retain) IBOutlet UINavigationBar *iPadNavBar;

- (IBAction)showLinkOptions;
- (IBAction)dismiss;

@end
