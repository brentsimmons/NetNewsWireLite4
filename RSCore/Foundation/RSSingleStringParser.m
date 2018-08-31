//
//  RSSingleStringParser.m
//  RSCoreTests
//
//  Created by Brent Simmons on 8/3/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSSingleStringParser.h"


NSString *RSParseSingleStringWithTag(NSData *xmlData, NSString *tagName) {
    RSSingleStringParser *parser = [RSSingleStringParser xmlParser];
    parser.tagName = tagName;
    [parser parseData:xmlData error:nil];
    return parser.returnedString;    
}


@interface RSSingleStringParser ()
@property (nonatomic, strong, readwrite) NSString *returnedString;
@end


@implementation RSSingleStringParser

@synthesize tagName;
@synthesize returnedString;

#pragma mark Dealloc



#pragma mark SAX Callbacks

- (void)xmlStartElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri numberOfNamespaces:(int)numberOfNamespaces namespaces:(const xmlChar **)namespaces numberOfAttributes:(int)numberOfAttributes numberDefaulted:(int)numberDefaulted attributes:(const xmlChar **)attributes {
    [self startStoringCharacters];
}


- (void)xmlEndElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri {
    if (self.returnedString != nil)
        return; //shouldn't happen
    NSString *localTagName = [NSString stringWithUTF8String:(const char *)localName];
    if (localTagName && [localTagName isEqualToString:self.tagName]) {
        self.returnedString = [self currentString];
        [self stopParsing];
        return;
    }
    [self endStoringCharacters];
}


@end
