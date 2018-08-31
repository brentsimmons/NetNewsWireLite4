//
//  RSParsedTweet.m
//  RSCoreTests
//
//  Created by Brent Simmons on 8/4/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSParsedTweet.h"


@implementation RSParsedTweet

@synthesize text;
@synthesize source;
@synthesize createdAt;
@synthesize statusID;
@synthesize inReplyToStatusID;
@synthesize inReplyToUserID;
@synthesize inReplyToScreenName;
@synthesize favorited;
@synthesize user;
@synthesize placeFullName;
@synthesize userMentions;
@synthesize urls;
@synthesize hashtags;

- (void)dealloc {
	[text release];
	[source release];
	[createdAt release];
	[inReplyToScreenName release];
	[user release];
	[placeFullName release];
	[userMentions release];
	[urls release];
	[hashtags release];
	[super dealloc];
}

@end


@implementation RSParsedTwitterUser

@synthesize userID;
@synthesize name;
@synthesize screenName;
@synthesize location;
@synthesize description;
@synthesize profileImageURL;
@synthesize url;
@synthesize protected;
@synthesize followersCount;
@synthesize friendsCount;
@synthesize createdAt;
@synthesize favoritesCount;
@synthesize following;
@synthesize statusesCount;

- (void)dealloc {
	[name release];
	[screenName release];
	[location release];
	[description release];
	[profileImageURL release];
	[url release];
	[createdAt release];
	[super dealloc];
}

@end


@implementation RSParsedTwitterUserMention

@synthesize start;
@synthesize end;
@synthesize userID;
@synthesize screenName;
@synthesize name;

- (void)dealloc {
	[screenName release];
	[name release];
	[super dealloc];	
}

@end


@implementation RSParsedTwitterURL

@synthesize start;
@synthesize end;
@synthesize url;
@synthesize expandedURL;

- (void)dealloc {
	[url release];
	[expandedURL release];
	[super dealloc];	
}

@end


@implementation RSParsedTwitterHashtag

@synthesize start;
@synthesize end;
@synthesize text;

- (void)dealloc {
	[text release];
	[super dealloc];	
}

@end
