//
//  User.m
//  ConnectMeMore
//
//  Created by Cristina Sita on 14/08/2014.
//  Copyright (c) 2014 Lateral. All rights reserved.
//

#import "User.h"

@implementation User

- (id) initWithEmail:(NSString *)email andPassword:(NSString *)password{
    self = [super init];
    if (self){
        _email = email;
        _password = password;
    }
    return self;
}

- (id)initWithUser:(User *)user{
    self = [super init];
    if (self){
        _userID = user.userID;
        _name = user.name;
        _email = user.email;
        _password = user.password;
        _avatarURL = user.avatarURL;
        _deviceID = user.deviceID;
        _token = user.token;
        _isOnline = user.isOnline;
        _status = user.status;
    }
    return self;
}

- (id)userFromXMPPUser:(XMPPUserCoreDataStorageObject *)xmppUser {
    
    if (self == nil) {
        return nil;
    }
    _userID = xmppUser.jid.user;
    _name = xmppUser.nickname;
    _isOnline = xmppUser.sectionNum;
    _jidStr = xmppUser.jidStr;
    return self;
    
}

@end
