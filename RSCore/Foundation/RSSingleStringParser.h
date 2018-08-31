//
//  RSSingleStringParser.h
//  RSCoreTests
//
//  Created by Brent Simmons on 8/3/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSSAXParser.h"


/*Pulls a string from one tag. When done, get parser.returnedString.*/

NSString *RSParseSingleStringWithTag(NSData *xmlData, NSString *tagName); //Or do it the easy way


@interface RSSingleStringParser : RSSAXParser {
@private
    NSString *tagName;
    NSString *returnedString;
}


@property (nonatomic, strong) NSString *tagName; /*Whose string value we'll get*/
@property (nonatomic, strong, readonly) NSString *returnedString;


@end
