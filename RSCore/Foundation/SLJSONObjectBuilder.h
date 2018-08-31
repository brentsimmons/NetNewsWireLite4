//
//  SLJSONObjectBuilder.h
//  nnw
//
//  Created by Brent Simmons on 12/14/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SLJSONStreamingParser.h"


@interface SLJSONObjectBuilder : NSObject <SLJSONStreamingParserDelegate> {
@private
	SLJSONStreamingParser *jsonParser;
	id jsonTree;
	NSMutableArray *objectStack;
}


/*When you have an entire JSON document in memory, you can parse it with one call.*/

- (BOOL)parseJSONDocument:(NSData *)jsonDocument error:(NSError **)error;
- (BOOL)parseJSONDocumentString:(NSString *)jsonDocumentString error:(NSError **)error;

/*If you're getting the JSON document in chunks (over HTTP, for instance), pass each chunk.*/

- (BOOL)parseBytes:(const void *)bytes length:(NSUInteger)length error:(NSError **)error;

/*If parsing succeeds, get the built tree of objects.*/

@property (nonatomic, retain, readonly) id jsonTree;

@end


/*Just ignores everything. Used only for performance testing, to blank out the SLJSONObjectBuilder code.*/

@interface SLJSONIgnorer : NSObject <SLJSONStreamingParserDelegate> {	
@private
	SLJSONStreamingParser *jsonParser;
}

- (BOOL)parseJSONDocument:(NSData *)jsonDocument error:(NSError **)error;


@end