
//  UserManager.m
//  ConnectMeMore
//
//  Created by Cristina Sita on 14/08/2014.
//  Copyright (c) 2014 Lateral. All rights reserved.
//

#import "UserManager.h"
#import "AFNetworking.h"
#import "NSString+URLEncoding.h"
#import "User.h"
#import "MissedCall.h"

@implementation UserManager


+ (void)createAccountForUser:(User *)user withCompletitionBlock:(returnBlock)aBlock {
    NSString *urlString = [NSString stringWithFormat:@"%@user/register", kbaseURL];
     NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"name":user.name,
                                                                                   @"email":user.email,
                                                                                   @"password":user.password,
                                                                                   @"password_confirm":user.password,
                                                                                   @"device_id":user.deviceID}];
    
    NSMutableURLRequest *uploadCompanyRequest = [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:@"POST"
                                                                                                           URLString:urlString parameters:params
                                                                                           constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
    
    } error:nil];
    
    AFHTTPRequestOperation *operationLogo = [[AFHTTPRequestOperation alloc] initWithRequest:uploadCompanyRequest];
    [operationLogo setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:nil];
        NSLog(@"%@",dict);
       
        [self setCurrentUser:dict];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error);
    }];
    [operationLogo start];

}

+ (void) loginWithUser:(User *)user withCompletitionBlock:(returnBlock)aBlock {
    NSString *urlString = [NSString stringWithFormat:@"%@user/login",kbaseURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"email"] = user.email;
    params[@"password"] = user.password;
    params[@"type"] = @3;
    if ([[NSUserDefaults standardUserDefaults] valueForKey:pushNotifTokenKey]) {
        params[@"device_token"] = [[NSUserDefaults standardUserDefaults] valueForKey:pushNotifTokenKey];
    }
    
    [request setHTTPBody:[self encodeParameters:params]];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setHTTPMethod:@"POST"];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *userDict = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:nil];
        NSLog(@"RESPONSE FROM SIGN IN %@",userDict);
        
        [self setCurrentUser:userDict];
        
        if (SharedAppDelegate.currentUser.status.intValue != 1) {
            
        }
        
        [[NSUserDefaults standardUserDefaults] setValue:[NSString stringWithFormat:@"%@@%@",userDict[@"user"][@"id"],xmppHostName] forKey:kXMPPmyJID];
        [[NSUserDefaults standardUserDefaults] setValue:userDict[@"user"][@"id"] forKey:kXMPPmyPassword];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[XMPPManager sharedInstance] connect];
    
        aBlock(userDict[@"user"],nil, user);
        userDict = nil;
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"error%@",error);
        
        aBlock(nil,error, user);
    }];
    [operation start];
    
    request = nil;
    urlString = nil;

}

+ (void)logoutUser:(User *)user withCompletitionBlock:(returnBlock)aBlock{
    NSString *urlString = [NSString stringWithFormat:@"%@user/logout", kbaseURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[self encodeParameters:@{@"Access-Token": user.token}]];
    [request setValue:user.token forHTTPHeaderField:@"Access-Token"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *userDict = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:nil];
        NSLog(@"%@",userDict);
        aBlock(userDict,nil, nil);
        userDict = nil;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error);
        aBlock(nil,error, nil);
    }];
    [operation start];
    
    request = nil;
    urlString = nil;
}

+ (void) getProfileForUser: (User *)user withCompletitionBlock:(returnBlock)aBlock{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@user/profile",kbaseURL]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:user.token forHTTPHeaderField:@"Access-Token"];
    [request setHTTPMethod:@"GET"];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation.securityPolicy setAllowInvalidCertificates:YES];
    
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Received %lu bytes from %@ (getClients)", (unsigned long)[responseObject length], operation.request.URL.absoluteString);
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        NSDictionary *userDict = [[NSDictionary alloc] init];
        
        NSError* error = nil;
        
        userDict = [NSJSONSerialization JSONObjectWithData:responseObject
                                                   options:NSJSONReadingAllowFragments error:&error];
        NSLog(@"%@",userDict);
        [self setCurrentUser:userDict];
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"error%@",error);
    }];
    
    [operation start];

}

