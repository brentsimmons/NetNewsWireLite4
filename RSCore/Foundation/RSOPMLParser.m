//
//  RSOPMLParser.m
//  nnw
//
//  Created by Brent Simmons on 2/24/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "RSOPMLParser.h"
#import "RSFoundationExtras.h"


@interface RSOPMLParser ()
@property (nonatomic, retain) NSMutableArray *outlineDictStack;
@end


@implementation RSOPMLParser

@synthesize outlineItems;
@synthesize flattenedOutlineItems;
@synthesize outlineDictStack;


#pragma mark Init

- (id)init {
	if (![super init])
		return nil;
	outlineItems = [[NSMutableArray arrayWithCapacity:200] retain];
	flattenedOutlineItems = [[NSMutableArray arrayWithCapacity:200] retain];
	outlineDictStack = [[NSMutableArray arrayWithCapacity:10] retain];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[outlineItems release];
	[outlineDictStack release];
	[flattenedOutlineItems release];
	[super dealloc];
}



#pragma mark Parsing

- (void)addOutlineDictToFlattenedArray {
	[self.flattenedOutlineItems rs_safeAddObject:[self.outlineDictStack lastObject]];
}


- (void)addOutlineDictToCurrentArray {
	/*Top item in stack is current item. Parent (last - 1) contains current array. If no parent, then array is top-level _outlineItems.*/
	NSUInteger outlineDictStackSize = [self.outlineDictStack count];
	if (outlineDictStackSize < 2)
		[self.outlineItems rs_safeAddObject:[self.outlineDictStack lastObject]];
	else {
		NSMutableDictionary *currentParentDict = [self.outlineDictStack objectAtIndex:outlineDictStackSize - 2];
		NSMutableArray *childrenArray = [currentParentDict objectForKey:@"_children"];
		if (!childrenArray)
			[currentParentDict setObject:[NSMutableArray array] forKey:@"_children"];
		[childrenArray rs_safeAddObject:[self.outlineDictStack lastObject]];
	}
}


- (void)pushOutlineDict {
	[self.outlineDictStack rs_safeAddObject:self.xmlAttributesDict];
}


- (void)popOutlineDict {
	if ([self.outlineDictStack lastObject])
		[self.outlineDictStack removeLastObject];
}


#pragma mark SAX Callbacks

static const char *kOutlineTag = "outline";
static const NSUInteger kOutlineTag_Length = 5;


- (void)xmlStartElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri numberOfNamespaces:(int)numberOfNamespaces namespaces:(const xmlChar **)namespaces numberOfAttributes:(int)numberOfAttributes numberDefaulted:(int)numberDefaulted attributes:(const xmlChar **)attributes {
	
	if (!_xmlEqualTags(localName, kOutlineTag, kOutlineTag_Length))
		return;
	[super xmlStartElement:localName prefix:prefix uri:uri numberOfNamespaces:numberOfNamespaces namespaces:namespaces numberOfAttributes:numberOfAttributes numberDefaulted:numberDefaulted attributes:attributes];
	[self pushOutlineDict];
}


- (void)xmlEndElement:(const xmlChar *)localName prefix:(const xmlChar *)prefix uri:(const xmlChar *)uri {
	if (!_xmlEqualTags(localName, kOutlineTag, kOutlineTag_Length))
		return;
	[self addOutlineDictToCurrentArray];
	[self addOutlineDictToFlattenedArray];
	[self popOutlineDict];	
}


- (void)xmlCharactersFound:(const xmlChar *)ch length:(int)length {
	; /*All data is in attributes*/
}


@end
