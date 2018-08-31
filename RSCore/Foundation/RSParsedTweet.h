//
//  RSParsedTweet.h
//  RSCoreTests
//
//  Created by Brent Simmons on 8/4/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@class RSParsedTwitterUser;

@interface RSParsedTweet : NSObject {
@private
	NSString *text;
	NSString *source;
	NSDate *createdAt;
	UInt64 statusID;
	UInt64 inReplyToStatusID;
	UInt64 inReplyToUserID;
	NSString *inReplyToScreenName;
	BOOL favorited;
	RSParsedTwitterUser *user;
	NSString *placeFullName;
	NSArray *userMentions;
	NSArray *urls;
	NSArray *hashtags;
}

@property (nonatomic, retain) NSString *text;
@property (nonatomic, retain) NSString *source;
@property (nonatomic, retain) NSDate *createdAt;
@property (nonatomic, assign) UInt64 statusID;
@property (nonatomic, assign) UInt64 inReplyToStatusID;
@property (nonatomic, assign) UInt64 inReplyToUserID;
@property (nonatomic, retain) NSString *inReplyToScreenName;
@property (nonatomic, assign) BOOL favorited;
@property (nonatomic, retain) RSParsedTwitterUser *user;
@property (nonatomic, retain) NSString *placeFullName;
@property (nonatomic, retain) NSArray *userMentions;
@property (nonatomic, retain) NSArray *urls;
@property (nonatomic, retain) NSArray *hashtags;


@end


@interface RSParsedTwitterUser : NSObject {
@private
	UInt64 userID;
	NSString *name;
	NSString *screenName;
	NSString *location;
	NSString *description;
	NSString *profileImageURL;
	NSString *url;
	BOOL protected;
	NSUInteger followersCount;
	NSUInteger friendsCount;
	NSDate *createdAt;
	NSUInteger favoritesCount;
	BOOL following;
	NSUInteger statusesCount;
}

@property (nonatomic, assign) UInt64 userID;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *screenName;
@property (nonatomic, retain) NSString *location;
@property (nonatomic, retain) NSString *description;
@property (nonatomic, retain) NSString *profileImageURL;
@property (nonatomic, retain) NSString *url;
@property (nonatomic, assign) BOOL protected;
@property (nonatomic, assign) NSUInteger followersCount;
@property (nonatomic, assign) NSUInteger friendsCount;
@property (nonatomic, retain) NSDate *createdAt;
@property (nonatomic, assign) NSUInteger favoritesCount;
@property (nonatomic, assign) BOOL following;
@property (nonatomic, assign) NSUInteger statusesCount;

@end


@interface RSParsedTwitterUserMention : NSObject {
@private
	NSUInteger start;
	NSUInteger end;
	UInt64 userID;
	NSString *screenName;
	NSString *name;
}

@property (nonatomic, assign) NSUInteger start;
@property (nonatomic, assign) NSUInteger end;
@property (nonatomic, assign) UInt64 userID;
@property (nonatomic, retain) NSString *screenName;
@property (nonatomic, retain) NSString *name;

@end


@interface RSParsedTwitterURL : NSObject {
@private
	NSUInteger start;
	NSUInteger end;
	NSString *url;
	NSString *expandedURL;
}

@property (nonatomic, assign) NSUInteger start;
@property (nonatomic, assign) NSUInteger end;
@property (nonatomic, retain) NSString *url;
@property (nonatomic, retain) NSString *expandedURL;

@end


@interface RSParsedTwitterHashtag : NSObject {
@private
	NSUInteger start;
	NSUInteger end;
	NSString *text;
}

@property (nonatomic, assign) NSUInteger start;
@property (nonatomic, assign) NSUInteger end;
@property (nonatomic, retain) NSString *text;

@end
