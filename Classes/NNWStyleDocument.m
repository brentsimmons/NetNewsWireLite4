/*
    NNWStyleDocument.m
    NetNewsWire

    Created by Brent Simmons on 1/30/05.
    Copyright 2005 Ranchero Software. All rights reserved.
*/


#import "NNWStyleDocument.h"
#import "NNWStyleSheetController.h"
#import "RSWebBrowser.h"


NSString *NNWStyleDocumentInfoPlist = @"Info.plist";
NSString *NNWStyleDocumentCreatorName = @"CreatorName";
NSString *NNWStyleDocumentCreatorHomePage = @"CreatorHomePage";


@interface NNWStyleDocument ()

@property (nonatomic, assign) BOOL isInstalled;
@property (nonatomic, assign) BOOL styleWithSameNameIsInstalled;
@property (nonatomic, strong) NSString *authorName;
@property (nonatomic, strong) NSString *authorWebsiteURL;
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) NSString *message;
@property (nonatomic, strong) NSString *title;

- (void)updateUI;
- (void)installStyleNow;
- (void)runConfirmationSheet;

@end


@implementation NNWStyleDocument

@synthesize authorName;
@synthesize authorWebsiteButton;
@synthesize authorWebsiteURL;
@synthesize filePath;
@synthesize isInstalled;
@synthesize mainWindow;
@synthesize message;
@synthesize styleWithSameNameIsInstalled;
@synthesize title;

#pragma mark Dealloc



#pragma mark NSDocument Overrides

- (NSString *)windowNibName {
    return @"StyleDocument";
}


- (void)windowControllerDidLoadNib:(NSWindowController *)windowController {
    [self updateUI];
}


- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)type {
    self.filePath = fileName;
    return YES;
}


- (NSString *)displayName {
    NSString *s = [[self.filePath lastPathComponent] stringByDeletingPathExtension];
    return RSIsEmpty(s) ? NSLocalizedString(@"Unknown", @"Generic") : s;
}


#pragma mark Actions

- (IBAction)openAuthorWebsite:(id)sender {
    RSWebBrowserOpenURLInFront(self.authorWebsiteURL);
}


- (IBAction)installStyle:(id)sender {
    if (self.isInstalled)
        return;
    if (self.styleWithSameNameIsInstalled)
        [self runConfirmationSheet];
    else
        [self installStyleNow];
}


- (IBAction)cancelStyleWindow:(id)sender {
    [self performSelectorOnMainThread:@selector(close) withObject:nil waitUntilDone:NO];
}

    
#pragma mark Installing

- (void)didInstallInfoSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {    
    [self performSelectorOnMainThread:@selector(close) withObject:nil waitUntilDone:NO];
}


- (void)runDidInstallInfoSheet {
    NSBeginInformationalAlertSheet (NSLocalizedStringFromTable(@"Style Installed", @"StyleDocument", @"Style document window"), NSLocalizedString(@"OK", @"OK button for dialogs and sheets"), nil, nil, self.mainWindow, self, @selector(didInstallInfoSheetDidEnd:returnCode:contextInfo:), nil, nil, [NSString stringWithFormat:NSLocalizedStringFromTable(@"The style “%@” has been installed.", @"StyleDocument", @"Style document window"), self.displayName]);    
}


- (void)runInstallErrorSheet {
    NSString *errorTitle = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Can’t install “%@” because “%@.”", @"StyleDocument", @"Style document window"), self.displayName, [NNWStyleSheetController sharedController].installError];
    NSBeginCriticalAlertSheet(errorTitle, NSLocalizedString(@"OK", @"OK button for dialogs and sheets"), nil, nil, self.mainWindow, self, nil, nil, nil, [NSString stringWithFormat:NSLocalizedStringFromTable(@"The style “%@” has not been installed.", @"StyleDocument", @"Style document window"), self.displayName]);    
}


