//
//  PersonsViewController.h
//  ConnectMeMore
//
//  Created by Adi Ispas on 7/9/14.
//  Copyright (c) 2014 Lateral. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CallViewController.h"
#import "LoginViewController.h"
#import "PersonTableViewCell.h"
#import "NSDate+Utilities.h"
#import "User.h"
#import "BaseViewController.h"
#import "UserManager.h"
#import "MissedCall.h"
#import "UIImageView+WebCache.h"


@interface MissedCallsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSMutableArray *missedCalls;



//IBOutlets
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIView *noHistoeyView;

@end