+ (void) inviteUserWithEmail:(NSString *)email fromUser:(User *)currentUser withCompletitionBlock:(returnBlock)aBlock{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@contact/invite",kbaseURL]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"email":email}];
    [request setHTTPBody:[self encodeParameters:params]];
    [request setValue:currentUser.token forHTTPHeaderField:@"Access-Token"];
    [request setHTTPMethod:@"POST"];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *userDict = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:nil];
        NSLog(@"%@",userDict);
        
        aBlock(userDict,nil,nil);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error);
        aBlock(nil,error, nil);
    }];
    [operation start];

}

+ (void) cancelInviteWithID:(NSNumber *)inviteID fromUser: (User *)currentUser withCompletitionBlock:(returnBlock)aBlock{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@contact/cancel-invite",kbaseURL]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
   
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"invite":inviteID}];
    [request setHTTPBody:[self encodeParameters:params]];
    [request setValue:currentUser.token forHTTPHeaderField:@"Access-Token"];
    [request setHTTPMethod:@"POST"];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *userDict = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:nil];
        NSLog(@"%@",userDict);
        
        aBlock(userDict,nil,nil);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error);
        aBlock(nil,error, nil);
    }];
    [operation start];
}

#pragma mark - contacts
+ (void) getContactsForUser:(User *)currentUser withCompletitionBlock:(returnBlock) aBlock{
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@contacts",kbaseURL]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:currentUser.token forHTTPHeaderField:@"Access-Token"];
    [request setHTTPMethod:@"GET"];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation.securityPolicy setAllowInvalidCertificates:YES];
    
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
//        NSLog(@"Received %lu bytes from %@ (getContacts)", (unsigned long)[responseObject length], operation.request.URL.absoluteString);
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        NSDictionary *userDict = [[NSDictionary alloc] init];
        
        NSError* error = nil;
        NSMutableArray *contactList = [NSMutableArray array];
        
        userDict = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:&error];
//        NSLog(@"%@",userDict);
        
        for (NSDictionary * aUserDictionary in userDict[@"contacts"]) {
            User *aContact = [[User alloc] init];
            aContact.avatarURL = aUserDictionary[@"avatar_url"];
            aContact.name  = aUserDictionary[@"name"];
            aContact.userID = aUserDictionary[@"id"];
            aContact.isOnline = [NSNumber numberWithBool:[aUserDictionary[@"is_online"] boolValue]];
            [contactList addObject:aContact];
            aContact = nil;
        }
        
       
        aBlock(contactList,nil, nil);
        contactList = nil;
        userDict = nil;
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"error%@",error);
        aBlock(nil,error, nil);
    }];
    
    [operation start];
    request = nil;
    url = nil;

}


#pragma mark -call
+ (void) initiateCallWithUser:(User *)secondUser withCompletitionBlock:(returnBlock)aBlock{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@call",kbaseURL]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    NSLog(@"Request: %@/",url,secondUser.userID);
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"user":secondUser.userID}];
    [request setHTTPBody:[self encodeParameters:params]];
    User *currentUser = SharedAppDelegate.currentUser;
    [request setValue:currentUser.token forHTTPHeaderField:@"Access-Token"];
    [request setHTTPMethod:@"POST"];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *userDict = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:nil];
        NSLog(@"%@",userDict);
        
        aBlock(userDict,nil,nil);
        userDict = nil;
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error);
        aBlock(nil,error, nil);
    }];
    [operation start];
    
    request = nil;
    url = nil;
}

+ (void)receiveCallFromUserCallID:(NSString *)callID withCompletitionBlock:(returnBlock)aBlock{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@call/%@",kbaseURL,callID]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:SharedAppDelegate.currentUser.token forHTTPHeaderField:@"Access-Token"];
    [request setHTTPMethod:@"GET"];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation.securityPolicy setAllowInvalidCertificates:YES];
    
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        NSDictionary *userDict = [[NSDictionary alloc] init];
        
        NSError* error = nil;
        
        userDict = [NSJSONSerialization JSONObjectWithData:responseObject
                                                   options:NSJSONReadingAllowFragments error:&error];
        NSLog(@"%@",userDict);
        
        aBlock(userDict,nil,nil);
        userDict = nil;
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"error%@",error);
        aBlock(nil,error,nil);
    }];
    
    [operation start];
    
    request = nil;
    url = nil;
   
}