- (void)installStyleNow {
    BOOL success = [[NNWStyleSheetController sharedController] installStyleDocument:self.filePath];
    if (success)
        [self performSelectorOnMainThread:@selector(runDidInstallInfoSheet) withObject:nil waitUntilDone:NO];
    else
        [self performSelectorOnMainThread:@selector(runInstallErrorSheet) withObject:nil waitUntilDone:NO];
}


- (void)installSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {    
    if (returnCode == NSAlertDefaultReturn)
        [self installStyleNow];
}


- (void)runConfirmationSheet {
    NSString *confirmationTitle = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Are you sure you want to install \\U201C%@\\U201D?", @"StyleDocument", @"Style document window"), self.displayName];    
    NSBeginAlertSheet(confirmationTitle, NSLocalizedStringFromTable(@"Install", @"StyleDocument", @"Style document window"), NSLocalizedString(@"Cancel", @"Cancel button for dialogs and sheets"), nil, self.mainWindow, self, @selector(installSheetDidEnd:returnCode:contextInfo:), nil, nil, NSLocalizedStringFromTable(@"This will over-write your current version of this style.", @"StyleDocument", @"Style document window"));
}

    
#pragma mark Reading Stylesheet Data

- (NSString *)pathToInfoPlist {    
    return [self.filePath stringByAppendingPathComponent:NNWStyleDocumentInfoPlist];
}


- (void)readDataFromInfoPlist {    
    NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:self.pathToInfoPlist];
    self.authorName = [d objectForKey:NNWStyleDocumentCreatorName];
    self.authorWebsiteURL = [d objectForKey:NNWStyleDocumentCreatorHomePage];
}


- (void)checkIfInstalled {        
    self.isInstalled = [[NNWStyleSheetController sharedController] styleIsInstalled:self.filePath];
    self.styleWithSameNameIsInstalled = [[NNWStyleSheetController sharedController] styleWithSameNameIsInstalled:self.filePath];
}

    
#pragma mark UI

- (void)updateTitle {
    
    NSString *displayName = [[self.filePath lastPathComponent] stringByDeletingPathExtension];
    if (displayName == nil)
        return;
    NSString *displayAuthorName = self.authorName;
    if (RSStringIsEmpty(displayAuthorName))
        displayAuthorName = NSLocalizedStringFromTable(@"Unknown Author", @"StyleDocument", @"Style document window");
    
    NSString *s = [NSString stringWithFormat:NSLocalizedStringFromTable(@"“%@” by %@", @"StyleDocument", @"Style document window"), displayName, displayAuthorName];
    self.title = s;
}


- (void)updateAuthorWebsiteButton {
    
    if (RSIsEmpty(self.authorWebsiteURL)) {
        [authorWebsiteButton setTitle:NSLocalizedStringFromTable(@"Unknown URL", @"StyleDocument", @"Style document window")];
        [authorWebsiteButton setEnabled:NO];
        return;
    }
    
    [authorWebsiteButton setAttributedTitle:[NSAttributedString rs_truncatedBlueUnderlinedString:self.authorWebsiteURL withFont:[NSFont systemFontOfSize:11.0]]];
    [authorWebsiteButton setAttributedAlternateTitle:[NSAttributedString rs_truncatedRedUnderlinedString:self.authorWebsiteURL withFont: [NSFont systemFontOfSize: 11.0]]];
}


- (void)updateMessage {    
    if (self.isInstalled)
        self.message = NSLocalizedStringFromTable(@"This style is already installed.", @"StyleDocument", @"Style document window");
    else if (self.styleWithSameNameIsInstalled)
        self.message = NSLocalizedStringFromTable(@"A style with this name is already installed.", @"StyleDocument", @"Style document window");
    else
        self.message = NSLocalizedStringFromTable(@"This style has not been installed.", @"StyleDocument", @"Style document window");
}


- (void)updateUI {
    [self readDataFromInfoPlist];
    [self checkIfInstalled];
    [self updateTitle];
    [self updateAuthorWebsiteButton];
    [self updateMessage];
}

    
@end
