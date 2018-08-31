//
//  NNWArticleTheme.m
//  nnw
//
//  Created by Brent Simmons on 12/19/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWArticleTheme.h"
#import "RSFileUtilities.h"


@interface NNWArticleTheme ()

@property (nonatomic, retain, readwrite) NSString *folderPath;
@property (nonatomic, retain, readwrite) NSString *nameForDisplay;
@property (nonatomic, retain, readwrite) NSString *cssFilePath;
@property (nonatomic, retain, readwrite) NSString *emptyCSSFilePath;
@property (nonatomic, assign, readwrite) BOOL shouldScrollFullPage;

- (BOOL)determineIfShouldScrollFullPage;

@end


@implementation NNWArticleTheme

@synthesize shouldScrollFullPage;
@synthesize cssFilePath;
@synthesize emptyCSSFilePath;
@synthesize folderPath;
@synthesize htmlTemplate;
@synthesize nameForDisplay;


#pragma mark Init

- (id)initWithFolderPath:(NSString *)aFolderPath {
	self = [super init];
	if (self == nil)
		return self;
	folderPath = [aFolderPath retain];
	nameForDisplay = [[[folderPath lastPathComponent] stringByDeletingPathExtension] retain];
	cssFilePath = [[folderPath stringByAppendingPathComponent:@"stylesheet.css"] retain];
	NSString *anEmptyCSSFilePath = [folderPath stringByAppendingPathComponent:@"stylesheet_empty.css"];
	if (RSFileExists(anEmptyCSSFilePath))
		emptyCSSFilePath = [anEmptyCSSFilePath retain];
	else
		emptyCSSFilePath = [cssFilePath copy];
	shouldScrollFullPage = [self determineIfShouldScrollFullPage];
	return self;						   
}


#pragma mark Dealloc

- (void)dealloc {
	[nameForDisplay release];
	[htmlTemplate release];
	[folderPath release];
	[cssFilePath release];
	[emptyCSSFilePath release];
	[super dealloc];
}


#pragma mark Accessors

- (NSString *)htmlTemplate {
	if (htmlTemplate != nil)
		return htmlTemplate;
	
	NSString *templatePath = [self.folderPath stringByAppendingPathComponent:@"template.html"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:templatePath])
		return nil;
	
	NSString *templateString = [NSString rs_stringWithContentsOfUTF8EncodedFile:templatePath];
	if (RSStringIsEmpty(templateString))
		return nil;

	htmlTemplate = [templateString copy];
	return htmlTemplate;
}


#pragma mark Scrolling

- (BOOL)determineIfShouldScrollFullPage {
	/*Themes that have fixed elements should not scroll a full page.
	 This is a special case for a bunch of previously built-in themes.
	 There isn't another way I can find to work around this.*/
	NSString *s = self.nameForDisplay;
	if (RSIsEmpty(s))
		return YES;
	if ([s rs_caseInsensitiveContains:@"floating"])
		return YES;
	if ([s rs_caseInsensitiveContains:@"bd aqua"] || [s rs_caseInsensitiveContains:@"bd graphite"] || [s rs_caseInsensitiveContains:@"daring status"] || [s rs_caseInsensitiveContains:@"daring gradient"] || [s rs_caseInsensitiveContains:@"autumn"] || [s rs_caseInsensitiveContains:@"dashed+"] || [s rs_caseInsensitiveContains:@"red news"] || [s rs_caseInsensitiveContains:@"feedlight"])
		return NO;
	return YES;
}


@end
