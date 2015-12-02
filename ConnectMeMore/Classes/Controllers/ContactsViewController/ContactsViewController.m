//
//  ContactsViewController.m
//  ConnectMeMore
//
//  Created by Cristina Sita on 19/08/2014.
//  Copyright (c) 2014 Lateral. All rights reserved.
//

#import "ContactsViewController.h"
#import "KeychainItemWrapper.h"
#import "MissedCallsViewController.h"
#import "CustomTableViewCell.h"
#import "UIImageView+WebCache.h"
#import "User.h"

@implementation ContactsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:@"ContactsViewController" bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    
    
    [self buildUI];
    
//    [self fetchedResultsController];
    
}

- (void)viewWillAppear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkStatusChanged:) name:kNetworkUnavailableNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkStatusChanged:) name:kNetworkAvailableNotification object:nil];

    if ([SharedAppDelegate.connected boolValue]){
//        [self startTimer];
        [self.view sendSubviewToBack:self.noInternetConnectionView];
        [self.view bringSubviewToFront:self.contactsTableView];
    } else{
        [self.contactsTimer invalidate];
        self.contactsTimer = nil;
        [self.view bringSubviewToFront:self.noInternetConnectionView];
    }
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (!SharedAppDelegate.currentUser) {
        LoginViewController *loginController = [[LoginViewController alloc] init];
        [self.navigationController presentViewController:loginController animated:NO completion:nil];
    } else {
  
    }
    
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNetworkUnavailableNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNetworkAvailableNotification object:nil];
    [self.contactsTimer invalidate];
}




#pragma mark - UI
- (void)buildUI {

    
    if (![[[XMPPManager sharedInstance] xmppStream] isConnected]) {
        [DejalActivityView activityViewForView:self.contactsTableView withLabel:@"Connecting..."];
    } else {
        [DejalActivityView removeView];
    }
    
//    [DejalActivityView activityViewForView:self.contactsTableView];
    
//    if (![_contactsArray count]){
//        self.activityIndicator.hidden = NO;
//        [self.view bringSubviewToFront:self.activityIndicator];
//        [self.activityIndicator startAnimating];
//        self.activityIndicator.hidesWhenStopped = YES;
//    } else{
//        [self.activityIndicator stopAnimating];
//    }
    
    CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
    if (screenRect.size.height < 548)
    {
        CGRect frame = self.contactsTableView.frame;
        frame.size.height = 406;
        self.contactsTableView.frame = frame;
    }
    
    //register cells
    [self.contactsTableView registerNib:[UINib nibWithNibName:@"CustomTableViewCell" bundle:nil] forCellReuseIdentifier:@"ContactTableViewCell"];


    //set footer
    self.contactsTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.searchDisplayController.searchResultsTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}


# pragma mark - UITableViewDelegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [[[self fetchedResultsController] fetchedObjects] count];
    
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CustomTableViewCell *cell = (CustomTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"ContactTableViewCell" forIndexPath:indexPath];

    
    if (!cell.nameLabel) {
        cell = [[CustomTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ContactTableViewCell"];
    }

//    User *connection = _contactsArray[indexPath.row];
    XMPPUserCoreDataStorageObject *user = [[self fetchedResultsController] objectAtIndexPath:indexPath];
    User *connection = [[User alloc] userFromXMPPUser:user];

    cell.personPicture.layer.cornerRadius = cell.personPicture.frame.size.height/2;;
    cell.personPicture.layer.masksToBounds = YES;
    
    if (connection.isOnline.intValue == 0 || connection.isOnline.intValue == 1) {
        cell.statusImage.image = [UIImage imageNamed:@"Oval 1 + Oval 2 + Shape.png"];
    } else {
        cell.statusImage.image = [UIImage imageNamed:@"Fill 2 + Contact Name 4.png"];
    }
    
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@user/profile/%@/avatar",kbaseURL,connection.userID]];
    [cell.personPicture sd_setImageWithURL:url placeholderImage:[UIImage imageNamed:@"contacts.png"] options:SDWebImageRefreshCached completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        connection.avatar = image;
    }];
    
    cell.nameLabel.text = connection.name;
    
    connection = nil;
    
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80;
}

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row){
        [self.activityIndicator stopAnimating];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
//    User *secondUser = _contactsArray[indexPath.row];
    
    XMPPUserCoreDataStorageObject *user = [[self fetchedResultsController] objectAtIndexPath:indexPath];
    User *secondUser = [[User alloc] userFromXMPPUser:user];
    
    if (secondUser.isOnline.intValue == 2) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"The user you are trying to reach is not available." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    
    [DejalActivityView activityViewForView:self.view withLabel:@"Connecting..."];
    
    [UserManager initiateCallWithUser:secondUser withCompletitionBlock:^(id serializedObj, NSError *error, id returnedUser) {
        [DejalActivityView removeView];
        
         if (serializedObj && !error) {
            NSString *sessionID = serializedObj[@"session"];
            NSString *token = serializedObj[@"token"];
            NSString *callId = serializedObj[@"callID"];
            SharedAppDelegate.sessionID = sessionID;
            SharedAppDelegate.deviceToken = token;
            secondUser.callID = callId;

            NSMutableDictionary *messageDict = [NSMutableDictionary dictionary];
            messageDict[@"actionType"] = MAKE_CALL;
            messageDict[@"openTokSessionId"] = sessionID;
            messageDict[@"openTokTokenId"] = token;
            messageDict[@"callId"] = callId;

            [[XMPPManager sharedInstance] sendMessage:messageDict toUser:secondUser];

            NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:@{@"name":secondUser.name, @"callID":callId, @"status":@"outgoing"}];

            [[NSNotificationCenter defaultCenter] postNotificationName:kShowCallVCNotification object:user userInfo:userInfo];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"The user you want to reach is no longer available." delegate:nil cancelButtonTitle:@"Ok." otherButtonTitles: nil];
            [alert show];
        }
        
    }];
}



