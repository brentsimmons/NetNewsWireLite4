//
//  RSSAXSingleStringParser.m
//  bobcat
//
//  Created by Brent Simmons on 3/7/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "RSSAXSingleStringParser.h"


NSString *RSParseSingleStringWithTag(NSData *xmlData, NSString *tagName) {
	RSSAXSingleStringParser *parser = [RSSAXSingleStringParser xmlParser];
	parser.tagName = tagName;
	[parser parseData:xmlData error:nil];
	return parser.returnedString;	
}


@implementation RSSAXSingleStringParser

@synthesize tagName = _tagName, returnedString = _returnedString;

#pragma mark Dealloc

- (void)dealloc {
	[_returnedString release];
	[_tagName release];
	[super dealloc];
}


#pragma mark SAX Callbacks

- (void)xmlStartElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri numberOfNamespaces:(int)numberOfNamespaces namespaces:(const xmlChar **)namespaces numberOfAttributes:(int)numberOfAttributes numberDefaulted:(int)numberDefaulted attributes:(const xmlChar **)attributes {
	[self startStoringCharacters];
}


- (void)xmlEndElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri {
	NSString *localTagName = [NSString stringWithUTF8String:(const char *)localName];
	if (localTagName && [localTagName isEqualToString:self.tagName])
		self.returnedString = [self currentString];
	[self endStoringCharacters];
}


@end
