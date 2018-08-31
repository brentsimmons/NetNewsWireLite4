//
//  NNWGoogleUtilities.m
//  nnwiphone
//
//  Created by Brent Simmons on 8/6/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWGoogleUtilities.h"

NSString *NNWGoogleClientName = @"NNW-iPhone";


@implementation NNWGoogleUtilities


+ (NSString *)urlStringWithClientAppended:(NSString *)urlString {
	NSMutableString *urlStringWithClientAppended = [NSMutableString stringWithString:urlString];
	if ([urlString caseSensitiveContains:@"?"])
		[urlStringWithClientAppended appendString:@"&"];
	else
		[urlStringWithClientAppended appendString:@"?"];
	[urlStringWithClientAppended appendString:@"client="];
	[urlStringWithClientAppended appendString:NNWGoogleClientName];
	return urlStringWithClientAppended;
}


+ (NSURL *)urlWithClientAppended:(NSString *)urlString {
	return [NSURL URLWithString:[self urlStringWithClientAppended:urlString]];
}


@end
