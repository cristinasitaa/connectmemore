//
//  PersonsViewController.m
//  ConnectMeMore
//
//  Created by Adi Ispas on 7/9/14.
//  Copyright (c) 2014 Lateral. All rights reserved.
//

#import "MissedCallsViewController.h"
#import "KeychainItemWrapper.h"
#import "ContactsViewController.h"


@interface MissedCallsViewController ()

@end

@implementation MissedCallsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkStatusChanged:) name:kNetworkUnavailableNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkStatusChanged:) name:kNetworkAvailableNotification object:nil];

    if ([SharedAppDelegate.connected boolValue]){
        [self getData];
    } else {
        [self.view bringSubviewToFront:self.noHistoeyView];
    }
    
    [self buildUI];
    
}

- (void)getData {
//    [self.activityIndicator startAnimating];
    
    [DejalActivityView activityViewForView:self.view];
    
    [UserManager getCallHistoryWithCompletitionBlock:^(id serializedObj, NSError *error, id returnedUser) {
        if (!serializedObj || error){
            
        } else {
//            [self.activityIndicator stopAnimating];
            [DejalActivityView removeView];
            _missedCalls = (NSMutableArray *)serializedObj;
            [self.tableView reloadData];
        }
    }];
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNetworkAvailableNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNetworkUnavailableNotification object:nil];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UI
- (void) buildUI{
    
    if (![_missedCalls count]){
//        [self.activityIndicator startAnimating];
        [DejalActivityView activityViewForView:self.view];
//        self.activityIndicator.hidesWhenStopped = YES;
    } else{
//        [self.activityIndicator stopAnimating];
        [DejalActivityView removeView];
    }

    CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
    if (screenRect.size.height < 548)
    {
        CGRect frame = self.tableView.frame;
        frame.size.height = 406;
        self.tableView.frame = frame;
    }

    
    //register cells
    [self.tableView registerNib:[UINib nibWithNibName:@"PersonTableViewCell"
                                               bundle:[NSBundle mainBundle]]
         forCellReuseIdentifier:@"Cell"];
    
    [self.searchDisplayController.searchResultsTableView registerNib:[UINib nibWithNibName:@"PersonTableViewCell"
                                                                                    bundle:[NSBundle mainBundle]]
                                              forCellReuseIdentifier:@"Cell"];
    
    //set footer
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
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

    return _missedCalls.count;

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PersonTableViewCell *cell = (PersonTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (!cell) {
        cell = [[PersonTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    
    cell.personPicture.layer.cornerRadius = cell.personPicture.frame.size.height/2;;
    cell.personPicture.layer.masksToBounds = YES;
    cell.statusImage.hidden = YES;
    
    MissedCall *missedCall = _missedCalls[indexPath.row];
    
    if (missedCall.avatar.length){
        [cell.personPicture sd_setImageWithURL:[NSURL URLWithString:missedCall.avatar] placeholderImage:[UIImage imageNamed:@"contacts.png"]];
    } else {
        cell.personPicture.image = [UIImage imageNamed:@"contacts.png"];
    }
    
    cell.personName.text = missedCall.name;

  
    cell.timeLabel.text = [self getDateForCall:missedCall];
    cell.timeLabel.textColor = [self getColorForCall:missedCall];
    
    
    missedCall = nil;
    
    return cell;
}

- (NSString *) getDateForCall:(MissedCall *)missedCall{
//    NSString *dateString = [missedCall.time componentsSeparatedByString:@" "][0];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    // this is imporant - we set our input date format to match our input string
    // if format doesn't match you'll get nil from your string, so be careful
    dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *date = [dateFormatter dateFromString:missedCall.time]; // UTC date
    NSDate *date2 = [date dateByAddingTimeInterval:[[NSTimeZone localTimeZone] secondsFromGMTForDate:date]]; // local date!

    [dateFormatter setDateFormat:@"MMM dd, yyyy 'at' HH:mm:ss"];
    
//    NSDate *dateFromString = [[NSDate alloc] init];
//    // voila!
//    dateFromString = [dateFormatter dateFromString:dateString];
//    
//    dateFormatter = [[NSDateFormatter alloc] init];
//    [dateFormatter setDateFormat:@"MMM dd, yyyy"];
//    NSString *stringDate = [dateFormatter stringFromDate:[NSDate date]];
//    
//    dateString = [missedCall.time componentsSeparatedByString:@" "][1];
//    [dateFormatter setDateFormat:@"MMM dd, yyyy"];
    
//    stringDate = [stringDate stringByAppendingString:[NSString stringWithFormat:@" at %@",dateString]];
    
    NSString *stringDate = [dateFormatter stringFromDate:date2];
    
   return [NSString stringWithFormat:@"%@ call on %@", missedCall.type, stringDate];
    
}

- (UIColor *)getColorForCall:(MissedCall *)missedCall{
    if ([missedCall.type isEqualToString:@"missed"]){
        return  [UIColor redColor];
    } else if ([missedCall.type isEqualToString:@"incoming"]){
        return [UIColor greenColor];
    } else if ([missedCall.type isEqualToString:@"outgoing"]){
        return  [UIColor blueColor];
    }
    return nil;

}

/*
- (NSString *)checkDateForLastCall:(NSString *)time {
    NSString *dateString = @"";
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    NSDate *dateOfCall = [[NSDate alloc] init];
    dateOfCall = [formatter dateFromString:time];
    if ([dateOfCall isToday]){
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"HH:mm a"];
        dateString = [formatter stringFromDate:dateOfCall];
    } else{
        formatter = [[NSDateFormatter alloc] init];
        
        [formatter setDateFormat:@"MMM"];
        dateString = [formatter stringFromDate:dateOfCall];
        
        dateString = [dateString stringByAppendingString:@" "];
        
        [formatter setDateFormat:@"dd"];
        dateString = [dateString stringByAppendingString:[formatter stringFromDate:dateOfCall]];
    }
    
    formatter = nil;
    dateOfCall = nil;
    
    return dateString;

}
 
*/

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
        return 80;
}

-(void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row){
//        [self.activityIndicator stopAnimating];
        [DejalActivityView removeView];
    }
}

#pragma mark TODO: didselectrow
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MissedCall *missedCall = [_missedCalls objectAtIndex:indexPath.row];
    BaseViewController *parentBaseVC = (BaseViewController *)self.parentViewController;
    parentBaseVC.passedMissedCall = missedCall;
    [parentBaseVC showContacts:nil];
    
}

- (void) networkStatusChanged:(NSNotification *)note{
    if ([SharedAppDelegate.connected boolValue]){
        [self getData];
        [self.view sendSubviewToBack:self.noHistoeyView];
    } else {
        [self.view bringSubviewToFront:self.noHistoeyView];
    }
}


- (void)dealloc{
    _missedCalls = nil;
    _tableView.delegate = nil;
    _tableView.dataSource = nil;
    _tableView = nil;
    _activityIndicator = nil;
    _noHistoeyView = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
