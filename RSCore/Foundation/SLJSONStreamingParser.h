//
//  SLJSONStreamingParser.h
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 12/13/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SLJSONScanner.h"


/*Not using modern runtime because using in NetNewsWire 3.2.x.

 Use on any thread -- but a given instance should be used
 only on the thread where it was created. You could put a lock
 around calls to parseBytes:length:error: and be okay --
 but you probably have an architectural bug if you're using
 a given instance on multiple threads.
 
The main points of this parser:
 1. It tries to allocate little memory.
 2. It does not require caller to have entire document in memory.

 It doesn't do any validation. It's forgiving. The main thing is *performance*.
*/


@protocol SLJSONStreamingParserDelegate <NSObject>

@required

- (void)objectDidStart; //{
- (void)objectDidEnd; //}
- (void)arrayDidStart; //[
- (void)arrayDidEnd; //]

/*If null, true, or false, the specific methods are called instead of valueFound:length:*/
- (void)nullValueFound;
- (void)trueValueFound;
- (void)falseValueFound;

/*If the found value is a string, it will start and end with a " character.
 Otherwise it should be interepreted as a number, which is left as an exercise for the delegate.*/
- (void)valueFound:(unsigned char *)characters length:(NSUInteger)length;

- (void)nameFound:(unsigned char *)characters length:(NSUInteger)length;

@end


@interface SLJSONStreamingParser : NSObject <SLJSONScannerDelegate> {
@private
	id<SLJSONStreamingParserDelegate> delegate;
	NSMutableData *nameOrValueBuffer;
	SLJSONScanner *jsonScanner;
}


- (id)initWithDelegate:(id<SLJSONStreamingParserDelegate>)aDelegate; //delegate is required

/*Keep calling.*/

- (BOOL)parseBytes:(unsigned char *)bytes length:(NSUInteger)length error:(NSError **)error;

/*When there are no more bytes to parse, it's important to call this method.*/

- (void)finishParsing;


@end
