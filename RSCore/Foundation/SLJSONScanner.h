//
//  SLJSONScanner.h
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 12/14/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol SLJSONScannerDelegate <NSObject>

@required

- (void)objectDidStart; //{
- (void)objectDidEnd; //}
- (void)arrayDidStart; //[
- (void)arrayDidEnd; //]
- (void)nameValueSeparatorFound; //:
- (void)valueSeparatorFound; //,
- (void)charactersFound:(unsigned char *)characters length:(NSUInteger)length; //names and values may come in chunks

@end



@interface SLJSONScanner : NSObject {
@private
	id<SLJSONScannerDelegate> delegate;
	unsigned char *jsonBytes;
	BOOL inNameOrValue;
	NSUInteger quoteLevel;
	NSUInteger numberOfJSONBytes;
	NSUInteger indexOfNameOrValueStart;
	BOOL lastCharacterWasEscape;
}


- (id)initWithDelegate:(id<SLJSONScannerDelegate>)aDelegate; //delegate is required

/*Keep calling.*/

- (BOOL)scanBytes:(unsigned char *)bytes length:(NSUInteger)length error:(NSError **)error;

@end
