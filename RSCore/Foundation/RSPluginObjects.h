//
//  RSPluginObjects.h
//  RSCoreTests
//
//  Created by Brent Simmons on 10/2/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSPluginProtocols.h"


@class RSDataArticle;

@interface RSSharableItem : NSObject <RSSharableItem> {
@private
	NSString *uti;
	NSURL *URL;
	NSData *itemData;
	NSString *htmlText;
	NSString *selectedText;
	NSString *title;
	id<RSFeedSpecifier> feed;
	NSURL *permalink;	
}


+ (id<RSSharableItem>)sharableItemWithURL:(NSURL *)aURL;
+ (id<RSSharableItem>)sharableItemWithURL:(NSURL *)aURL permalink:(NSURL *)aPermalink title:(NSString *)aTitle; //assumes text type
+ (id<RSSharableItem>)sharableItemWithArticle:(RSDataArticle *)anArticle;
+ (id<RSSharableItem>)sharableItemWithTimeBasedMedia:(NSURL *)aURL;

+ (NSArray *)arrayOfOneSharableItemWithArticle:(RSDataArticle *)anArticle; //Convenience. The plugin APIs want arrays.

@end
