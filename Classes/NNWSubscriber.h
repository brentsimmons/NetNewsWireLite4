//
//  NNWSubscriber.h
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 7/22/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NNWFeedFinder.h"
#import "RSFolder.h"
#import "RSRefreshProtocols.h"


/*Given a feedURL, account, and optional parentFolder and title,
 NNWSubscriber finds the feed and adds it to the right place.
 
 This works only for the default local account. We'll have to
 do a plugin interface to handle other accounts.
 
 When finished, it sends a notification, either NNWSubscribeDidSucceedNotification
 or NNWSubscribeDidFailNotification. The object points back here for more info.
 
 NNWSubscriber doesn't display errors, though it will create an
 NSError object if subscribing fails. Displaying these
 is up to whatever object catches the notification.*/


extern NSString *NNWSubscribeDidSucceedNotification;
extern NSString *NNWSubscribeDidFailNotification;


@class NNWSubscriber;
@class RSFeed;

enum _NNWSubscriberFailureReason { //error codes
    NNWSubscriberFailureNone, //success, in other words
    NNWSubscriberFailureUserCanceled,
    NNWSubscriberFailureAlreadySubscribed,
    NNWSubscriberFailureCouldNotFindFeed
};

@class NNWSubscribeRequest;


#pragma mark -


@interface NNWSubscriber : NSObject <NNWFeedFinderDelegate> {
@private
    NNWSubscribeRequest *subscribeRequest;
    NSError *error;
    NSString *foundTitle;
    NSString *password;
    NSString *username;
    NSURL *foundFeedURL;
    RSFeed *feedAdded;
}

- (id)initWithSubscribeRequest:(NNWSubscribeRequest *)aSubscribeRequest;
- (void)subscribe;
    
@property (nonatomic, strong, readonly) NSError *error; //error code is _NNWSubscriberFailureReason
@property (nonatomic, strong, readonly) NSURL *foundFeedURL;
@property (nonatomic, strong, readonly) NSString *foundTitle; //only present if title is nil in subscribeRequest
@property (nonatomic, strong, readonly) NNWSubscribeRequest *subscribeRequest; //original request, unchanged
@property (nonatomic, strong, readonly) NSString *username;
@property (nonatomic, strong, readonly) NSString *password;
@property (nonatomic, strong, readonly) RSFeed *feedAdded;


@end

