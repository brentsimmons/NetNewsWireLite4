//
//  RSFeedTypeDetector.m
//  RSCoreTests
//
//  Created by Brent Simmons on 6/23/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSFeedTypeDetector.h"
#import "RSFoundationExtras.h"
#import "RSFeedTypeDetectorParser.h"


/*One big challenge with feed detection is memory allocation.
 You do *not* want to allocate an NSString based on the NSData and search through that NSString.
 It's especially a killer on mobile, where doing so might very easily result in a memory warning.
 
 So, since the feed is probably UTF-8 or other ASCII-ish (mostly single-byte) character set,
 then strnstr will work most of the time. That's just a search -- I bet it results in
 no heap memory allocations whatsoever.
 
 But if it doesn't work, we fall back to a SAX parser. SAX because it doesn't copy the feedData, because
 it's fast, and because we can abort parsing once we have our answer.*/


static const char *rs_rssStart = "<rss";
static const char *rs_rdfStart = "<rdf:";
static const char *rs_atomStart = "<feed";
static const char *rs_htmlStart = "<html";

RSFeedType RSFeedTypeForData(NSData *feedData) {
    
    if (RSIsEmpty(feedData))
        return RSFeedTypeNotAFeed;

    /*Avoid dealing with big media: we can easily check for the likeliness of it being
     a png, jpg, gif, or movie. Yes, these things happen -- and because they tend to be large
     (especially movies), it's a good idea to check in advance.*/
    
    if (RSDataIsProbablyMedia(feedData))
        return RSFeedTypeNotAFeed;
    
    /*Since feedData is probably UTF-8 or similar, strnstr will usually work.*/
    
    NSUInteger feedDataLength = [feedData length];
    static const size_t maxCharactersToSearch = 1024;
    char *rssStart = strnstr([feedData bytes], rs_rssStart, maxCharactersToSearch);
    if (rssStart != nil)
        return RSFeedTypeRSS;
    char *rdfStart = strnstr([feedData bytes], rs_rdfStart, maxCharactersToSearch);
    if (rdfStart != nil) //It's an RSS 1.0 (rdf) feed
        return RSFeedTypeRSS;
    char *atomStart = strnstr([feedData bytes], rs_atomStart, maxCharactersToSearch);
    if (atomStart != nil)
        return RSFeedTypeAtom;
    char *htmlStart = strnstr([feedData bytes], rs_htmlStart, maxCharactersToSearch);
    if (htmlStart != nil)
        return RSFeedTypeNotAFeed;
    if (feedDataLength > 5 * 1024 * 1024) //> 5 MB, probably bogus (limit arbitrarily picked)
        return RSFeedTypeNotAFeed;
    
    /*It's probably not a feed. But it might be -- it could just be UTF-16 or something where strnstr wouldn't work.*/
    
    RSFeedTypeDetectorParser *feedDetectorParser = [[RSFeedTypeDetectorParser alloc] init];
    NSError *error = nil;
    [feedDetectorParser parseData:feedData error:&error];
    RSFeedType feedType = feedDetectorParser.feedType;
    return feedType;
}



BOOL RSDataIsFeed(NSData *feedData) {
    return RSFeedTypeForData(feedData) != RSFeedTypeNotAFeed;
}


BOOL RSDataIsProbablyMedia(NSData *data) {
    
    if ([data length] < 12)
        return NO; //probably not; no harm, anyway
    
    const char *bytes = (const char *)[data bytes];
    
    if (bytes[1] == 'P' && bytes[2] == 'N' && bytes[3] == 'G')
        return YES;
    if (bytes[0] == 'G' && bytes[1] == 'I' && bytes[2] == 'F')
        return YES;
    if (bytes[0] == 0 && bytes[1] == 0 && bytes[2] == 0 && bytes[4] == 'f' && bytes[5] == 't' && bytes[6] == 'y') //movie
        return YES;
    if (bytes[6] == 'J' && bytes[7] == 'F' && bytes[8] == 'I' && bytes[9] == 'F') //JPEG
        return YES;
    if (bytes[6] == 'E' && bytes[7] == 'x' && bytes[8] == 'i' && bytes[9] == 'f') //JPEG
        return YES;
    return NO;
}
