//
//  NNWSharingPluginOpenInBrowser.m
//  nnw
//
//  Created by Brent Simmons on 12/30/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWSharingPluginOpenInBrowser.h"


@interface NNWSharingCommandOpenInBrowser : NSObject <RSPluginCommand>

@end


#pragma mark -

@interface NNWSharingPluginOpenInBrowser ()

@property (nonatomic, strong, readwrite) NSArray *allCommands;
@end


@implementation NNWSharingPluginOpenInBrowser

@synthesize allCommands;


#pragma mark Dealloc



#pragma mark RSPlugin

- (BOOL)shouldRegister:(id<RSPluginManager>)pluginManager {
    self.allCommands = [NSArray arrayWithObject:[[NNWSharingCommandOpenInBrowser alloc] init]];
    return YES;
}


@end



#pragma mark -

@implementation NNWSharingCommandOpenInBrowser

#pragma mark Browser

static void replaceAmpersandEntities(NSMutableString *s) {
    /*This shouldn't be necessary, but feeds are often excessively encoded, so this hack-ish thing has to happen.*/
    [s replaceOccurrencesOfString:@"&amp;" withString:@"&" options:NSLiteralSearch range:NSMakeRange(0, [s length])];
    [s replaceOccurrencesOfString:@"&#38;" withString:@"&" options:NSLiteralSearch range:NSMakeRange(0, [s length])];
}


static NSString *prepareURLStringForBrowser(NSString *urlString) {
    NSMutableString *s = [urlString mutableCopy];
    CFStringTrimWhitespace((CFMutableStringRef)s);
    [s replaceOccurrencesOfString:@" " withString:@"%20" options:NSLiteralSearch range:NSMakeRange(0, [s length])];
    replaceAmpersandEntities(s);
    [s replaceOccurrencesOfString:@"^" withString:@"%5E" options:NSLiteralSearch range:NSMakeRange(0, [s length])];
    return s;
}


- (void)openURL:(NSURL *)url inBackground:(BOOL)inBackground {
    NSURL *massagedURL = [NSURL URLWithString:prepareURLStringForBrowser([url absoluteString])];
    if (massagedURL == nil)
        return;
    if (inBackground) {
        LSLaunchURLSpec urlSpec;        
        urlSpec.appURL = nil;    
        urlSpec.itemURLs = (__bridge CFArrayRef)[NSArray arrayWithObject:massagedURL];
        urlSpec.passThruParams = nil;
        urlSpec.launchFlags = kLSLaunchDontSwitch;
        urlSpec.asyncRefCon = nil;        
        LSOpenFromURLSpec(&urlSpec, nil);
    }
    else
        [[NSWorkspace sharedWorkspace] openURL:massagedURL];
    
}


#pragma mark RSPluginCommand

- (NSString *)commandID {
    return @"com.ranchero.NetNewsWire.plugin.sharing.OpenInBrowser";
}


- (NSString *)title {
    return NSLocalizedStringFromTable(@"Open in Browser", @"NNWSharingPluginOpenInBrowser", @"Command");
}


- (NSString *)shortTitle {
    return self.title;
}


- (NSArray *)commandTypes {
    return [NSArray arrayWithObject:[NSNumber numberWithInteger:RSPluginCommandTypeOpenInViewer]];
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
    [self openURL:url inBackground:[[NSUserDefaults standardUserDefaults] boolForKey:@"openInBrowserInBackground"]];
    
    [aPluginHelper noteUserDidShareItem:sharableItem viaServiceIdentifier:@"browser"];
    return YES;
}


@end
