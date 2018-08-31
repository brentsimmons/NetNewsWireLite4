//
//  SLJSONObjectBuilder.m
//  nnw
//
//  Created by Brent Simmons on 12/14/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "SLJSONObjectBuilder.h"


/*Because performance is so critical, direct ivar access is used.*/

//@interface SLJSONObjectBuilder ()
//
//@property (nonatomic, retain) SLJSONStreamingParser *jsonParser;
//@property (nonatomic, retain) NSMutableArray *objectStack;
//@end


@implementation SLJSONObjectBuilder

//@synthesize jsonParser;
//@synthesize objectStack;


#pragma mark Init

- (id)init {
	self = [super init];
	if (self == nil)
		return nil;
	jsonParser = [(SLJSONStreamingParser *)[SLJSONStreamingParser alloc] initWithDelegate:self];
	objectStack = [[NSMutableArray alloc] initWithCapacity:20];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[jsonParser release];
	[objectStack release];
	[super dealloc];
}


#pragma mark Accessors

- (id)jsonTree {
	return [objectStack rs_safeObjectAtIndex:0];
}


#pragma mark Parsing

- (BOOL)parseBytes:(const void *)bytes length:(NSUInteger)length error:(NSError **)error {
	BOOL success = NO;
	//NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	success = [jsonParser parseBytes:(unsigned char *)bytes length:length error:error];
	//[pool drain];
	return success;
}


- (BOOL)parseJSONDocument:(NSData *)jsonDocument error:(NSError **)error {
	BOOL success = [self parseBytes:[jsonDocument bytes] length:[jsonDocument length] error:error];
	[jsonParser finishParsing];
	return success;
}


- (BOOL)parseJSONDocumentString:(NSString *)jsonDocumentString error:(NSError **)error {
	return [self parseJSONDocument:[jsonDocumentString dataUsingEncoding:NSUTF8StringEncoding] error:error];
}


#pragma mark Stack

- (void)addKey:(NSString *)key andObject:(id)anObject {
	CFMutableDictionaryRef currentObject = (CFMutableDictionaryRef)[objectStack lastObject];
	CFDictionarySetValue(currentObject, (CFStringRef)key, (CFTypeRef)anObject); //Must use CFDictionarySetValue to avoid key-copying
//	NSMutableDictionary *currentObject = [self.objectStack lastObject]; //it must be a dictionary
//	[currentObject setObject:anObject forKey:key];
}


- (void)addObjectToCurrentObject:(id)anObject {
	id currentObject = [objectStack lastObject];
	if (currentObject == nil)
		[objectStack addObject:anObject];
	else if ([currentObject isKindOfClass:[NSString class]]) {
		NSString *key = [[currentObject retain] autorelease];
		[objectStack removeObjectAtIndex:[objectStack count] - 1];
		return [self addKey:key andObject:anObject];
	}
	else if ([currentObject isKindOfClass:[NSMutableArray class]])
		[currentObject addObject:anObject];
}


- (void)addCurrentObjectToPreviousObject {
	id currentObject = [[[objectStack lastObject] retain] autorelease];
	[objectStack removeObjectAtIndex:[objectStack count] - 1];
	[self addObjectToCurrentObject:currentObject];
}


#pragma mark SLJSONStreamingParserDelegate

- (void)objectDidStart {
	CFMutableDictionaryRef aDictionary = CFDictionaryCreateMutable(kCFAllocatorDefault, 40, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	[objectStack addObject:(id)aDictionary];//[NSMutableDictionary dictionary]];
	NSMakeCollectable(aDictionary);
}


- (void)objectDidEnd {
	[self addCurrentObjectToPreviousObject];
}


- (void)arrayDidStart {
	[objectStack addObject:[NSMutableArray array]];
}


- (void)arrayDidEnd {
	[self addCurrentObjectToPreviousObject];
}


- (void)nullValueFound {
	[self addObjectToCurrentObject:[NSNull null]];
}


- (void)trueValueFound {
	[self addObjectToCurrentObject:[NSNumber numberWithBool:YES]];
}


- (void)falseValueFound {
	[self addObjectToCurrentObject:[NSNumber numberWithBool:NO]];
}


- (void)valueFound:(unsigned char *)characters length:(NSUInteger)length {
	//CFStringRef value = CFStringCreateWithBytes(kCFAllocatorDefault, characters, (signed long)length, kCFStringEncodingUTF8, NO);	
	NSString *value = [[[NSString alloc] initWithBytes:characters length:length encoding:NSUTF8StringEncoding] autorelease];
	[self addObjectToCurrentObject:(id)value];
	//CFRelease(value);
	
}


- (void)nameFound:(unsigned char *)characters length:(NSUInteger)length {
//	CFStringRef name = CFStringCreateWithBytes(kCFAllocatorDefault, characters, (signed long)length, kCFStringEncodingUTF8, NO);	
	NSString *name = [[[NSString alloc] initWithBytes:characters length:length encoding:NSUTF8StringEncoding] autorelease];
	[objectStack addObject:(id)name];
//	CFRelease(name);
}


@end


@interface SLJSONIgnorer ()

@property (nonatomic, retain) SLJSONStreamingParser *jsonParser;
@end



@implementation SLJSONIgnorer

@synthesize jsonParser;


#pragma mark Init

- (id)init {
	self = [super init];
	if (self == nil)
		return nil;
	jsonParser = [(SLJSONStreamingParser *)[SLJSONStreamingParser alloc] initWithDelegate:self];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[jsonParser release];
	[super dealloc];
}


#pragma mark Parsing

- (BOOL)parseBytes:(const void *)bytes length:(NSUInteger)length error:(NSError **)error {
	BOOL success = NO;
	//NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	success = [self.jsonParser parseBytes:(unsigned char *)bytes length:length error:error];
	//[pool drain];
	return success;
}


- (BOOL)parseJSONDocument:(NSData *)jsonDocument error:(NSError **)error {
	BOOL success = [self parseBytes:[jsonDocument bytes] length:[jsonDocument length] error:error];
	[self.jsonParser finishParsing];
	return success;
}


- (BOOL)parseJSONDocumentString:(NSString *)jsonDocumentString error:(NSError **)error {
	return [self parseJSONDocument:[jsonDocumentString dataUsingEncoding:NSUTF8StringEncoding] error:error];
}


#pragma mark SLJSONStreamingParserDelegate

- (void)objectDidStart {
}


- (void)objectDidEnd {
}


- (void)arrayDidStart {
}


- (void)arrayDidEnd {
}


- (void)nullValueFound {
}


- (void)trueValueFound {
}


- (void)falseValueFound {
}


- (void)valueFound:(unsigned char *)characters length:(NSUInteger)length {
}


- (void)nameFound:(unsigned char *)characters length:(NSUInteger)length {
}



@end

