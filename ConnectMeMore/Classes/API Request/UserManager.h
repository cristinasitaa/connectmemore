//
//  UserManager.h
//  ConnectMeMore
//
//  Created by Cristina Sita on 14/08/2014.
//  Copyright (c) 2014 Lateral. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"

typedef void(^returnBlock)(id serializedObj,NSError *error,id returnedUser);

@interface UserManager : NSObject


// create account
+ (void) createAccountForUser:(User *)user withCompletitionBlock:(returnBlock)aBlock;
//login + logout
+ (void) loginWithUser: (User *)user withCompletitionBlock:(returnBlock)aBlock;
+ (void) logoutUser:(User *)user withCompletitionBlock:(returnBlock)aBlock;

//get profile
+ (void) getProfileForUser: (User *)user withCompletitionBlock:(returnBlock)aBlock;

//invites
+ (void) inviteUserWithEmail:(NSString *)email fromUser:(User *)currentUser withCompletitionBlock:(returnBlock)aBlock;
+ (void) cancelInviteWithID:(NSNumber *)inviteID fromUser: (User *)currentUser withCompletitionBlock:(returnBlock)aBlock;

//contacts
+ (void) getContactsForUser:(User *)currentUser withCompletitionBlock:(returnBlock) aBlock;

//calls
+ (void) initiateCallWithUser:(User *)secondUser withCompletitionBlock:(returnBlock) aBlock;
+ (void) receiveCallFromUserCallID:(NSString *)callID withCompletitionBlock:(returnBlock) aBlock;
+ (void) dropCallForCallID:(NSString *)callID withCompletitionBlock:(returnBlock) aBlock;
+ (void) answerCallForCallID:(NSString *)callID withCompletitionBlock:(returnBlock) aBlock;
+ (void) callHeartBeatWithCompletitionBlock:(returnBlock) aBlock;

//history
+ (void) getCallHistoryWithCompletitionBlock:(returnBlock) aBlock;

//user status
+ (void) setUserBusyWithCompletitionBlock:(returnBlock) aBlock;
+ (void) setUserAvailableWithCompletitionBlock:(returnBlock) aBlock;

+ (void)sendPresence:(NSString *)type;

@end
