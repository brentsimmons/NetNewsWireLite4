//
//  RSFeedTypeDetectorParser.m
//  RSCoreTests
//
//  Created by Brent Simmons on 6/28/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSFeedTypeDetectorParser.h"


/*It just compares start-tags to see if it's the start of a feed --
 or the common wrong case of an html page.
 There's a limit of kMaxStartTagsToCheck -- no need to parse
 through an entire XML document if the start tag isn't right near the top.*/
 

static const NSUInteger kMaxStartTagsToCheck = 6; //should be plenty
 
@interface RSFeedTypeDetectorParser ()
@property (nonatomic, assign, readwrite) RSFeedType feedType;
@property (nonatomic, assign, readwrite) NSUInteger countStartElements;
@end


@implementation RSFeedTypeDetectorParser

@synthesize feedType;
@synthesize countStartElements;


- (id)init {
	self = [super init];
	if (self == nil)
		return nil;
	feedType = RSFeedTypeNotAFeed;
	return self;
}


- (void)stopParsingWithDetectedFeedType:(RSFeedType)detectedFeedType {
	self.feedType = detectedFeedType;
	[self stopParsing];
}


static const char *kRSSStartTag = "rss";
static const NSUInteger kRSSStartTagLength = 4;
static const char *kRDFStartTag = "RDF";
static const NSUInteger kRDFStartTagLength = 4;
static const char *kFeedStartTag = "feed";
static const NSUInteger kFeedStartTagLength = 5;
static const char *kHTMLStartTag = "html"; //common not-a-feed case
static const NSUInteger kHTMLStartTagLength = 5;

- (void)xmlStartElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri numberOfNamespaces:(int)numberOfNamespaces namespaces:(const xmlChar **)namespaces numberOfAttributes:(int)numberOfAttributes numberDefaulted:(int)numberDefaulted attributes:(const xmlChar **)attributes {
	
	if (_xmlEqualTags(localName, kRSSStartTag, kRSSStartTagLength) || _xmlEqualTags(localName, kRDFStartTag, kRDFStartTagLength)) {
		[self stopParsingWithDetectedFeedType:RSFeedTypeRSS];
		return;
	}
	else if (_xmlEqualTags(localName, kFeedStartTag, kFeedStartTagLength)) {
		[self stopParsingWithDetectedFeedType:RSFeedTypeAtom];
		return;
	}
	else if (_xmlEqualTags(localName, kHTMLStartTag, kHTMLStartTagLength)) {
		[self stopParsingWithDetectedFeedType:RSFeedTypeNotAFeed];
		return;
	}
	
	self.countStartElements = self.countStartElements + 1;
	if (self.countStartElements > kMaxStartTagsToCheck)
		[self stopParsing];
}


- (void)xmlEndElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri {
}


- (void)xmlCharactersFound:(const xmlChar *)ch length:(int)length {
}


- (void)xmlEndDocument {
	;
}


@end
