//
//  RSRefreshStreamingFeedOperation.m
//  padlynx
//
//  Created by Brent Simmons on 9/3/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSRefreshStreamingFeedOperation.h"
#import "RSFeedSpecifier.h"
#import "RSAtomParser.h"
#import "RSDataManagedObjects.h"
#import "RSFeedTypeDetector.h"
#import "RSRSSParser.h"


@interface RSRefreshStreamingFeedOperation()

@property (nonatomic, retain) id<RSFeedSpecifier> feedSpecifier;
@property (nonatomic, retain) id<RSAccount> account;
@property (nonatomic, retain) NSManagedObjectContext *temporaryMOC;

@end


@implementation RSRefreshStreamingFeedOperation

@synthesize feedSpecifier;
@synthesize account;
@synthesize articleSaver;
@synthesize temporaryMOC;

#pragma mark Init

- (id)initWithFeedSpecifier:(id<RSFeedSpecifier>)aFeedSpecifier account:(id<RSAccount>)anAccount {
	self = [super initWithURL:aFeedSpecifier.URL delegate:nil callbackSelector:nil parser:nil useWebCache:NO];
	if (self == nil)
		return nil;	
	self.operationObject = aFeedSpecifier;
	feedSpecifier = [(id)aFeedSpecifier retain];
	account = [(id)anAccount retain];
	self.operationType = RSOperationTypeDownloadFeed;
	self.temporaryMOC = rs_app_delegate.temporaryManagedObjectContext;
	if ([aFeedSpecifier respondsToSelector:@selector(logicalEtagHeader)])
		[self.extraRequestHeaders rs_safeSetObject:aFeedSpecifier.logicalEtagHeader forKey:RSHTTPRequestHeaderIfNoneMatch];
	if ([aFeedSpecifier respondsToSelector:@selector(logicalLastModifiedHeader)])
		[self.extraRequestHeaders rs_safeSetObject:aFeedSpecifier.logicalLastModifiedHeader forKey:RSHTTPRequestHeaderIfModifiedSince];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[(id)feedSpecifier release];
	[(id)account release];
	[(id)articleSaver release];
	[temporaryMOC release];
	[super dealloc];
}


#pragma mark RSDownloadOperation

- (void)download {
	[super download];
	if (self.statusCode == RSHTTPStatusOK || self.statusCode == RSHTTPStatusNotModified)
		[(RSFeedSpecifier *)(self.feedSpecifier) saveCheckDate:[NSDate date] andConditionalGetInfo:self.conditionalGetInfoResponse];
	else
		[(RSFeedSpecifier *)(self.feedSpecifier) saveCheckDate:[NSDate date] andConditionalGetInfo:nil];
	[rs_app_delegate saveManagedObjectContext:self.temporaryMOC];
	self.temporaryMOC = nil;
}


#pragma mark Parser

- (void)startParserIfNeeded {
	if (self.statusCode != RSHTTPStatusOK || self.didStartParser || [self.responseBody length] < 50)
		return;
	RSFeedType feedType = RSFeedTypeForData(self.responseBody);
	if (feedType == RSFeedTypeNotAFeed) {
		[self.urlConnection cancel];
		self.finishedReading = YES;
		return;
	}
	self.didStartParser = YES;
	if (feedType == RSFeedTypeRSS)
		self.parser = [[[RSRSSParser alloc] init] autorelease];
	else if (feedType == RSFeedTypeAtom)
		self.parser = [[[RSAtomParser alloc] init] autorelease];
	((RSAbstractFeedParser *)(self.parser)).delegate = self.articleSaver;
	[self.parser startParsing:self.responseBody];	
}


#pragma mark NSURLConnection Delegate

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[super connection:connection didReceiveData:data];
	[self startParserIfNeeded];
}


@end
