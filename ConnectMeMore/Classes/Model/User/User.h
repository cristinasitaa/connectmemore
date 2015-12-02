//
//  User.h
//  ConnectMeMore
//
//  Created by Cristina Sita on 14/08/2014.
//  Copyright (c) 2014 Lateral. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPUserCoreDataStorageObject.h"

@interface User : NSObject

@property (strong, nonatomic) NSString  *userID;
@property (strong, nonatomic) NSString  *name;
@property (strong, nonatomic) NSString  *email;
@property (strong, nonatomic) NSString  *password;
@property (strong, nonatomic) NSString  *avatarURL;
@property (strong, nonatomic) NSString  *deviceID;
@property (strong, nonatomic) NSString  *token;
@property (strong, nonatomic) NSNumber  *isOnline; // 0:available, 1: away, 2:offline
@property (strong, nonatomic) NSNumber  *status;
@property (strong, nonatomic) NSString  *jidStr;
@property (strong, nonatomic) NSString  *callID;
@property (strong, nonatomic) UIImage   *avatar;

- (id)initWithEmail:(NSString *)email andPassword:(NSString *)password;
- (id)initWithUser:(User *)user;
- (id)userFromXMPPUser:(XMPPUserCoreDataStorageObject *)xmppUser;
@end
