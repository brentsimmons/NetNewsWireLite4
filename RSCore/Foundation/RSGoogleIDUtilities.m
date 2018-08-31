//
//  RSGoogleIDUtilities.m
//  RSCoreTests
//
//  Created by Brent Simmons on 5/29/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSGoogleIDUtilities.h"
#import "RSFoundationExtras.h"


//NSString *RSGoogleGuidPrefix = @"tag:google.com,2005:reader/item/";
//
//static const NSUInteger kLongGoogleItemIDLength = 32;
//
//
//BOOL RSGoogleIsLongItemID(NSString *itemID) {
//	return [itemID length] == kLongGoogleItemIDLength && [itemID hasPrefix:RSGoogleGuidPrefix];
//}


//static NSString *rs_forwardSlash = @"/";
//
//NSString *RSGoogleShortItemIDForLongItemID(NSString *itemID) {
//	if (RSStringIsEmpty(itemID))
//		return itemID;
//	if ([itemID length] == 16)
//		return itemID;
//	if ([itemID rangeOfString:rs_forwardSlash options:0].location == NSNotFound)
//		return itemID; //Shouldn't get here
//	return [[itemID componentsSeparatedByString:rs_forwardSlash] lastObject];
//}
