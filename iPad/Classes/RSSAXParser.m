//
//  RSSAXAbstractParser.m
//  nnw
//
//  Created by Brent Simmons on 2/22/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "RSSAXParser.h"


static xmlSAXHandler saxHandlerStruct;


@interface RSSAXParser ()
@property (nonatomic, retain) NSMutableArray *xmlAttributesStack;
@end

@implementation RSSAXParser

@synthesize xmlAttributesDict = _xmlAttributesDict, xmlAttributesStack = _xmlAttributesStack;


#pragma mark Class Methods

+ (id)xmlParser {
	return [[[self alloc] init] autorelease];	
}


#pragma mark Init

- (id)init {
	if (![super init])
		return nil;
	_characterBuffer = [[NSMutableData data] retain];
	_xmlAttributesStack = [[NSMutableArray arrayWithCapacity:10] retain];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	if (_context)
		xmlFreeParserCtxt(_context);
	[_xmlAttributesDict release];
	[_xmlAttributesStack release];
	[_characterBuffer release];
	[super dealloc];
}


#pragma mark Parser public interface

- (void)parseData:(NSData *)data error:(NSError **)error {
	[self startParsing:data];
	[self endParsing];
}


- (void)parseChunk:(NSData *)data error:(NSError **)error {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	xmlParseChunk(_context, (const char *)[data bytes], [data length], 0);
	[pool drain];
}


- (void)startParsing:(NSData *)initialChunk {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	//_context = xmlCreatePushParserCtxt(&saxHandlerStruct, self, (const char *)[initialChunk bytes], [initialChunk length], nil);
	_context = xmlCreatePushParserCtxt(&saxHandlerStruct, self, nil, 0, nil);
	xmlCtxtUseOptions(_context, XML_PARSE_NOENT);
	NSError *error = nil;
	[self parseChunk:initialChunk error:&error];
	[pool release];
}


- (void)endParsing {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    xmlParseChunk(_context, nil, 0, 1);
	xmlFreeParserCtxt(_context);
	_context = nil;
	self.xmlAttributesDict = nil;
	[pool release];
}


- (void)stopParsing {
    xmlStopParser(_context);
	self.xmlAttributesDict = nil;
}


#pragma mark Parsing

- (NSString *)keyWithLocalName:(const char *)localName prefix:(const char *)prefix {
	if (prefix == nil)
		return [NSString stringWithUTF8String:localName];
	NSMutableString *key = [NSMutableString stringWithUTF8String:prefix];
	const unichar colonCharacter = ':';
	CFStringAppendCharacters((CFMutableStringRef)key, &colonCharacter, 1);
	CFStringAppendCString((CFMutableStringRef)key, localName, kCFStringEncodingUTF8);
	return key;
}


- (void)addItemToDictionary:(const char *)localName prefix:(const char *)prefix dictionary:(NSMutableDictionary *)dict {
	if ([_characterBuffer length] < 1)
		return;
	[dict safeSetObject:[self currentString] forKey:[self keyWithLocalName:localName prefix:prefix]];
	[self endStoringCharacters];	
}


- (void)appendCharacters:(const char *)charactersFound length:(NSInteger)length {
//	xmlChar *decodedCharacters = xmlStringLenDecodeEntities(_context, (const xmlChar*)charactersFound, length, XML_SUBSTITUTE_REF, 0, 0, 0);
//	[_characterBuffer appendBytes:decodedCharacters length:xmlStrlen(decodedCharacters)];
	[_characterBuffer appendBytes:charactersFound length:length];
}


- (NSString *)currentString {
	if ([_characterBuffer length] < 1)
		return nil;
	return [[[NSString alloc] initWithData:_characterBuffer encoding:NSUTF8StringEncoding] autorelease];
//	NSMutableString *s = [[[NSMutableString alloc] initWithData:_characterBuffer encoding:NSUTF8StringEncoding] autorelease];
//	[s replaceXMLCharacterReferences];
////	[s replaceEntityAmpWithAmpersand];
////	[s replaceEntityQuotWithDoubleQuote];
////	[s replaceEntity39WithSingleQuote];
//	CFStringTrimWhitespace((CFMutableStringRef)s);
//	return s;
}


- (void)startStoringCharacters {
	_storingCharacters = YES;
	[_characterBuffer setLength:0];
}


- (void)endStoringCharacters {
	_storingCharacters = NO;
	[_characterBuffer setLength:0];
}


#pragma mark Callbacks

