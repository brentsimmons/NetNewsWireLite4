//
//  NNWSharingPluginSendViaEmail.m
//  nnw
//
//  Created by Brent Simmons on 1/4/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWSharingPluginSendViaEmail.h"


@interface NNWSharingCommandEmailLink : NSObject <RSPluginCommand>
@end


#pragma mark -

@interface NNWSharingPluginSendViaEmail ()

@property (nonatomic, retain, readwrite) NSArray *allCommands;
@end


@implementation NNWSharingPluginSendViaEmail

@synthesize allCommands;

#pragma mark Dealloc

- (void)dealloc {
	[allCommands release];
	[super dealloc];
}


#pragma mark RSPlugin

- (BOOL)shouldRegister:(id<RSPluginManager>)pluginManager {
	self.allCommands = [NSArray arrayWithObject:[[[NNWSharingCommandEmailLink alloc] init] autorelease]];
	return YES;
}


@end


#pragma mark -

@implementation NNWSharingCommandEmailLink


#pragma mark Sending

- (BOOL)openEmailMessageWithTitle:(NSString *)aTitle titleTemplate:(NSString *)titleTemplate URL:(NSURL *)aURL bodyTemplate:(NSString *)bodyTemplate {
	
	NSMutableString *subjectForEmail = [NSMutableString stringWithString:titleTemplate];
	[subjectForEmail replaceOccurrencesOfString:@"[[title]]" withString:aTitle options:NSCaseInsensitiveSearch range:NSMakeRange(0, [titleTemplate length])];
	
	NSMutableString *bodyForEmail = [NSMutableString stringWithString:bodyTemplate];
	[bodyForEmail replaceOccurrencesOfString:@"[[url]]" withString:[aURL absoluteString] options:NSCaseInsensitiveSearch range:NSMakeRange(0, [bodyForEmail length])];
	
	return [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:RSStringMailToLinkWithTitleAndBody(subjectForEmail, bodyForEmail)]];	
}


- (NSString *)contentsOfEmailTemplateWithFolder:(NSString *)folder filename:(NSString *)filename {
	NSString *pathToEmailTemplate = [folder stringByAppendingPathComponent:filename];
	if (![[NSFileManager defaultManager] fileExistsAtPath:pathToEmailTemplate])
		return nil;
	NSStringEncoding encoding = NSUTF8StringEncoding;
	return [NSString stringWithContentsOfFile:pathToEmailTemplate usedEncoding:&encoding error:nil];
} 


#pragma mark RSPluginCommand

- (NSString *)commandID {
	return @"com.ranchero.NetNewsWire.plugin.sharing.SendViaEmail";
}


- (NSString *)title {
	return NSLocalizedStringFromTable(@"Mail Link", @"NNWSharingPluginSendViaEmail", @"Command");
}


- (NSString *)shortTitle {
	return self.title;
}


- (NSImage *)image {
	return [NSImage imageNamed:@"GEnvelopeTemplate"];
}


- (NSArray *)commandTypes {
	return [NSArray arrayWithObject:[NSNumber numberWithInteger:RSPluginCommandTypeSharing]];
}


- (BOOL)validateCommandWithArray:(NSArray *)items {
	
	/*Conceivably we could handle more than one item. But then we'd need to ask the user if they're sure
	 when the number is above something like 5 or 10. So we'll leave that as a feature request.*/
	
	if (items == nil || [items count] != 1)
		return NO;
	id<RSSharableItem> aSharableItem = [items objectAtIndex:0];
	return aSharableItem.URL != nil || aSharableItem.permalink != nil;
}


- (BOOL)performCommandWithArray:(NSArray *)items userInterfaceContext:(id<RSUserInterfaceContext>)userInterfaceContext pluginHelper:(id<RSPluginHelper>)aPluginHelper error:(NSError **)error {
	
	id<RSSharableItem> sharableItem = [items objectAtIndex:0];
	
	NSURL *url = sharableItem.permalink; //for articles in feeds, most people expect the permalink, so use that if available
	if (url == nil)
		url = sharableItem.URL;
	NSString *aTitle = sharableItem.title;
	if (aTitle == nil)
		aTitle = NSLocalizedStringFromTable(@"Cool Link!", @"NNWSharingPluginSendViaEmail", @"Default subject line for email");
	
	NSString *templatesFolder = [aPluginHelper.pathToDataFolder stringByAppendingPathComponent:@"Templates"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:templatesFolder]) {
		if (![[NSFileManager defaultManager] createDirectoryAtPath:templatesFolder withIntermediateDirectories:NO attributes:nil error:error])
			return NO;
	}
	
	NSString *titleTemplate = @"[[title]]";
	NSString *userTitleTemplate = [self contentsOfEmailTemplateWithFolder:templatesFolder filename:@"EmailLinkTitleTemplate"];
	if (userTitleTemplate != nil)
		titleTemplate = userTitleTemplate;
	
	NSString *bodyTemplate = @"[[url]]\n\nLink found via NetNewsWire for Macintosh: http://netnewswireapp.com/";
	NSString *userBodyTemplate = [self contentsOfEmailTemplateWithFolder:templatesFolder filename:@"EmailLinkBodyTemplate"];
	if (userBodyTemplate != nil)
		bodyTemplate = userBodyTemplate;

	return [self openEmailMessageWithTitle:aTitle titleTemplate:titleTemplate URL:url bodyTemplate:bodyTemplate];
}


@end

