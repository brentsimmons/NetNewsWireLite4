//
//  NNWSendToAppCommand.m
//  nnw
//
//  Created by Brent Simmons on 1/3/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWPluginCommandSendToApp.h"
#import "RSFileUtilities.h"


@implementation NNWSendToAppSpecifier 

@synthesize URLSchemeTemplate;
@synthesize appBundleID;
@synthesize appExistsOnDisk;
@synthesize appName;
@synthesize appPath;
@synthesize usesAPI;
@synthesize usesURLScheme;


NSString *NNWSendToAppBundleIDKey = @"BundleID";
static NSString *NNWSendToAppURLTemplateKey = @"URLTemplate";

- (id)initWithAppName:(NSString *)anAppName configInfo:(id)configInfo {
	
	self = [super init];
	if (self == nil)
		return nil;
	
	if ([anAppName hasSuffix:@".app"])
		anAppName = [anAppName stringByDeletingPathExtension];
	appName = [anAppName retain];

	if ([configInfo isKindOfClass:[NSString class]]) {
		appBundleID = [configInfo retain];
		usesAPI = YES;
	}
	
	else if ([configInfo isKindOfClass:[NSDictionary class]]) {
		appBundleID = [[configInfo objectForKey:NNWSendToAppBundleIDKey] retain];
		URLSchemeTemplate = [[configInfo objectForKey:NNWSendToAppURLTemplateKey] retain];
		if (URLSchemeTemplate != nil)
			usesURLScheme = YES;
	}
	
	NSString *path = nil;
	if (appBundleID != nil)
		path = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:appBundleID];
	if (path == nil)
		path = [[NSWorkspace sharedWorkspace] fullPathForApplication:appName];
	appPath = [path retain];
	if (appPath != nil)
		appExistsOnDisk = YES;
	
	return self;
}


#pragma mark Dealloc
			   
- (void)dealloc {
	[URLSchemeTemplate release];
	[appBundleID release];
	[appName release];
	[appPath release];
	[icon release];
	[super dealloc];
}


#pragma mark Icon

- (NSImage *)icon {
	if (icon != nil)
		return icon;
	if (self.appPath == nil)
		return nil;
	icon = [[[NSWorkspace sharedWorkspace] iconForFile:self.appPath] retain];
	return icon;
}

			   
@end


#pragma mark -


@interface NNWPluginCommandSendToApp ()

@property (nonatomic, retain) NNWSendToAppSpecifier *sendToAppSpecifier;
@property (nonatomic, retain) id<RSSharableItem> sharableItem;

@end


@implementation NNWPluginCommandSendToApp

@synthesize sendToAppSpecifier;
@synthesize sharableItem;

#pragma mark Init

- (id)initWithAppSpecifier:(NNWSendToAppSpecifier *)aSendToAppSpecifier {
	self = [super init];
	if (self == nil)
		return nil;
	sendToAppSpecifier = [aSendToAppSpecifier retain];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[sendToAppSpecifier release];
	[sharableItem release];
	[super dealloc];
}


#pragma mark Send via Weblog Editor Interface Apple event


static NSAppleEventDescriptor *targetDescriptorForRunningAppAtPath(NSString *appPath) {
	/*Could be broken out into NSAppleEventDescriptor category, but it's used only here, so it's better off here.*/
	NSString *appName = RSFileDisplayNameAtPath(appPath, YES);
	NSString *appNameWithAppSuffix = [NSString stringWithFormat:@"%@%@", appName, @".app"];
	ProcessSerialNumber psn = {0, kNoProcess};
	BOOL foundPSN = NO;	
	while (true) {
		OSErr err = GetNextProcess(&psn);
		if (err != noErr)
			break;
		NSDictionary *infoDict = [(NSDictionary *)ProcessInformationCopyDictionary(&psn, (UInt32)kProcessDictionaryIncludeAllInformationMask) autorelease];
		NSString *oneAppPath = [infoDict objectForKey:@"BundlePath"];
		if (RSIsEmpty(oneAppPath))
			continue;
		NSString *oneAppName = [oneAppPath lastPathComponent];
		if ((appName && [appName isEqualToString:oneAppName]) || (appNameWithAppSuffix && [appNameWithAppSuffix isEqualToString:oneAppName])) {
			foundPSN = YES;
			break;
		}
	}	
	if (foundPSN)
		return [[[NSAppleEventDescriptor alloc] initWithDescriptorType:typeProcessSerialNumber data:[NSData dataWithBytes:&psn length:sizeof(ProcessSerialNumber)]] autorelease];	
	return [NSAppleEventDescriptor descriptorWithDescriptorType:typeFileURL data:[[[NSURL fileURLWithPath:appPath] absoluteString] dataUsingEncoding:NSUTF8StringEncoding]];
}


