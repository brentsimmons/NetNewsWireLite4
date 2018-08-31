//
//  RSTweetParser.m
//  RSCoreTests
//
//  Created by Brent Simmons on 8/4/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSTweetParser.h"


@implementation RSTweetParser


//- (void)xmlStartElement:(const xmlChar *)localName {
//	if (xmlEqualTags(localName, kStatusTag, kStatusTagLength)) {
//		self.parsingTweet = YES;
//		[self addTweet];
//	}
//	else if (xmlEqualTags(localName, kUserMentionTag, kUserMentionTagLength) && self.parsingUserMentions) {
//		self.parsingUserMention = YES;
//		[self addUserMention];
//	}
//	else if (self.parsingURLs && !self.parsingURL && xmlEqualTags(localName, kURLTag, kURLTagLength)) {
//		self.parsingURL = YES;
//		[self addURL];
//	}
//	else if (xmlEqualTags(localName, kHashtagsTag, kHashtagsTagLength))
//		self.parsingHashtags = YES;
//	else if (xmlEqualTags(localName, kHashtagTag, kHashtagTagLength)) {
//		self.parsingHashtag = YES;
//		[self addHashtag];
//	}
//	else if (xmlEqualTags(localName, kUserTag, kUserTagLength))
//		self.parsingUser = YES;
//	else if (xmlEqualTags(localName, kPlaceTag, kPlaceTagLength))
//		self.parsingPlace = YES;
//	else if (xmlEqualTags(localName, kEntitiesTag, kEntitiesTagLength))
//		self.parsingEntities = YES;
//	
//	else if ([self shouldStoreCharactersForTag:localName])
//		[self startStoringCharacters];
//}

@end
