//
//  AppDelegate.h
//  ConnectMeMore
//
//  Created by Adi Ispas on 7/9/14.
//  Copyright (c) 2014 Lateral. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserManager.h"
#import "User.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import <CoreData/CoreData.h>
#import "XMPPManager.h"
#import "Reachability.h"
#import "Message.h"
#import "SRWebSocket.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) User *currentUser;
@property (strong, nonatomic) NSString *sessionID;
@property (strong, nonatomic) NSString *deviceToken;
@property (strong, nonatomic) Reachability *internetReachableFoo;
@property (strong, nonatomic) SRWebSocket *webSocket;
@property (strong, nonatomic) NSNumber *socketIsOpen;
@property (strong, nonatomic) Reachability *reachability;
@property (strong, nonatomic) NSNumber *connected;
@property (assign, nonatomic) UIBackgroundTaskIdentifier backgroundTask;
@property (assign, nonatomic) NSTimer *backgroundTimer;
@property (strong, nonatomic) NSTimer *callHeartbeatTimer;
@property (assign, nonatomic) BOOL inCall;

//- (void) reconnectToWebSocket;

@end
