//
//  AppDelegate.m
//  ConnectMeMore
//
//  Created by Adi Ispas on 7/9/14.
//  Copyright (c) 2014 Lateral. All rights reserved.
//

#import "AppDelegate.h"
#import "KeychainItemWrapper.h"
#import "ContactsViewController.h"
#import "LoginViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "CallViewController.h"
#import "XMPPManager.h"


@implementation AppDelegate

#pragma mark - appDelegate methods
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    [self setUpRechability];
    
    // Register for push notifications
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert |
                                                        UIUserNotificationTypeBadge |
                                                        UIUserNotificationTypeSound);
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes
                                                                                 categories:nil];
        [application registerUserNotificationSettings:settings];
        
    } else {
        [application registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                                         UIRemoteNotificationTypeAlert |
                                                         UIRemoteNotificationTypeSound)];
    }
    
    [[XMPPManager sharedInstance] setupStream];
    
    // Override point for customization after application launch.
    // retrieve values from keychain
    KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:@"CMM-Lateral-inc2" accessGroup:nil];
    NSString *password = [keychainItem objectForKey:(__bridge id)kSecValueData];
    NSString *mail = [keychainItem objectForKey:(__bridge id)kSecAttrAccount];

    if (password.length && mail.length){
        //user saved in keychain, show Recent Contacts
        User *oldUser = [[User alloc] initWithEmail:mail andPassword:password];
        [UserManager loginWithUser:oldUser withCompletitionBlock:^(id serializedObj, NSError *error, id returnedUser) {
            if ([serializedObj[@"error"] boolValue] == YES || !serializedObj){
                LoginViewController *loginController = [[LoginViewController alloc] init];
                UINavigationController *loginNav = [[UINavigationController alloc] initWithRootViewController:loginController];
                self.window.rootViewController = loginNav;
            } else if (error == nil) {
                NSLog(@"SUCCESS");
                BaseViewController *baseController = [[BaseViewController alloc] init];
                UINavigationController *contactsNav = [[UINavigationController alloc] initWithRootViewController:baseController];
                self.window.rootViewController = contactsNav;
            }
        }];
    } else {
        // no user saved in keychain, show Login
        LoginViewController *loginController = [[LoginViewController alloc] init];
        UINavigationController *loginNav = [[UINavigationController alloc] initWithRootViewController:loginController];
        self.window.rootViewController = loginNav;

    }
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
//    [[AVAudioSession sharedInstance] setActive:NO error:nil];
    
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    if ([[self getTopController] isKindOfClass:[CallViewController class]]){
        CallViewController * callVC = (CallViewController *)[self getTopController];
        [callVC endCallButtonPressed:nil];
    }


    NSLog(@"Application entered background state.");
    NSAssert(self.backgroundTask == UIBackgroundTaskInvalid, nil);

    
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)timerUpdate:(id)sender {
    
    if (![[[XMPPManager sharedInstance] xmppStream] isConnected]) {
        [[XMPPManager sharedInstance] goOnline];
    }
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [[UIApplication sharedApplication] clearKeepAliveTimeout];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
//    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber: 0];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - PushNotifications
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"device registered for APNS with token %@", deviceToken);
    
    NSString *tokenString = [NSString stringWithFormat:@"%@", deviceToken];
    tokenString = [tokenString stringByReplacingOccurrencesOfString:@" " withString:@""];
    tokenString = [tokenString stringByReplacingOccurrencesOfString:@"<" withString:@""];
    tokenString = [tokenString stringByReplacingOccurrencesOfString:@">" withString:@""];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:tokenString forKey:pushNotifTokenKey];
    [defaults synchronize];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"device failed to register for APNS with error %@", [error localizedDescription]);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    
    NSLog(@"Remote notification userInfo is%@",userInfo);
    
    completionHandler(UIBackgroundFetchResultNewData);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    
    if (application.applicationState == UIApplicationStateActive){
    
    } else {
        NSLog(@"opened from inactive");
    }
}

#pragma mark - Heartbeat
- (void) callHeartBeat:(NSTimer *)timer {
    [UserManager callHeartBeatWithCompletitionBlock:^(id serializedObj, NSError *error, id returnedUser) {
        if (serializedObj){
            if ([serializedObj[@"status"] isEqualToString:@"incoming"]){
                if (![[self getTopController] isKindOfClass:[CallViewController class]]){
                    NSLog(@"Post notific");
                    [[NSNotificationCenter defaultCenter] postNotificationName:kShowCallVCNotification object:nil userInfo:serializedObj];
                }
            }
        } else if (error){
            if ([[self getTopController] isKindOfClass:[CallViewController class]]){
                CallViewController * callVC = (CallViewController *)[self getTopController];
                [callVC endCallButtonPressed:nil];
            }
            
        }
    }];
}

#pragma mark - helper methods
- (UIViewController*) getTopController
{
    UIViewController *topViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    while (topViewController.presentedViewController) {
        topViewController = topViewController.presentedViewController;
    }
    
    return topViewController;
}


#pragma mark - Reachability & Network

-(void)setUpRechability
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNetworkChange:) name:kReachabilityChangedNotification object:nil];
    
    _reachability = [Reachability reachabilityForInternetConnection];
    [_reachability startNotifier];
    
    NetworkStatus remoteHostStatus = [_reachability currentReachabilityStatus];
    
    if (remoteHostStatus == NotReachable){
        self.connected = [NSNumber numberWithBool:NO];
    }
    else if (remoteHostStatus == ReachableViaWiFi)  {
        self.connected = [NSNumber numberWithBool:YES];
    }
    else if (remoteHostStatus == ReachableViaWWAN)  {
        self.connected = [NSNumber numberWithBool:YES];
    }
    
}

- (void) handleNetworkChange:(NSNotification *)notice
{
    NetworkStatus remoteHostStatus = [_reachability currentReachabilityStatus];
    
    if (remoteHostStatus == NotReachable){
        self.connected = [NSNumber numberWithBool:NO];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNetworkUnavailableNotification object:nil];
    }
    else if (remoteHostStatus == ReachableViaWiFi)  {
        self.connected = [NSNumber numberWithBool:YES];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNetworkAvailableNotification object:nil];

    }
    else if (remoteHostStatus == ReachableViaWWAN)  {
        self.connected = [NSNumber numberWithBool:YES];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNetworkAvailableNotification object:nil];
    }
    
    NSLog(@"%@",remoteHostStatus);
    
}



@end
