//
//  RSGoogleReaderConstants.m
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 12/3/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSGoogleReaderConstants.h"


NSString *RSGoogleReaderItemIDPrefix = @"tag:google.com,2005:reader/item/";
NSString *RSGoogleReaderItemIDPrefixFormat = @"tag:google.com,2005:reader/item/%@";

NSString *RSGoogleReaderItemIDsLimit = @"10000";
NSString *RSGoogleReaderItemIDsURLFormat = @"http://www.google.com/reader/api/0/stream/items/ids?%@";
NSString *RSGoogleReaderStatesParameterName = @"s";
NSString *RSGoogleReaderLimitParameterName = @"n";
NSString *RSGoogleReaderItemIDsParameterName = @"i";

NSString *RSGoogleReaderReadState = @"user/-/state/com.google/read";
NSString *RSGoogleReaderStarredState = @"user/-/state/com.google/starred";

NSString *RSGoogleReaderReadingListState = @"user/-/state/com.google/reading-list";
NSString *RSGoogleReaderExcludeParameterName = @"xt";

NSString *RSGoogleReaderFetchItemsByIDURL = @"http://www.google.com/reader/api/0/stream/items/contents?output=atom";


#pragma mark Login

NSString *SLGoogleReaderLoginErrorResponseStringBadAuthentication = @"BadAuthentication";
NSString *SLGoogleReaderLoginErrorResponseStringNotVerified = @"NotVerified";
NSString *SLGoogleReaderLoginErrorResponseStringTermsNotAgreed = @"TermsNotAgreed";
NSString *SLGoogleReaderLoginErrorResponseStringCaptchaRequired = @"CaptchaRequired";
NSString *SLGoogleReaderLoginErrorResponseStringUnknown = @"Unknown";
NSString *SLGoogleReaderLoginErrorResponseStringAccountDeleted = @"AccountDeleted";
NSString *SLGoogleReaderLoginErrorResponseStringAccountDisabled = @"AccountDisabled";
NSString *SLGoogleReaderLoginErrorResponseStringServiceDisabled = @"ServiceDisabled";
NSString *SLGoogleReaderLoginErrorResponseStringServiceUnavailable = @"ServiceUnavailable";

