//
//  ContactsViewController.h
//  ConnectMeMore
//
//  Created by Cristina Sita on 19/08/2014.
//  Copyright (c) 2014 Lateral. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"
#import "MissedCall.h"

@interface ContactsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate,NSFetchedResultsControllerDelegate, UISearchBarDelegate> {
    NSFetchedResultsController *fetchedResultsController;
}


@property (weak, nonatomic) IBOutlet UITableView *contactsTableView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIView *noInternetConnectionView;

@property (strong, nonatomic) NSTimer *contactsTimer;
@property (strong, nonatomic) NSArray *contactsArray;

@property (strong, nonatomic) MissedCall *passedMissedCall;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableHeightConstraint;

@end