static NSAppleEventDescriptor *descriptorWithStringIfNotNil(NSString *value) {
	if (value == nil)
		return nil;
	return [NSAppleEventDescriptor descriptorWithString:value];
}


static void addStringDescriptorToRecordDescriptorIfNotNil(NSAppleEventDescriptor *recordDescriptor, NSString *value, AEKeyword keyword) {
	NSAppleEventDescriptor *stringDescriptor = descriptorWithStringIfNotNil(value);
	if (stringDescriptor != nil)
		[recordDescriptor setDescriptor:stringDescriptor forKeyword:keyword];
}


static const AEKeyword kWeblogEditorAPITitle = 'titl';
static const AEKeyword kWeblogEditorAPIDescription = 'desc';
static const AEKeyword kWeblogEditorAPILink = 'link';
static const AEKeyword kWeblogEditorAPIPermalink = 'link';
static const AEKeyword kWeblogEditorAPIFeedName = 'snam';
static const AEKeyword kWeblogEditorAPIFeedHomePageURL = 'hurl';
static const AEKeyword kWeblogEditorAPIFeedURL = 'furl';


- (NSAppleEventDescriptor *)recordDescriptor {

	NSAppleEventDescriptor *recordDescriptor = [NSAppleEventDescriptor recordDescriptor];
	
	addStringDescriptorToRecordDescriptorIfNotNil(recordDescriptor, self.sharableItem.title, kWeblogEditorAPITitle);
	addStringDescriptorToRecordDescriptorIfNotNil(recordDescriptor, self.sharableItem.htmlText, kWeblogEditorAPIDescription);
	addStringDescriptorToRecordDescriptorIfNotNil(recordDescriptor, [self.sharableItem.URL absoluteString], kWeblogEditorAPILink);
	addStringDescriptorToRecordDescriptorIfNotNil(recordDescriptor, [self.sharableItem.permalink absoluteString], kWeblogEditorAPIPermalink);
	
	addStringDescriptorToRecordDescriptorIfNotNil(recordDescriptor, self.sharableItem.feed.name, kWeblogEditorAPIFeedName);
	addStringDescriptorToRecordDescriptorIfNotNil(recordDescriptor, [self.sharableItem.feed.homePageURL absoluteString], kWeblogEditorAPIFeedHomePageURL);
	addStringDescriptorToRecordDescriptorIfNotNil(recordDescriptor, [self.sharableItem.feed.URL absoluteString], kWeblogEditorAPIFeedURL);
	
	return recordDescriptor;	
}


- (BOOL)sendUsingAPICall {

//	NSAppleEventDescriptor *targetDescriptor = nil;
//	NSString *bundleID = self.sendToAppSpecifier.appBundleID;
//	if (bundleID != nil)
//		targetDescriptor = [NSAppleEventDescriptor descriptorWithDescriptorType:typeApplicationBundleID data:[bundleID dataUsingEncoding:NSUTF8StringEncoding]];
//	if (targetDescriptor == nil && self.sendToAppSpecifier.appPath != nil)
//		targetDescriptor = [NSAppleEventDescriptor descriptorWithDescriptorType:typeFileURL data:[[[NSURL fileURLWithPath:self.sendToAppSpecifier.appPath] absoluteString] dataUsingEncoding:NSUTF8StringEncoding]];
//	if (targetDescriptor == nil)
//		return NO;

	if (RSLaunchAppWithPathSync(self.sendToAppSpecifier.appPath) != noErr)
		return NO;

	NSAppleEventDescriptor *targetDescriptor = targetDescriptorForRunningAppAtPath(self.sendToAppSpecifier.appPath);
	if (!targetDescriptor)
		return NO;	

	NSAppleEventDescriptor *appleEvent = [NSAppleEventDescriptor appleEventWithEventClass:'EBlg' eventID:'oitm' targetDescriptor:targetDescriptor returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];	
	[appleEvent setParamDescriptor:[self recordDescriptor] forKeyword:keyDirectObject];
	
	return AESendMessage((const AppleEvent *)[appleEvent aeDesc], NULL, kAENoReply | kAECanSwitchLayer | kAEAlwaysInteract, kAEDefaultTimeout) == noErr;
}


