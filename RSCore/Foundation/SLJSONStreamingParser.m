//
//  SLJSONStreamingParser.m
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 12/13/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "SLJSONStreamingParser.h"


/*Because performance is so critical, direct ivar access is used instead of via properties.*/

@interface SLJSONStreamingParser ()

//@property (nonatomic, assign) id<SLJSONStreamingParserDelegate> delegate;
//@property (nonatomic, retain) NSMutableData *nameOrValueBuffer;
//@property (nonatomic, retain) SLJSONScanner *jsonScanner;

- (void)sendValueToDelegate;

@end


@implementation SLJSONStreamingParser


#pragma mark Init

- (id)initWithDelegate:(id<SLJSONStreamingParserDelegate>)aDelegate {
	if (aDelegate == nil)
		return nil;
	self = [super init];
	if (self == nil)
		return nil;
	delegate = aDelegate;
	jsonScanner = [[SLJSONScanner alloc] initWithDelegate:self];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[nameOrValueBuffer release];
	[jsonScanner release];
	[super dealloc];
}


#pragma mark Public API

- (BOOL)parseBytes:(unsigned char *)bytes length:(NSUInteger)length error:(NSError **)error {
	return [jsonScanner scanBytes:bytes length:length error:error];
}


- (void)finishParsing {
	[self sendValueToDelegate];
	[nameOrValueBuffer release];
	nameOrValueBuffer = nil;
	[jsonScanner release];
	jsonScanner = nil;
//	self.nameOrValueBuffer = nil;
//	self.jsonScanner = nil;
}


#pragma mark SLJSONScannerDelegate

- (void)sendValueToDelegate {
	
	NSUInteger numberOfBytes = [nameOrValueBuffer length];
	if (numberOfBytes < 1)
		return;
	
	BOOL didCallDelegate = NO;
	if (numberOfBytes == 4 || numberOfBytes == 5) {
		void *value = [nameOrValueBuffer mutableBytes];
		if (memcmp(value, "null", 4) == 0) {
			didCallDelegate = YES;
			[delegate nullValueFound];
		}
		else if (memcmp(value, "true", 4) == 0) {
			didCallDelegate = YES;
			[delegate trueValueFound];
		}
		else if (memcmp(value, "false", 5) == 0) {
			didCallDelegate = YES;
			[delegate falseValueFound];
		}
	}
	
	if (!didCallDelegate)
		[delegate valueFound:[nameOrValueBuffer mutableBytes] length:numberOfBytes]; //strings and numbers
	[nameOrValueBuffer setLength:0];	
}


- (void)objectDidStart {
	[delegate objectDidStart];
}


- (void)objectDidEnd {
	[self sendValueToDelegate];
	[delegate objectDidEnd];
}


- (void)arrayDidStart {
	[delegate arrayDidStart];
}


- (void)arrayDidEnd {
	[self sendValueToDelegate];
	[delegate arrayDidEnd];
}


- (void)nameValueSeparatorFound {
	NSUInteger numberOfBytes = [nameOrValueBuffer length];
	if (numberOfBytes < 1)
		return;
	[delegate nameFound:[nameOrValueBuffer mutableBytes] + 1 length:numberOfBytes - 2]; //strip leading and trailing "
	[nameOrValueBuffer setLength:0];
}


- (void)valueSeparatorFound {
	[self sendValueToDelegate];
}


- (void)charactersFound:(unsigned char *)characters length:(NSUInteger)length {
	if (nameOrValueBuffer == nil)
		nameOrValueBuffer = [[NSMutableData dataWithCapacity:MAX(length * 4, 8 * 1024ULL)] retain];
	[nameOrValueBuffer appendBytes:characters length:length];
}


@end
