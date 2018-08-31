//
//  RSGoogleReaderConstants.h
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 12/3/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString *RSGoogleReaderItemIDPrefix; //@"tag:google.com,2005:reader/item/"
extern NSString *RSGoogleReaderItemIDPrefixFormat; //@"tag:google.com,2005:reader/item/%@";

extern NSString *RSGoogleReaderItemIDsLimit; //@"10000";
extern NSString *RSGoogleReaderItemIDsURLFormat; //@"http://www.google.com/reader/api/0/stream/items/ids?%@";
extern NSString *RSGoogleReaderStatesParameterName; //@"s";
extern NSString *RSGoogleReaderLimitParameterName; //@"n";
extern NSString *RSGoogleReaderItemIDsParameterName; //@"i";

extern NSString *RSGoogleReaderReadState; //@"user/-/state/com.google/read";
extern NSString *RSGoogleReaderStarredState; //@"user/-/state/com.google/starred";

extern NSString *RSGoogleReaderReadingListState; //@"user/-/state/com.google/reading-list";
extern NSString *RSGoogleReaderExcludeParameterName; //@"xt";

extern NSString *RSGoogleReaderFetchItemsByIDURL; //@"http://www.google.com/reader/api/0/stream/items/contents?output=atom";


/*Login*/

extern NSString *SLGoogleReaderLoginErrorResponseStringBadAuthentication; //@"BadAuthentication"
extern NSString *SLGoogleReaderLoginErrorResponseStringNotVerified; //@"NotVerified"
extern NSString *SLGoogleReaderLoginErrorResponseStringTermsNotAgreed; //@"TermsNotAgreed"
extern NSString *SLGoogleReaderLoginErrorResponseStringCaptchaRequired; //@"CaptchaRequired"
extern NSString *SLGoogleReaderLoginErrorResponseStringUnknown; //@"Unknown"
extern NSString *SLGoogleReaderLoginErrorResponseStringAccountDeleted; //@"AccountDeleted"
extern NSString *SLGoogleReaderLoginErrorResponseStringAccountDisabled; //@"AccountDisabled"
extern NSString *SLGoogleReaderLoginErrorResponseStringServiceDisabled; //@"ServiceDisabled"
extern NSString *SLGoogleReaderLoginErrorResponseStringServiceUnavailable; //@"ServiceUnavailable"


typedef enum _RSGoogleReaderLoginResponseCode {
	RSGoogleReaderLoginResponseCodeSuccess,
	RSGoogleReaderLoginResponseCodeBadAuthentication,
	RSGoogleReaderLoginResponseCodeNotVerified,
	RSGoogleReaderLoginResponseCodeTermsNotAgreed,
	RSGoogleReaderLoginResponseCodeCaptchaRequired,
	RSGoogleReaderLoginResponseCodeUnknown,
	RSGoogleReaderLoginResponseCodeAccountDeleted,
	RSGoogleReaderLoginResponseCodeAccountDisabled,
	RSGoogleReaderLoginResponseCodeServiceDisabled,
	RSGoogleReaderLoginResponseCodeServiceUnavailable
} RSGoogleReaderLoginResponseCode;

