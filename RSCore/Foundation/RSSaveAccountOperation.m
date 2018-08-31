//
//  RSSaveAccountOperation.m
//  padlynx
//
//  Created by Brent Simmons on 10/16/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSSaveAccountOperation.h"
#import "RSDataAccount.h"


@interface RSSaveAccountOperation ()
@property (nonatomic, strong) RSDataAccount *account;
@end


@implementation RSSaveAccountOperation

@synthesize account;

#pragma mark Init

- (id)initWithAccount:(RSDataAccount *)anAccount {
    self = [super initWithDelegate:nil callbackSelector:nil];
    if (self == nil)
        return nil;
    account = anAccount;
    self.operationObject = anAccount;
    self.operationType = RSOperationTypeSavingFeeds;
    return self;
}


#pragma mark Dealloc



#pragma mark RSOperation

- (void)main {
    [self.account saveToDiskIfNeeded];    
    [super main];
}


@end
