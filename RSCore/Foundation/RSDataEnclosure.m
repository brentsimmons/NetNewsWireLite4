//
//  NNWEnclosure.m
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 8/8/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSDataEnclosure.h"
#import "RSParsedEnclosure.h"
#import "RSDataManagedObjects.h"


@implementation RSDataEnclosure

@dynamic bitRate;
@dynamic fileSize;
@dynamic height;
@dynamic mediaType;
@dynamic medium;
@dynamic mimeType;
@dynamic URL;
@dynamic width;

@dynamic articles;


static NSString *NNWEnclosureEntityName = @"Enclosure";

+ (RSDataEnclosure *)createEnclosureWithURL:(NSString *)enclosureURL moc:(NSManagedObjectContext *)moc {
	RSDataEnclosure *createdEnclosure = (RSDataEnclosure *)[NSEntityDescription insertNewObjectForEntityForName:NNWEnclosureEntityName inManagedObjectContext:moc];
	createdEnclosure.URL = enclosureURL;
	return createdEnclosure;
}


+ (NSSet *)enclosuresWithArrayOfParsedEnclosures:(NSArray *)parsedEnclosures moc:(NSManagedObjectContext *)moc {
	NSMutableSet *enclosures = [NSMutableSet setWithCapacity:[parsedEnclosures count]];
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	for (RSParsedEnclosure *oneParsedEnclosure in parsedEnclosures) {
		NSString *url = oneParsedEnclosure.urlString;
		if (RSStringIsEmpty(url))
			continue;
		RSDataEnclosure *createdEnclosure = [self createEnclosureWithURL:url moc:moc];
		if (createdEnclosure == nil)
			continue;
		if (oneParsedEnclosure.bitrate > 0)
			createdEnclosure.bitRate = [NSNumber numberWithInteger:oneParsedEnclosure.bitrate];
		if (oneParsedEnclosure.fileSize > 0)
			createdEnclosure.fileSize = [NSNumber numberWithInteger:oneParsedEnclosure.fileSize];
		if (oneParsedEnclosure.height > 0)
			createdEnclosure.height = [NSNumber numberWithInteger:oneParsedEnclosure.height];
		if (oneParsedEnclosure.mediaType != RSMediaTypeUnknown)
			createdEnclosure.mediaType = [NSNumber numberWithInteger:oneParsedEnclosure.mediaType];
		if (!RSStringIsEmpty(oneParsedEnclosure.medium))
			createdEnclosure.medium = oneParsedEnclosure.medium;
		if (!RSStringIsEmpty(oneParsedEnclosure.mimeType))
			createdEnclosure.mimeType = oneParsedEnclosure.mimeType;
		if (oneParsedEnclosure.width > 0)
			createdEnclosure.width = [NSNumber numberWithInteger:oneParsedEnclosure.width];
		[enclosures addObject:createdEnclosure];
	}
	[pool drain];
	return enclosures;
}


@end
