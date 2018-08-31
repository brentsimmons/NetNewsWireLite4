//
//  RSSAXAbstractParser.h
//  nnw
//
//  Created by Brent Simmons on 2/22/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libxml/tree.h>
#import <libxml/parserInternals.h>


#define _xmlEqualTags(localName, tag, tagLength) !strncmp((const char *)localName, tag, tagLength)


@interface RSSAXParser : NSObject {
@protected
	xmlParserCtxtPtr _context;
	NSMutableData *_characterBuffer;
	NSMutableDictionary *_xmlAttributesDict;
	BOOL _storingCharacters;
	NSMutableArray *_xmlAttributesStack;
}


+ (id)xmlParser;

- (void)parseData:(NSData *)feedData error:(NSError **)error; /*To parse an entire document. Otherwise use calls below.*/

- (void)startParsing:(NSData *)initialChunk;
- (void)parseChunk:(NSData *)data error:(NSError **)error;
- (void)endParsing;
- (void)stopParsing; /*Stops it early*/

/*For subclasses -- *very* thin wrappers for C interface*/

- (void)xmlStartElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri numberOfNamespaces:(int)numberOfNamespaces namespaces:(const xmlChar **)namespaces numberOfAttributes:(int)numberOfAttributes numberDefaulted:(int)numberDefaulted attributes:(const xmlChar **)attributes; /*Call super only if you need attributes xmlAttributesDict set up*/
- (void)xmlEndElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri; /*No need to call super*/
- (void)xmlCharactersFound:(const xmlChar *)ch length:(int)length;

- (NSString *)currentString;
- (void)startStoringCharacters;
- (void)endStoringCharacters;

@property (nonatomic, retain) NSMutableDictionary *xmlAttributesDict;

/*Utilities*/

- (NSString *)keyWithLocalName:(const char *)localName prefix:(const char *)prefix;
- (void)addItemToDictionary:(const char *)localName prefix:(const char *)prefix dictionary:(NSMutableDictionary *)dict;


@end
