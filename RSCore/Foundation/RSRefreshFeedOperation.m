//
//  NNWRefreshFeedOperation.m
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 6/27/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSRefreshFeedOperation.h"
#import "NNWCredentialsWindowController.h"
#import "RSDataAccount.h"
#import "RSDataController.h"
#import "RSFeed.h"
#import "RSFeedParserProxy.h"
#import "RSFeedTypeDetector.h"
#import "RSLocalAccountCoreDataArticleSaverOperation.h"
#import "RSLocalAccountFeedMetadataCache.h"
#import "RSParsedFeedInfo.h"
#import "RSRefreshProtocols.h"


@interface RSRefreshFeedOperation ()

@property (nonatomic, strong) NSURL *feedURL;
@property (nonatomic, strong) NSString *accountIdentifier;
@property (nonatomic, assign) BOOL didTryUsernameAndPassword;

- (void)processFeed;

@end


@implementation RSRefreshFeedOperation

@synthesize accountIdentifier;
@synthesize feedURL;
@synthesize didTryUsernameAndPassword;


#pragma mark Init

- (id)initWithFeedURL:(NSURL *)aFeedURL accountIdentifier:(NSString *)anAccountIdentifier {
    self = [super initWithURL:aFeedURL delegate:nil callbackSelector:nil parser:nil useWebCache:NO];
    if (self == nil)
        return nil;    
    self.operationObject = aFeedURL;
    feedURL = aFeedURL;
    accountIdentifier = anAccountIdentifier;
    self.operationType = RSOperationTypeDownloadFeed;
    return self;
}


#pragma mark Dealloc



#pragma mark RSDownloadOperation

- (void)createRequest {
    RSHTTPConditionalGetInfo *conditionalGetInfo = [[RSLocalAccountFeedMetadataCache sharedCache] conditionalGetInfoForFeedURL:self.feedURL];
    [self.extraRequestHeaders rs_safeSetObject:conditionalGetInfo.httpResponseEtag forKey:RSHTTPRequestHeaderIfNoneMatch];
    [self.extraRequestHeaders rs_safeSetObject:conditionalGetInfo.httpResponseLastModified forKey:RSHTTPRequestHeaderIfModifiedSince];    
    [super createRequest];
}


- (void)download {
    if (![self isCancelled])
        [super download];
    if (![self isCancelled])
        [self processFeed];
}


- (void)runCredentialsWindow:(NSMutableDictionary *)credentialsDictionary {
    
    /*This method runs on the main thread. It's okay to talk to RSDataAccount, RSFeed, etc.*/
    
    id<RSAccount> account = [rs_app_delegate.dataController accountWithID:self.accountIdentifier];
    if (account == nil || ![account respondsToSelector:@selector(feedWithURL:)])
        return;
    RSFeed *feed = [(RSDataAccount *)account feedWithURL:self.feedURL];
    if (feed == nil)
        return;
    NSString *nameForDisplay = feed.nameForDisplay;
    if (nameForDisplay == nil)
        nameForDisplay = [[credentialsDictionary objectForKey:RSURLKey] absoluteString];
    if (nameForDisplay == nil)
        nameForDisplay = [self.feedURL absoluteString];
    
    NNWCredentialsWindowController *credentialsWindowController = [[NNWCredentialsWindowController alloc] init];
    [credentialsWindowController window];
    
    NSString *usernameAndPasswordQuoted = NSLocalizedStringFromTable(@"Enter username and password for “%@.”", @"Subscribing", @"Credentials sheet message");
    NSString *credentialsMessage = [NSString stringWithFormat:usernameAndPasswordQuoted, nameForDisplay];
    [credentialsWindowController.messageTextField setStringValue:credentialsMessage];
    
    NNWCredentialsResult *credentialsResult = [credentialsWindowController runModalForBackgroundWindow:nil];
    if (credentialsResult == nil)
        return;
    [credentialsDictionary setObject:credentialsResult forKey:@"result"];
    if (!RSStringIsEmpty(credentialsResult.username)) {
        feed.username = credentialsResult.username;
        if (!RSStringIsEmpty(credentialsResult.password)) {
            feed.password = credentialsResult.password;
            [feed savePasswordInKeychain];
        }
    }
}


- (void)askUserForCredentials:(NSURL *)aURL {
    NSMutableDictionary *credentialsDictionary = [NSMutableDictionary dictionary];
    [credentialsDictionary setObject:aURL forKey:RSURLKey];
    [self performSelectorOnMainThread:@selector(runCredentialsWindow:) withObject:credentialsDictionary waitUntilDone:YES];
    
    NNWCredentialsResult *credentialsResult = [credentialsDictionary objectForKey:@"result"];
    self.username = credentialsResult.username;
    self.password = credentialsResult.password;    
}


- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
    if ([self isCancelled]) {
        [[challenge sender] cancelAuthenticationChallenge:challenge];
        return;
    }
    
    BOOL didAskUserForCredentials = NO;
    
    if (self.didTryUsernameAndPassword || (RSStringIsEmpty(self.username) && RSStringIsEmpty(self.password))) {
        didAskUserForCredentials = YES;
        [self askUserForCredentials:[self.urlRequest URL]];
    }
    
    if (RSStringIsEmpty(self.password) && !RSStringIsEmpty(self.username)) {
        /*Get from keychain -- have username but not password.*/
        self.password = RSKeychainFetchInternetPassword(self.feedURL, self.username);
        if (RSStringIsEmpty(self.password) && !didAskUserForCredentials) {
            //didAskUserForCredentials = YES;
            [self askUserForCredentials:[self.urlRequest URL]];
        }
    }
    
    if (!RSStringIsEmpty(self.username) && !RSStringIsEmpty(self.password) && [challenge previousFailureCount] < 3) {
        self.didTryUsernameAndPassword = YES;
        NSURLCredential *newCredential = [NSURLCredential credentialWithUser:self.username password:self.password persistence:NSURLCredentialPersistenceForSession];
        [[challenge sender] useCredential:newCredential forAuthenticationChallenge:challenge];
        return;
    }
    
    [[challenge sender] cancelAuthenticationChallenge:challenge];
}


#pragma mark Processing

- (void)processNotAFeed {
    self.responseBody = nil;
}


- (void)processNotModifiedFeed {
    /*304 -- or 200 with empty feed data -- or 200 and feed data is same as last time*/
    self.responseBody = nil;
}


- (void)saveArticles:(NSArray *)articles {
    /*Create an operation on the special serial Core Data Queue for saving news items.*/
    RSLocalAccountCoreDataArticleSaverOperation *localAccountCoreDataArticleSaverOperation = [[RSLocalAccountCoreDataArticleSaverOperation alloc] initWithParsedArticles:articles feedURL:self.feedURL accountIdentifier:self.accountIdentifier];
    [rs_app_delegate addCoreDataBackgroundOperation:localAccountCoreDataArticleSaverOperation];
}


- (void)parseAndProcessFeed {
    
    self.parser = [[RSFeedParserProxy alloc] init];
    RSFeedParserProxy *feedParser = (RSFeedParserProxy *)(self.parser);
    
    NSError *parseError = nil;
    [self.parser parseData:self.responseBody error:&parseError];

    if (![self isCancelled])        
        [self saveArticles:feedParser.newsItems];
    
    if (![self isCancelled]) {
        if (feedParser.feedHomePageURL != nil || feedParser.feedTitle != nil) {
            RSParsedFeedInfo *feedInfo = [[RSParsedFeedInfo alloc] init];
            feedInfo.feedURLString = [self.feedURL absoluteString];
            feedInfo.homePageURLString = feedParser.feedHomePageURL;
            feedInfo.title = feedParser.feedTitle;
            [feedInfo sendDidParseFeedInfoNotification];
        }
    }
    
    self.responseBody = nil;
    self.parser = nil;
}


- (void)handle200 {
    if (RSIsEmpty(self.responseBody)) {
        [self processNotModifiedFeed];
        return;
    }
    NSData *feedData = self.responseBody;
    RSFeedType feedType = RSFeedTypeForData(feedData);
    if (feedType == RSFeedTypeNotAFeed) {
        [self processNotAFeed];
        return;
    }
    
    if ([self isCancelled])
        return;
    
    /*Check md5 hash -- if same hash as last download, skip processing.*/
    NSData *previousHash = [[RSLocalAccountFeedMetadataCache sharedCache] contentHashForFeedURL:self.feedURL];
    NSData *responseBodyHash = [self.responseBody rs_md5Hash];
    if (!RSIsEmpty(previousHash)) {
        if ([previousHash isEqualToData:responseBodyHash]) {
            [self processNotModifiedFeed];
            return;
        }
    }
    
    if (![self isCancelled])
        [self parseAndProcessFeed];
    
    if (![self isCancelled]) {
        [[RSLocalAccountFeedMetadataCache sharedCache] setContentHash:responseBodyHash forFeedURL:self.feedURL];
        [[RSLocalAccountFeedMetadataCache sharedCache] setConditionalGetInfo:[RSHTTPConditionalGetInfo conditionalGetInfoWithURLResponse:self.urlResponse] forFeedURL:self.feedURL];
    }
}


- (void)handle304 {
    [self processNotModifiedFeed];
}


- (void)processFeed {
    /*Handle response codes, including 304s and redirects and not-founds.*/
    if ([self isCancelled])
        return;
    if (self.statusCode == 200)
        [self handle200];
    else if (self.statusCode == 304)
        [self handle304];
}


@end