#pragma mark Send via URL Scheme

static NSString *stringWithURLEncoding(NSString *urlStringToEncode) {
	CFStringRef encodedString = CFURLCreateStringByAddingPercentEscapes(nil, (CFStringRef)urlStringToEncode, nil, CFSTR("`*^[]{}%=&/:+?#$,;<>@!'\" "), kCFStringEncodingUTF8);
	return (__bridge_transfer NSString *)encodedString;
}


- (BOOL)sendUsingURLScheme {
	
	NSURL *url = sharableItem.permalink; //for articles in feeds, most people expect the permalink, so use that if available
	if (url == nil)
		url = sharableItem.URL;
	NSString *encodedURLString = stringWithURLEncoding([url absoluteString]);
	
	NSMutableString *urlStringToSend = [[self.sendToAppSpecifier.URLSchemeTemplate mutableCopy] autorelease];
	[urlStringToSend replaceOccurrencesOfString:@"[[url]]" withString:encodedURLString options:NSLiteralSearch range:NSMakeRange(0, [urlStringToSend length])];
	
	NSString *itemTitle = sharableItem.title;
	if (itemTitle == nil)
		itemTitle = @"";
	NSString *encodedTitle = stringWithURLEncoding(itemTitle);
	[urlStringToSend replaceOccurrencesOfString:@"[[title]]" withString:encodedTitle options:NSLiteralSearch range:NSMakeRange(0, [urlStringToSend length])];

	NSURL *urlToSend = [NSURL URLWithString:urlStringToSend];
	if (urlToSend == nil)
		return NO;
	if (RSLaunchAppWithPathSync(self.sendToAppSpecifier.appPath) != noErr)
		return NO;
	
	return [[NSWorkspace sharedWorkspace] openURLs:[NSArray arrayWithObject:urlToSend] withAppBundleIdentifier:self.sendToAppSpecifier.appBundleID options:0 additionalEventParamDescriptor:nil launchIdentifiers:NULL];
	//return [[NSWorkspace sharedWorkspace] openURL:urlToSend];	
}


#pragma mark Sending

- (BOOL)sendSharableItem {
	
	if (self.sendToAppSpecifier.usesAPI)
		return [self sendUsingAPICall];	
	else if (self.sendToAppSpecifier.usesURLScheme)
		return [self sendUsingURLScheme];
	
	return NO;
}


#pragma mark RSPluginCommand

- (NSString *)commandID {
	return [NSString stringWithFormat:@"com.ranchero.NetNewsWire.plugin.sharing.SendToApp.%@", self.sendToAppSpecifier.appName];
}


- (NSString *)title {
	return [NSString stringWithFormat:NSLocalizedStringFromTable(@"Send to %@", @"NNWPluginComandSendToApp", @"Command"), self.sendToAppSpecifier.appName];
}


- (NSString *)shortTitle {
	return self.sendToAppSpecifier.appName;
}


- (NSImage *)image {
	return self.sendToAppSpecifier.icon;
}


- (NSArray *)commandTypes {
	return [NSArray arrayWithObject:[NSNumber numberWithInteger:RSPluginCommandTypeSharing]];
}


- (BOOL)validateCommandWithArray:(NSArray *)items {
	
	if (items == nil || [items count] != 1)
		return NO;
	id<RSSharableItem> aSharableItem = [items objectAtIndex:0];
	return aSharableItem.URL != nil || aSharableItem.permalink != nil;
}


- (BOOL)performCommandWithArray:(NSArray *)items userInterfaceContext:(id<RSUserInterfaceContext>)userInterfaceContext pluginHelper:(id<RSPluginHelper>)aPluginHelper error:(NSError **)error {
	
	self.sharableItem = [items objectAtIndex:0];
	BOOL didSendItem = [self sendSharableItem];
	self.sharableItem = nil;

	if (didSendItem) {
		NSString *serviceIdentifier = sendToAppSpecifier.appName;
		if (serviceIdentifier == nil)
			serviceIdentifier = sendToAppSpecifier.appBundleID;	
		[aPluginHelper noteUserDidShareItem:sharableItem viaServiceIdentifier:serviceIdentifier];
	}
	
	return didSendItem;
}


@end
