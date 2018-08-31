//
//  RSFeedTypeDetector.h
//  RSCoreTests
//
//  Created by Brent Simmons on 6/23/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


/*When you have all -- or just the beginning -- of a feed, this can tell what kind of feed it is.
 It may decide that it's not a feed at all (a web page, for instance).
 Just call RSFeedTypeForData(feedData).
 
 It does *not* distinguish Google Reader from Atom. Partly because apps other than NetNewsWire
 don't need that dependency, and partly because any app should know when the feeds
 are coming from Google Reader, and the app shouldn't have to use the feed detector in those cases.*/


typedef enum _RSFeedType {
	RSFeedTypeRSS, //includes RSS 1.0 (RDF)
	RSFeedTypeAtom,
	RSFeedTypeNotAFeed //probably a web page
} RSFeedType;


RSFeedType RSFeedTypeForData(NSData *feedData);
BOOL RSDataIsFeed(NSData *feedData); //For when you just need to know if it's any kind of feed

BOOL RSDataIsProbablyMedia(NSData *data);