//- (NSIndexPath *)indexPathToBeSelected {
//    NSIndexPath *indexPath = [[NSIndexPath alloc] init];
//    int indexRow = 0;
//    for (User *user in _contactsArray){
//        if ([user.name isEqualToString:self.passedMissedCall.name] && [user.avatarURL isEqualToString:self.passedMissedCall.avatar]){
//            indexRow = (int)[_contactsArray indexOfObject:user];
//            break;
//        }
//    }
//    indexPath = [NSIndexPath indexPathForRow:indexRow inSection:0];
//    return indexPath;
//}


//#pragma mark - check for contacts
//- (void)checkForContacts: (NSTimer *)timer {
//    
//    if ([SharedAppDelegate.connected boolValue]){
//        [UserManager getContactsForUser:SharedAppDelegate.currentUser withCompletitionBlock:^(id serializedObj, NSError *error, id returnedUser) {
//            if (!serializedObj || error){
//                NSLog(@"error from get contacts %@",error);
//            } else if (error == nil){
//                self.contactsArray = (NSMutableArray *)serializedObj;
//                [self.contactsTableView reloadData];
//                [self.view sendSubviewToBack:self.noInternetConnectionView];
//                if (self.passedMissedCall){
//                    [self.contactsTableView selectRowAtIndexPath:[self indexPathToBeSelected] animated:YES scrollPosition:UITableViewScrollPositionTop];
//                    self.passedMissedCall = nil;
//                }
//                
//            }
//        }];
//    }
//    
//}

//- (void) startTimer{
//    self.contactsTimer = [NSTimer scheduledTimerWithTimeInterval:15.0f
//                                                          target:self
//                                                        selector:@selector(checkForContacts:)
//                                                        userInfo:nil
//                                                         repeats:YES];
//    [self.contactsTimer fire];
//    
//}

#pragma mark - Network
- (void)networkStatusChanged:(NSNotification *)note {
    if ([SharedAppDelegate.connected boolValue]){
//        [self startTimer];
        [self.view sendSubviewToBack:self.noInternetConnectionView];
    } else {
        [self.contactsTimer invalidate];
        self.contactsTimer = nil;
        [self.view bringSubviewToFront:self.noInternetConnectionView];
    }
}

#pragma mark - dealloc
- (void)dealloc{
    
    _activityIndicator = nil;
    _contactsTimer = nil;
    _contactsArray = nil;
    _noInternetConnectionView = nil;
    _contactsTableView.delegate = nil;
    _contactsTableView.dataSource = nil;
    _contactsTableView = nil;
    _passedMissedCall = nil;
}


#pragma mark -
#pragma mark - NSFetchedResultsController

- (NSFetchedResultsController *)fetchedResultsController {
    
    if (fetchedResultsController == nil) {
        NSManagedObjectContext *moc = [[XMPPManager sharedInstance] managedObjectContext_roster];
        
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorageObject"
                                                  inManagedObjectContext:moc];
        
        NSSortDescriptor *sd1 = [[NSSortDescriptor alloc] initWithKey:@"sectionNum" ascending:YES];
        NSSortDescriptor *sd2 = [[NSSortDescriptor alloc] initWithKey:@"displayName" ascending:YES];
        
        NSArray *sortDescriptors = [NSArray arrayWithObjects:sd1,sd2, nil];
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:entity];
        [fetchRequest setSortDescriptors:sortDescriptors];
        [fetchRequest setFetchBatchSize:10];
        
        fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                       managedObjectContext:moc
                                                                         sectionNameKeyPath:nil
                                                                                  cacheName:nil];
        [fetchedResultsController setDelegate:self];
        
        
        NSError *error = nil;
        if (![fetchedResultsController performFetch:&error])
        {
            NSLog(@"Error performing fetch: %@", error);
        }
        
    }

    return fetchedResultsController;
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.contactsTableView reloadData];
    
//    if ([[XMPPManager sharedInstance] isConnected]) {
        [DejalActivityView removeView];
//    }
    

    if (SharedAppDelegate.currentUser.status.intValue != 1) {
        [UserManager sendPresence:@"unavailable"];
    }
    
}

@end
