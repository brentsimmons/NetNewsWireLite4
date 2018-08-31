//
//  RSSAXAbstractParser.m
//  nnw
//
//  Created by Brent Simmons on 2/22/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "RSSAXParser.h"
#import "RSDateParser.h"
#import "RSFoundationExtras.h"


static xmlSAXHandler saxHandlerStruct;


@interface RSSAXParser ()
@property (nonatomic, strong) NSMutableArray *xmlAttributesStack;
@end

@implementation RSSAXParser

@synthesize xmlAttributesDict = _xmlAttributesDict, xmlAttributesStack = _xmlAttributesStack;
@synthesize characterBuffer = _characterBuffer;
@synthesize dataURL = _dataURL;

#pragma mark Class Methods

+ (id)xmlParser {
    return [[self alloc] init];    
}


#pragma mark Init

- (id)init {
    if (![super init])
        return nil;
    _characterBuffer = [NSMutableData dataWithCapacity:2000];
    _xmlAttributesStack = [NSMutableArray arrayWithCapacity:10];
    return self;
}


#pragma mark Dealloc

- (void)dealloc {
    if (_context)
        xmlFreeParserCtxt(_context);
}


#pragma mark Parser public interface

- (BOOL)parseData:(NSData *)data error:(NSError **)error {
    [self startParsing:data];
    [self endParsing];
    return YES;
}


- (BOOL)parseChunk:(NSData *)data error:(NSError **)error {
    @autoreleasepool {
        xmlParseChunk(_context, (const char *)[data bytes], (int)[data length], 0);
    }
    return YES;
}


- (void)startParsing:(NSData *)initialChunk {
    @autoreleasepool {
        _context = xmlCreatePushParserCtxt(&saxHandlerStruct, (__bridge void *)(self), nil, 0, nil);
        xmlCtxtUseOptions(_context, XML_PARSE_RECOVER | XML_PARSE_NOENT);
        NSError *error = nil;
        [self parseChunk:initialChunk error:&error];
    }
}


- (void)endParsing {
    @autoreleasepool {
        xmlParseChunk(_context, nil, 0, 1);
    xmlFreeParserCtxt(_context);
    _context = nil;
    self.xmlAttributesDict = nil;
    }
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
    [dict rs_safeSetObject:[self currentString] forKey:[self keyWithLocalName:localName prefix:prefix]];
    [self endStoringCharacters];    
}


- (void)appendCharacters:(const char *)charactersFound length:(NSUInteger)length {
    [_characterBuffer appendBytes:charactersFound length:length];
}


- (void)appendUTF8String:(const char *)utf8String { //nil-terminated
    [self appendCharacters:utf8String length:strlen(utf8String)];
}


- (NSDate *)currentDate {
    const void *bytes = [self currentBytes];
    if (bytes == nil)
        return nil;
    return RSDateWithBytes(bytes, [_characterBuffer length]);
}


- (const void *)currentBytes {
    if ([_characterBuffer length] < 1)
        return nil;
    return [_characterBuffer bytes];
}


- (NSString *)currentString {
    if ([_characterBuffer length] < 1)
        return nil;
    return [[NSString alloc] initWithData:_characterBuffer encoding:NSUTF8StringEncoding];
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
        NSMutableDictionary *attributesDict = [[NSMutableDictionary alloc] initWithCapacity:(NSUInteger)numberOfAttributes];
        //        BOOL anyValueContainsEntity = NO;
        int i = 0, j = 0;
        for (i = 0, j = 0; i < numberOfAttributes; i++, j+=5) {
            NSUInteger lenValue = (NSUInteger)(attributes[j + 4] - attributes[j + 3]);
            NSMutableString *value = [[NSMutableString alloc] initWithBytes:(const void *)attributes[j + 3] length:lenValue encoding:NSUTF8StringEncoding];
            if (value) {
                //                CFStringTrimWhitespace((CFMutableStringRef)value);
                [value rs_replaceEntity38WithAmpersand];
                //[value replaceXMLCharacterReferences];
            }
            NSString *attName = [[NSString alloc] initWithUTF8String:(const char *)attributes[j]];
            if (attributes[j + 1]) {
                NSString *attPrefix = [NSString stringWithUTF8String:(const char *)attributes[j + 1]];
                attName = [NSString stringWithFormat:@"%@:%@", attPrefix, attName];
            }
            [attributesDict setObject:value forKey:attName];
        }
        self.xmlAttributesDict = attributesDict;
    }
    if (RSIsEmpty(self.xmlAttributesDict))
        [_xmlAttributesStack addObject:[NSNull null]];
    else
        [_xmlAttributesStack addObject:self.xmlAttributesDict];
    //    [_xmlAttributesStack addObject:((void *)self.xmlAttributesDict != nil) ? self.xmlAttributesDict : [NSNull null]];
}


- (void)xmlEndElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri {
    self.xmlAttributesDict = [_xmlAttributesStack lastObject];
    if ((id)self.xmlAttributesDict == (id)[NSNull null])
        self.xmlAttributesDict = nil;
    [_xmlAttributesStack removeLastObject];
}


- (void)xmlCharactersFound:(const xmlChar *)ch length:(int)length {
    if (_storingCharacters)
        [self appendCharacters:(const char *)ch length:(NSUInteger)length];
}


- (void)logErrorContextToConsole {
#if TARGET_IPHONE_SIMULATOR
    if (self.dataURL)
        NSLog(@"SAX error parsing: %@", self.dataURL);
#endif
}


- (void)xmlEndDocument {
    ; /*For subclasses -- for instance, that need to call a delegate when parsing is finished.*/
}


@end


#pragma mark C -- SAX Callbacks from libxml2

static void startElementSAX(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI, int nb_namespaces, const xmlChar **namespaces, int nb_attributes, int nb_defaulted, const xmlChar **attributes) {
    [(__bridge RSSAXParser *)ctx xmlStartElement:localname prefix:prefix uri:URI numberOfNamespaces:nb_namespaces namespaces:namespaces numberOfAttributes:nb_attributes numberDefaulted:nb_defaulted attributes:attributes];
}


static void    endElementSAX(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI) {    
    [(__bridge RSSAXParser *)ctx xmlEndElement:localname prefix:prefix uri:URI];
}


static void    charactersFoundSAX(void *ctx, const xmlChar *ch, int len) {
    [(__bridge RSSAXParser *)ctx xmlCharactersFound:ch length:len];
}


//static void errorEncounteredSAX(void *ctx, const char *msg, ...) {
////    va_list args;    
////    va_start(args, msg);
////    fprintf(stdout, "SAX.error: ");
////    vfprintf(stdout, msg, args);
////    va_end(args);
////    [(RSSAXParser *)ctx logErrorContextToConsole];
//}


static void endDocumentSAX(void *ctx) {
    [(__bridge RSSAXParser *)ctx xmlEndDocument];
}


static xmlSAXHandler saxHandlerStruct = {
    nil,                       /* internalSubset */
    nil,                       /* isStandalone   */
    nil,                       /* hasInternalSubset */
    nil,                       /* hasExternalSubset */
    nil,                       /* resolveEntity */
    nil,                       /* getEntity */
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
    nil, //errorEncounteredSAX,       /* error */
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

