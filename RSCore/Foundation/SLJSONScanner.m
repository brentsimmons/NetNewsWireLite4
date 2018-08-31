//
//  SLJSONScanner.m
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 12/14/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "SLJSONScanner.h"


/*Because performance is so important, the scanner does direct ivar access instead of access via properties.*/

@interface SLJSONScanner ()

//@property (nonatomic, assign) id<SLJSONScannerDelegate> delegate;
//@property (nonatomic, assign) unsigned char *jsonBytes;
//@property (nonatomic, assign) BOOL inNameOrValue;
//@property (nonatomic, assign) NSUInteger quoteLevel;
//@property (nonatomic, assign) NSUInteger numberOfJSONBytes;
//@property (nonatomic, assign) NSUInteger indexOfNameOrValueStart;
//@property (nonatomic, assign) BOOL lastCharacterWasEscape;

- (void)continueScanning;

@end


@implementation SLJSONScanner

//@synthesize delegate;
//@synthesize jsonBytes;
//@synthesize inNameOrValue;
//@synthesize quoteLevel;
//@synthesize numberOfJSONBytes;
//@synthesize indexOfNameOrValueStart;
//@synthesize lastCharacterWasEscape;


#pragma mark Init

- (id)initWithDelegate:(id<SLJSONScannerDelegate>)aDelegate {
	if (aDelegate == nil)
		return nil;
	self = [super init];
	if (self == nil)
		return nil;
	delegate = aDelegate;
	return self;
}


#pragma mark Public API

- (BOOL)scanBytes:(unsigned char *)bytes length:(NSUInteger)length error:(NSError **)error {
	jsonBytes = bytes;
	numberOfJSONBytes = length;
	indexOfNameOrValueStart = 0;
	[self continueScanning];
	return YES;	
}


#pragma mark Scanning

- (BOOL)processPossibleToken:(unsigned char)ch {
	if (ch != '{' && ch != '}' && ch != '[' && ch != ']' && ch != ':' && ch != ',')
		return NO;
	switch (ch) {
		case '{':
			[delegate objectDidStart];
			break;
		case '}':
			[delegate objectDidEnd];
			break;
		case '[':
			[delegate arrayDidStart];
			break;
		case ']':
			[delegate arrayDidEnd];
			break;
		case ':':
			[delegate nameValueSeparatorFound];
			break;
		case ',':
			[delegate valueSeparatorFound];
			break;
		default:
			break;
	}
	return YES;
}


- (BOOL)processPossibleNameOrValueStart:(unsigned char)ch indexOfByte:(NSUInteger)indexOfByte {
	if (ch < 33) //space is 32, ctrl characters are smaller
		return NO;
	if (ch == '"') {
		quoteLevel = 1;
		indexOfNameOrValueStart = indexOfByte;// + 1;
		inNameOrValue = YES;
		return YES;
	}
	if (ch == '+' || ch == '-' || ch == 'E' || ch == 'e' || ch == 'n' || ch == 'f' || ch == 't' || ch == '.' || isdigit(ch)) { //number, or false/true/null
		indexOfNameOrValueStart = indexOfByte;
		inNameOrValue = YES;
		return YES;
	}
	return NO;
}


- (void)sendNameOrValueCharactersToDelegate:(NSUInteger)indexOfByte {
	if (indexOfNameOrValueStart == NSNotFound)
		return;
	[delegate charactersFound:(jsonBytes) + indexOfNameOrValueStart length:(indexOfByte + 1) - indexOfNameOrValueStart];
}


- (void)processNameOrValueCharacter:(unsigned char)ch indexOfByte:(NSUInteger)indexOfByte isLastCharacter:(BOOL)isLastCharacter {
	if ((ch < 33 || ch == ',' || ch == '}' || ch == ']') && quoteLevel < 1) {
		[self sendNameOrValueCharactersToDelegate:indexOfByte - 1];
		inNameOrValue = NO;
		indexOfNameOrValueStart = NSNotFound;
		[self processPossibleToken:ch];
	}
	else if (!lastCharacterWasEscape && quoteLevel == 1 && ch == '"') {
		quoteLevel = 0;
		[self sendNameOrValueCharactersToDelegate:indexOfByte];// - 1];
		inNameOrValue = NO;
		return;
	}
	else if (isLastCharacter) {
		[self sendNameOrValueCharactersToDelegate:indexOfByte];
		indexOfNameOrValueStart = NSNotFound;
	}
	if (ch == '\\')
		lastCharacterWasEscape = !lastCharacterWasEscape;
}


- (void)continueScanning {
	unsigned char ch = 0;
	NSUInteger indexOfByte = 0;
	for (indexOfByte = 0; indexOfByte < numberOfJSONBytes; indexOfByte++) {
		ch = (jsonBytes)[indexOfByte];
		if (inNameOrValue) {
			BOOL isLastCharacter = (indexOfByte == numberOfJSONBytes - 1);
			[self processNameOrValueCharacter:ch indexOfByte:indexOfByte isLastCharacter:isLastCharacter];
		}
		else {
			if (!isspace(ch) && ![self processPossibleToken:ch])
				[self processPossibleNameOrValueStart:ch indexOfByte:indexOfByte];
		}
	}
}


@end
