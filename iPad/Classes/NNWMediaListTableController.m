//
//  NNWMediaListTableController.m
//  nnwipad
//
//  Created by Brent Simmons on 2/18/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWMediaListTableController.h"


@implementation NNWMediaListTableController

@synthesize tableView;

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv {
	return 1;
}


- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section {
	return 1;
}


NSString *NNWMediaListCellIdentifier = @"MediaListCell";

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
 	//NSInteger section = indexPath.section;
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NNWMediaListCellIdentifier];
	if (!cell)
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NNWMediaListCellIdentifier] autorelease];
    
	//	NSInteger row = indexPath.row;
	cell.textLabel.text = @"Media";
    return cell;
}


- (NSInteger)tableView:(UITableView *)tv indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 0;
}


- (void)handleDidSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSLog(@"Selected: %@", indexPath);
}


- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self performSelectorOnMainThread:@selector(handleDidSelectRowAtIndexPath:) withObject:indexPath waitUntilDone:NO];
}


- (BOOL)tableView:(UITableView *)tv canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}


@end
