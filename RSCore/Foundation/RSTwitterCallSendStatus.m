//
//  RSTwitterCallSendStatus.m
//  RSCoreTests
//
//  Created by Brent Simmons on 8/2/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSTwitterCallSendStatus.h"
#import "RSTwitterUtilities.h"


@implementation RSTwitterCallSendStatus


#pragma mark Dealloc

- (id)initWithStatus:(NSString *)aStatus oauthInfo:(RSOAuthInfo *)oaInfo delegate:(id)aDelegate callbackSelector:(SEL)aCallbackSelector {
	self = [super initWithURL:[NSURL URLWithString:@"https://api.twitter.com/statuses/update.xml"] oauthInfo:oaInfo delegate:aDelegate callbackSelector:aCallbackSelector];
	if (self == nil)
		return nil;
	status = [aStatus copy];
	self.operationType = RSOperationTypePostToTwitter;
	self.operationObject = aStatus;
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[status release];
	[super dealloc];
}


- (void)createRequest {
	self.httpMethod = RSHTTPMethodPost;
	NSString *statusTrimmed = [status precomposedStringWithCanonicalMapping];
    if ([statusTrimmed length] > RSTwitterMaxCharacters)
        statusTrimmed = [statusTrimmed substringToIndex:RSTwitterMaxCharacters];
	self.postBodyDictionary = [NSDictionary dictionaryWithObject:statusTrimmed forKey:@"status"];
	[super createRequest];
}


#pragma mark Response

- (void)buildParsedResponse {
	self.parsedResponse = [NSNumber numberWithBool:self.okResponse];
//	NSString *response = [[[NSString alloc] initWithData:self.responseBody encoding:NSUTF8StringEncoding] autorelease];
	//NSLog(@"response: %@", response);
}


@end


/*<?xml version="1.0" encoding="UTF-8"?>
 <status>
 <created_at>Tue Aug 03 05:52:22 +0000 2010</created_at>
 <id>20200069026</id>
 <text>Testingignore</text>
 <source>&lt;a href=&quot;http://taplynx.com/&quot; rel=&quot;nofollow&quot;&gt;TapLynx&lt;/a&gt;</source>
 <truncated>false</truncated>
 <in_reply_to_status_id></in_reply_to_status_id>
 <in_reply_to_user_id></in_reply_to_user_id>
 <favorited>false</favorited>
 <in_reply_to_screen_name></in_reply_to_screen_name>
 <user>
 <id>5773272</id>
 <name>NetNewsWire Demo</name>
 <screen_name>nnwdemo</screen_name>
 <location></location>
 <description></description>
 <profile_image_url>http://a2.twimg.com/profile_images/30826362/nnwchaticon_normal.png</profile_image_url>
 <url></url>
 <protected>false</protected>
 <followers_count>38</followers_count>
 <profile_background_color>9ae4e8</profile_background_color>
 <profile_text_color>000000</profile_text_color>
 <profile_link_color>0000ff</profile_link_color>
 <profile_sidebar_fill_color>e0ff92</profile_sidebar_fill_color>
 <profile_sidebar_border_color>87bc44</profile_sidebar_border_color>
 <friends_count>1</friends_count>
 <created_at>Fri May 04 18:48:49 +0000 2007</created_at>
 <favourites_count>0</favourites_count>
 <utc_offset>-25200</utc_offset>
 <time_zone>Arizona</time_zone>
 <profile_background_image_url>http://s.twimg.com/a/1280528898/images/themes/theme1/bg.png</profile_background_image_url>
 <profile_background_tile>false</profile_background_tile>
 <profile_use_background_image>true</profile_use_background_image>
 <notifications>false</notifications>
 <geo_enabled>false</geo_enabled>
 <verified>false</verified>
 <following>false</following>
 <statuses_count>4</statuses_count>
 <lang>en</lang>
 <contributors_enabled>false</contributors_enabled>
 <follow_request_sent>false</follow_request_sent>
 <listed_count>0</listed_count>
 <show_all_inline_media>false</show_all_inline_media>
 </user>
 <geo/>
 <coordinates/>
 <place/>
 <contributors/>
 </status>
*/
