//
//  NNWFolder.m
//  nnwiphone
//
//  Created by Brent Simmons on 8/10/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWFolder.h"
#import "NNWAppDelegate.h"
#import "NNWDataController.h"
#import "RSParsedGoogleSub.h"


@implementation NNWFolder


#pragma mark Class Methods

+ (NSManagedObject *)folderWithGoogleDictionary:(RSParsedGoogleCategory *)category managedObjectContext:(NSManagedObjectContext *)moc {
	NSString *googleID = category.googleID;
	if (RSStringIsEmpty(googleID))
		return nil;
	NNWFolder *folder = (NNWFolder *)[[NNWDataController sharedController] objectWithUniqueGoogleID:googleID entityName:RSDataEntityFolder managedObjectContext:moc];
	NSString *label = [folder valueForKey:@"label"];
	if (RSStringIsEmpty(label)) {
		NSArray *stringComponents = [googleID componentsSeparatedByString:RSFeedSlash];
		label = [stringComponents lastObject];
		[folder setValue:label forKey:@"label"];
	}
	NSString *displayName = [folder valueForKey:RSDataTitle];
	if (RSStringIsEmpty(displayName)) {
		NSArray *stringComponents = [label componentsSeparatedByString:@" — "];
		displayName = [stringComponents lastObject];
		[folder setValue:displayName forKey:RSDataTitle];		
	}
	if (![folder valueForKey:@"level"]) {
		NSInteger level = [[label componentsSeparatedByString:@" — "] count] - 1;
		[folder setValue:[NSNumber numberWithInteger:level] forKey:@"level"];
	}
	return folder;
}


+ (void)ensureParent:(NNWFolder *)folder managedObjectContext:(NSManagedObjectContext *)moc {
	/*Recursive, of course -- ensures grandparents, etc.*/
	NSString *googleID = [folder valueForKey:RSDataGoogleID];
	NSArray *stringComponents = [googleID componentsSeparatedByString:@" — "];
	NSInteger level = [stringComponents count] - 1;
	if (level < 1)
		return;
	NSMutableArray *newStringComponents = [NSMutableArray arrayWithArray:stringComponents];
	[newStringComponents removeLastObject];
	NSString *newGoogleID = [newStringComponents componentsJoinedByString:@" — "];
	RSParsedGoogleCategory *newGoogleCategory = [[[RSParsedGoogleCategory alloc] init] autorelease];
	newGoogleCategory.googleID = newGoogleID;
	NSManagedObject *newFolder = [self folderWithGoogleDictionary:newGoogleCategory managedObjectContext:moc];
	[self ensureParent:(NNWFolder *)newFolder managedObjectContext:moc];
}


@end
