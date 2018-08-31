//
//  NNWTinyUrlOperation.m
//  ModalView
//
//  Created by Nick Harris on 3/13/10.
//  Copyright 2010 Sirrahsoft LLC. All rights reserved.
//

#import "RSFetchTinyURLOperation.h"


NSString *RSFetchShortenedURLOperationDidComplete = @"RSCreateShortenedURLOperationDidComplete";
NSString *RSFetchShortenedURLOperationDidFail = @"RSCreateShortenedURLOperationDidFail";

NSString *RSOriginalURLKey = @"original";
NSString *RSShortenedURLKey = @"shortened";

@implementation RSFetchTinyURLOperation

@synthesize shortenedURLString;
@synthesize originalURLString;


#pragma mark Init

- (id)initWithOriginalURLString:(NSString *)anOriginalURLString {
	NSString *urlString = [NSString stringWithFormat:@"http://tinyurl.com/api-create.php?url=%@", anOriginalURLString];
	/*Okay to use web cache because tinyurl.com should report same thing every time.*/
	self = [super initWithURL:[NSURL URLWithString:urlString] delegate:nil callbackSelector:nil parser:nil useWebCache:YES];
	if (self == nil)
		return nil;
	operationType = RSOperationTypeCreateShortenedURL;
	originalURLString = [anOriginalURLString retain];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[originalURLString release];
	[shortenedURLString release];
	[super dealloc];
}


#pragma mark Notifications

- (void)reportShortenedURL {
	self.shortenedURLString = [NSString rs_stringWithUTF8EncodedData:self.responseBody];
	NSMutableDictionary *d = [NSMutableDictionary dictionary];
	[d rs_safeSetObject:self.originalURLString forKey:RSOriginalURLKey];
	[d rs_safeSetObject:self.shortenedURLString forKey:RSShortenedURLKey];
	[[NSNotificationCenter defaultCenter] rs_postNotificationOnMainThread:RSFetchShortenedURLOperationDidComplete object:self userInfo:d];	
}


- (void)reportFailure {
	[[NSNotificationCenter defaultCenter] rs_postNotificationOnMainThread:RSFetchShortenedURLOperationDidFail object:self userInfo:nil];	
}


#pragma mark RSOperation

- (void)main {
	if (self.useWebCache && [self fetchCachedObject])
		[self reportShortenedURL];
	else {
		[self download];
		if ([self okResponse])
			[self reportShortenedURL];
		else
			[self reportFailure];
	}
	[self notifyObserversThatOperationIsComplete];
}


@end