- (void)xmlStartElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri numberOfNamespaces:(int)numberOfNamespaces namespaces:(const xmlChar **)namespaces numberOfAttributes:(int)numberOfAttributes numberDefaulted:(int)numberDefaulted attributes:(const xmlChar **)attributes {
	
	self.xmlAttributesDict = nil;
	if (numberOfAttributes > 0 && attributes) {
		NSMutableDictionary *attributesDict = [[NSMutableDictionary alloc] initWithCapacity:numberOfAttributes];
//		BOOL anyValueContainsEntity = NO;
		int i = 0, j = 0;
		for (i = 0, j = 0; i < numberOfAttributes; i++, j+=5) {
			NSUInteger lenValue = (NSUInteger)(attributes[j + 4] - attributes[j + 3]);
			NSMutableString *value = [[NSMutableString alloc] initWithBytes:(const void *)attributes[j + 3] length:lenValue encoding:NSUTF8StringEncoding];
			if (value) {
//				CFStringTrimWhitespace((CFMutableStringRef)value);
				[value replaceEntity38WithAmpersand];
				//[value replaceXMLCharacterReferences];
			}
			NSString *attName = [[[NSString alloc] initWithUTF8String:(const char *)attributes[j]] autorelease];
			if (attributes[j + 1]) {
				NSString *attPrefix = [NSString stringWithUTF8String:(const char *)attributes[j + 1]];
				attName = [NSString stringWithFormat:@"%@:%@", attPrefix, attName];
			}
			[attributesDict setObject:value forKey:attName];
			[value release];
		}
		self.xmlAttributesDict = attributesDict;
		[attributesDict release];
	}
	if (RSIsEmpty(self.xmlAttributesDict))
		[_xmlAttributesStack addObject:[NSNull null]];
	else
		[_xmlAttributesStack addObject:self.xmlAttributesDict];
//	[_xmlAttributesStack addObject:((void *)self.xmlAttributesDict != nil) ? self.xmlAttributesDict : [NSNull null]];
}


- (void)xmlEndElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri {
	self.xmlAttributesDict = [_xmlAttributesStack lastObject];
	if ((id)self.xmlAttributesDict == (id)[NSNull null])
		self.xmlAttributesDict = nil;
	[_xmlAttributesStack removeLastObject];
}


- (void)xmlCharactersFound:(const xmlChar *)ch length:(int)length {
	if (_storingCharacters)
		[self appendCharacters:(const char *)ch length:length];
}


- (void)xmlEndDocument {
	; /*For subclasses -- for instance, that need to call a delegate when parsing is finished.*/
}


@end


#pragma mark C -- SAX Callbacks from libxml2

static void startElementSAX(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI, int nb_namespaces, const xmlChar **namespaces, int nb_attributes, int nb_defaulted, const xmlChar **attributes) {
	[(RSSAXParser *)ctx xmlStartElement:localname prefix:prefix uri:URI numberOfNamespaces:nb_namespaces namespaces:namespaces numberOfAttributes:nb_attributes numberDefaulted:nb_defaulted attributes:attributes];
}


static void	endElementSAX(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI) {    
	[(RSSAXParser *)ctx xmlEndElement:localname prefix:prefix uri:URI];
}


static void	charactersFoundSAX(void *ctx, const xmlChar *ch, int len) {
	[(RSSAXParser *)ctx xmlCharactersFound:ch length:len];
}


//static xmlEntityPtr getEntitySAX(void *user_data, const xmlChar *name) {
//	return xmlGetPredefinedEntity(name);	
//}


static void errorEncounteredSAX(void *ctx, const char *msg, ...) {
	va_list args;	
    va_start(args, msg);
    fprintf(stdout, "SAX.error: ");
    vfprintf(stdout, msg, args);
	va_end(args);
}


static void endDocumentSAX(void *ctx) {
	[(RSSAXParser *)ctx xmlEndDocument];
}


static xmlSAXHandler saxHandlerStruct = {
nil,                       /* internalSubset */
nil,                       /* isStandalone   */
nil,                       /* hasInternalSubset */
nil,                       /* hasExternalSubset */
nil,                       /* resolveEntity */
nil,					   /* getEntity */
nil,                       /* entityDecl */
nil,                       /* notationDecl */
nil,                       /* attributeDecl */
nil,                       /* elementDecl */
nil,                       /* unparsedEntityDecl */
nil,                       /* setDocumentLocator */
nil,                       /* startDocument */
endDocumentSAX,            /* endDocument */
nil,                       /* startElement*/
nil,                       /* endElement */
nil,                       /* reference */
charactersFoundSAX,        /* characters */
nil,                       /* ignorableWhitespace */
nil,                       /* processingInstruction */
nil,                       /* comment */
nil,                       /* warning */
errorEncounteredSAX,       /* error */
nil,                       /* fatalError //: unused error() get all the errors */
nil,                       /* getParameterEntity */
nil,                       /* cdataBlock */
nil,                       /* externalSubset */
XML_SAX2_MAGIC,            //
nil,
startElementSAX,           /* startElementNs */
endElementSAX,             /* endElementNs */
nil,                       /* serror */
};