+ (void)answerCallForCallID:(NSString *)callID withCompletitionBlock:(returnBlock) aBlock {

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@call/%@",kbaseURL,callID]];
    
    NSLog(@"Request: %@",url);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:SharedAppDelegate.currentUser.token forHTTPHeaderField:@"Access-Token"];
    [request setHTTPMethod:@"POST"];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation.securityPolicy setAllowInvalidCertificates:YES];
    
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        NSDictionary *userDict = [[NSDictionary alloc] init];
        
        NSError* error = nil;
        
        userDict = [NSJSONSerialization JSONObjectWithData:responseObject
                                                   options:NSJSONReadingAllowFragments error:&error];
        NSLog(@"%@",userDict);
        
        aBlock(userDict,nil,nil);
        userDict = nil;
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"error%@",error);
        NSDictionary * userDict = [NSJSONSerialization JSONObjectWithData:operation.responseData
                                                   options:NSJSONReadingAllowFragments error:&error];
        NSLog(@"%@",userDict);
        aBlock(nil,error,nil);
    }];
    
    [operation start];
    request = nil;
    url = nil;

}

+ (void)dropCallForCallID:(NSString *)callID withCompletitionBlock:(returnBlock) aBlock{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@call/%@",kbaseURL,callID]];
    
    NSLog(@"Request: %@",url);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:SharedAppDelegate.currentUser.token forHTTPHeaderField:@"Access-Token"];
    [request setHTTPMethod:@"DELETE"];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation.securityPolicy setAllowInvalidCertificates:YES];
    
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        NSDictionary *userDict = [[NSDictionary alloc] init];
        
        NSError* error = nil;
        
        userDict = [NSJSONSerialization JSONObjectWithData:responseObject
                                                   options:NSJSONReadingAllowFragments error:&error];
        NSLog(@"%@",userDict);
        
        aBlock(userDict,nil,nil);
        userDict = nil;
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"error%@",error);
        aBlock(nil,error,nil);
    }];
    
    [operation start];
    request = nil;
    url = nil;

}

+ (void) callHeartBeatWithCompletitionBlock:(returnBlock) aBlock{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@call/heartbeat",kbaseURL]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:SharedAppDelegate.currentUser.token forHTTPHeaderField:@"Access-Token"];
    [request setHTTPMethod:@"GET"];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation.securityPolicy setAllowInvalidCertificates:YES];
    
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        NSDictionary *userDict = [[NSDictionary alloc] init];
        
        NSError* error = nil;
        
        userDict = [NSJSONSerialization JSONObjectWithData:responseObject
                                                   options:NSJSONReadingAllowFragments error:&error];
        NSLog(@"%@",userDict);
        
        aBlock(userDict,nil,nil);
        userDict = nil;
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        NSLog(@"error%@",error);
        aBlock(nil,error,nil);
    }];
    
    [operation start];
    request = nil;
    url = nil;

}

#pragma mark - History
+ (void) getCallHistoryWithCompletitionBlock:(returnBlock) aBlock;{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@call/history",kbaseURL]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:SharedAppDelegate.currentUser.token forHTTPHeaderField:@"Access-Token"];
    [request setHTTPMethod:@"GET"];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation.securityPolicy setAllowInvalidCertificates:YES];
    
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        NSDictionary *userDict = [[NSDictionary alloc] init];
        
        NSError* error = nil;
        
        userDict = [NSJSONSerialization JSONObjectWithData:responseObject
                                                   options:NSJSONReadingAllowFragments error:&error];
        NSLog(@"%@",userDict);

        NSMutableArray *missedCallsArray = [NSMutableArray array];
        
        for (NSDictionary * aMissedCallDictionary in userDict) {
            MissedCall *aMissedCall = [[MissedCall alloc] init];
            aMissedCall.avatar = aMissedCallDictionary[@"avatar_url"];
            aMissedCall.duration = aMissedCallDictionary[@"duration"];
            aMissedCall.missedCallID = aMissedCallDictionary[@"id"];
            aMissedCall.isOnline = [NSNumber numberWithBool:[aMissedCallDictionary[@"is_online"] boolValue]];
            aMissedCall.name = aMissedCallDictionary[@"name"];
            aMissedCall.time = aMissedCallDictionary[@"time"];
            aMissedCall.type = aMissedCallDictionary[@"type"];
            [missedCallsArray addObject:aMissedCall];
            aMissedCall = nil;
        }
        
        aBlock(missedCallsArray,nil,nil);
        userDict = nil;
        missedCallsArray = nil;
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //        NSLog(@"error%@",error);
        aBlock(nil,error,nil);
    }];
    
    [operation start];
    request = nil;
    url = nil;
}

