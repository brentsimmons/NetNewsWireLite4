//
//  RSSAXAbstractParser.h
//  nnw
//
//  Created by Brent Simmons on 2/22/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libxml/tree.h>


#define _xmlEqualTags(localName, tag, tagLength) !strncmp((const char *)localName, tag, tagLength)


@interface RSSAXParser : NSObject {
@protected
	xmlParserCtxtPtr _context;
	NSMutableData *_characterBuffer;
	NSMutableDictionary *_xmlAttributesDict;
	BOOL _storingCharacters;
	NSMutableArray *_xmlAttributesStack;
	NSURL *_dataURL; /*where the data came from, such as a feed*/
}


@property (nonatomic, retain, readonly) NSMutableData *characterBuffer;
@property (nonatomic, retain) NSMutableDictionary *xmlAttributesDict;
@property (nonatomic, retain) NSURL *dataURL;

+ (id)xmlParser;

- (BOOL)parseData:(NSData *)feedData error:(NSError **)error; /*To parse an entire document. Otherwise use calls below.*/

- (void)startParsing:(NSData *)initialChunk;
- (BOOL)parseChunk:(NSData *)data error:(NSError **)error;
- (void)endParsing;
- (void)stopParsing; /*Stops it early*/

- (void)appendCharacters:(const char *)charactersFound length:(NSUInteger)length;
- (void)appendUTF8String:(const char *)utf8String; //nil-terminated

/*For subclasses -- *very* thin wrappers for C interface*/

- (void)xmlStartElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri numberOfNamespaces:(int)numberOfNamespaces namespaces:(const xmlChar **)namespaces numberOfAttributes:(int)numberOfAttributes numberDefaulted:(int)numberDefaulted attributes:(const xmlChar **)attributes; /*Call super only if you need attributes xmlAttributesDict set up*/
- (void)xmlEndElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri; /*No need to call super*/
- (void)xmlCharactersFound:(const xmlChar *)ch length:(int)length;

- (NSDate *)currentDate;
- (NSString *)currentString;
- (const void *)currentBytes;

- (void)startStoringCharacters;
- (void)endStoringCharacters;


/*Utilities*/

- (NSString *)keyWithLocalName:(const char *)localName prefix:(const char *)prefix;
- (void)addItemToDictionary:(const char *)localName prefix:(const char *)prefix dictionary:(NSMutableDictionary *)dict;


@end
