//
//  RSDateParser.h
//  RSCoreTests
//
//  Created by Brent Simmons on 5/29/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/*Dates are hard.
 Parsing a date with NSDateFormatter is hard *and* slow.
 So we have cool super-fast C stuff to parse dates.
 Common web dates -- RFC 822 and 8601 -- are handled here:
 the formats you find in RSS and Atom feeds, for instance.
 We can add more formats as needed.
 
 Any of these may return nil. They may also return garbage, given bad input.
*/
 

/*Atom and RSS dates*/

NSDate *RSDateWithString(NSString *dateString);

/*In the context of a SAX parser, you have the bytes and don't need to convert to a string first.
 It's faster and uses less memory.*/

NSDate *RSDateWithBytes(const char *bytes, NSUInteger numberOfBytes);


/*Twitter*/

NSDate *RSTwitterTimelineDateWithBytes(const char *bytes, NSUInteger numberOfBytes);
NSDate *RSTwitterTimelineDateWithString(NSString *twitterDateString);