#pragma mark - User Status
+ (void)setUserBusyWithCompletitionBlock:(returnBlock)aBlock{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@user/status",kbaseURL]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"status":@"2"}];
    [request setHTTPBody:[self encodeParameters:params]];
    
    [request setValue:SharedAppDelegate.currentUser.token forHTTPHeaderField:@"Access-Token"];
    [request setHTTPMethod:@"POST"];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *userDict = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:nil];
        NSLog(@"%@",userDict);
        
        aBlock(userDict,nil,nil);
        userDict = nil;
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error);
        aBlock(nil,error, nil);
    }];
    [operation start];
    
    request = nil;
    url = nil;
}

+ (void)setUserAvailableWithCompletitionBlock:(returnBlock)aBlock{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@user/status",kbaseURL]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"status":@"1"}];
    [request setHTTPBody:[self encodeParameters:params]];
    
    [request setValue:SharedAppDelegate.currentUser.token forHTTPHeaderField:@"Access-Token"];
    [request setHTTPMethod:@"POST"];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *userDict = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:nil];
        NSLog(@"%@",userDict);
        
        aBlock(userDict,nil,nil);
        userDict = nil;
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error);
        aBlock(nil,error, nil);
    }];
    [operation start];
    
    request = nil;
    url = nil;
}

#pragma mark - additional methods

+ (void) setCurrentUser:(NSDictionary *) dict{
    User *newCreatedUser = [[User alloc] init];
    newCreatedUser.name = dict[@"user"][@"name"];
    newCreatedUser.userID = dict[@"user"][@"id"];
    newCreatedUser.email = dict[@"user"][@"email"];
    newCreatedUser.token = dict[@"access_token"];
    newCreatedUser.deviceID = dict[@"user"][@"device_id"];
    newCreatedUser.avatarURL = dict[@"user"][@"avatar"];
    newCreatedUser.isOnline = [NSNumber numberWithBool:[dict[@"user"][@"is_online"] boolValue]];
    newCreatedUser.status = [NSNumber numberWithInt:[dict[@"user"][@"status"] integerValue]];
    
    SharedAppDelegate.currentUser = [[User alloc] initWithUser:newCreatedUser];
}


+ (NSData*)encodeParameters:(NSDictionary*)params
{
    NSMutableArray *parts = [[NSMutableArray alloc] init];
    for (NSString *key in params)
    {
        id encodedValue = [params objectForKey:key];
        
        if ([encodedValue isKindOfClass:[NSString class]])
        {
            encodedValue = [((NSString *)encodedValue) urlEncodeUsingEncoding:NSUTF8StringEncoding];
        }
        
        NSString *encodedKey = [key urlEncodeUsingEncoding:NSUTF8StringEncoding];
        NSString *part = [NSString stringWithFormat: @"%@=%@", encodedKey, encodedValue];
        [parts addObject:part];
    }
    NSString *encodedDictionary = [parts componentsJoinedByString:@"&"];
    
    return [encodedDictionary dataUsingEncoding:NSUTF8StringEncoding];
}

+ (void)sendPresence:(NSString *)type {
    
    NSXMLElement *presence = [NSXMLElement elementWithName:@"presence"];
    [presence addAttributeWithName:@"to" stringValue:xmppHostName];
    [presence addAttributeWithName:@"type" stringValue:type];
    
    [[[XMPPManager sharedInstance] xmppStream] sendElement:presence];
    
}

@end
