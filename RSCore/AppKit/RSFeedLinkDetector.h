//
//  RSFeedLinkDetector.h
//  NetNewsWire
//
//  Created by Brent Simmons on 2/7/07.
//  Copyright 2007 Ranchero Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>


NSArray *RSCachedFeedLinks(NSString *pageURLString, BOOL *found);



@interface RSFeedLinkDetector : NSObject {

	}


+ (NSArray *)feedLinksInDOMDocument:(DOMDocument *)domDocument pageURL:(NSURL *)pageURL;


@end
