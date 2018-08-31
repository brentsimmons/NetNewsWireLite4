//
//  NNWPreferencesFontsViewController.m
//  nnw
//
//  Created by Brent Simmons on 12/16/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWPreferencesFontsViewController.h"
#import "RSFontLabelView.h"


@interface NNWPreferencesFontsViewController ()

@property (nonatomic, strong, readwrite) NSToolbarItem *toolbarItem;
@property (nonatomic, assign) BOOL changingStandardFont;

- (void)updateFontLabels;
- (NSFont *)htmlStandardFont;
- (NSFont *)htmlFixedFont;
    
@end


@implementation NNWPreferencesFontsViewController

@synthesize toolbarItem;
@synthesize standardFontLabelView;
@synthesize fixedFontLabelView;
@synthesize changingStandardFont;


#pragma mark Init

- (id)init {
    self = [self initWithNibName:@"PreferencesFonts" bundle:nil];
    if (self == nil)
        return nil;
    toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:@"PreferencesFonts"];
    [toolbarItem setLabel:NSLocalizedStringFromTable(@"Fonts", @"PreferencesFonts", @"Toolbar item name")];
    [toolbarItem setImage:[NSImage imageNamed:NSImageNameFontPanel]];
    return self;
}


#pragma mark Dealloc



#pragma mark AwakeFromNib

- (void)awakeFromNib {
    [self updateFontLabels];
    [[self view] setNextResponder:self];
}


#pragma mark UI

- (void)updateFontLabels {
    [self.standardFontLabelView setChosenFont:[self htmlStandardFont]];
    [self.fixedFontLabelView setChosenFont:[self htmlFixedFont]];    
}


#pragma mark SLFullContentViewControllerPlugin

- (NSString *)windowTitle {
    return [self.toolbarItem label];
}


#pragma mark Fonts

- (int)minimumFontSize {
    return [[WebPreferences standardPreferences] minimumFontSize];
}


- (void)setMinimumFontSize:(int)aFontSize {
    [[WebPreferences standardPreferences] setMinimumFontSize:aFontSize];
}


- (NSFont *)defaultFont {
    NSFont *defaultFont = [NSFont fontWithName:@"Times" size:12.0f];
    if (defaultFont == nil)
        defaultFont = [NSFont userFontOfSize:12.0f];
    return defaultFont;
}


- (NSFont *)defaultFixedFont {
    NSFont *defaultFixedFont = [NSFont fontWithName:@"Courier" size:12.0f];
    if (defaultFixedFont == nil)
        defaultFixedFont = [NSFont userFixedPitchFontOfSize:12.0f];
    return defaultFixedFont;
}


- (NSFont *)htmlStandardFont {
    
    NSString *fontName = [[WebPreferences standardPreferences] standardFontFamily];
    int fontSize = [[WebPreferences standardPreferences] defaultFontSize];
    
    if (RSStringIsEmpty(fontName) || fontSize < 1)
        return [self defaultFont];
    
    NSFont *font = [NSFont fontWithName:fontName size:(CGFloat)fontSize];
    if (font == nil)
        return [self defaultFont];
    
    return font;    
}


- (NSFont *)htmlFixedFont {
    
    NSString *fontName = [[WebPreferences standardPreferences] fixedFontFamily];
    int fontSize = [[WebPreferences standardPreferences] defaultFixedFontSize];
    
    if (fontName == nil || fontSize < 1)
        return [self defaultFixedFont];
    
    NSFont *font = [NSFont fontWithName:fontName size:(CGFloat)fontSize];
    if (font == nil)
        return [self defaultFixedFont];
    return font;
}


- (void)changeHTMLStandardFontInPreferences:(WebPreferences *)webPrefs withFontManager:(NSFontManager *)fm {
    
    NSFont *currentFont = [fm convertFont:[fm selectedFont]];
    
    if (currentFont == nil || [currentFont isEqual:[self htmlStandardFont]])
        return;
    
    [webPrefs setDefaultFontSize:(int)[currentFont pointSize]];
    [webPrefs setStandardFontFamily:[currentFont familyName]];
    [webPrefs setSansSerifFontFamily:[currentFont familyName]];
    [webPrefs setSerifFontFamily:[currentFont familyName]];
    
    [self updateFontLabels];
}


- (void)changeHTMLFixedFontInPreferences:(WebPreferences *)webPrefs withFontManager:(NSFontManager *)fm {
    
    NSFont *currentFont = [fm convertFont:[fm selectedFont]];
    
    if (currentFont == nil || [currentFont isEqual:[self htmlFixedFont]])
        return;
    
    [webPrefs setDefaultFixedFontSize:(int)[currentFont pointSize]];
    [webPrefs setFixedFontFamily:[currentFont familyName]];

    [self updateFontLabels];
}


- (void)changeHTMLStandardFont:(id)sender {
    [self changeHTMLStandardFontInPreferences:[WebPreferences standardPreferences] withFontManager:sender];
}


- (void)changeHTMLFixedFont:(id)sender {
    [self changeHTMLFixedFontInPreferences:[WebPreferences standardPreferences] withFontManager:sender];
}


- (void)changeFont:(id)sender {
    if (self.changingStandardFont)
        [self changeHTMLStandardFont:sender];
    else
        [self changeHTMLFixedFont:sender];
}

#pragma mark Actions

//- (void)debug_printOutResponderChain:(id)sender {
//    NSLog(@"1st: %@", [[[self view] window] firstResponder]);
//    NSResponder *nomad = (NSResponder *)sender;
//    while (nomad != nil) {
//        NSLog(@"nomad: %@", nomad);
//        if (nomad == self)
//            NSLog(@"wooot!");
//        nomad = [nomad nextResponder];
//    }
//}


- (void)chooseHTMLStandardFont:(id)sender {
    [[[self view] window] makeFirstResponder:[self view]];
    self.changingStandardFont = YES;
//    [self debug_printOutResponderChain:sender];
    [[NSFontManager sharedFontManager] setSelectedFont:[self htmlStandardFont] isMultiple:NO];        
    [[NSFontManager sharedFontManager] orderFrontFontPanel:self];            
}


- (void)chooseHTMLFixedFont:(id)sender {
    [[[self view] window] makeFirstResponder:[self view]];
    self.changingStandardFont = NO;
//    [self debug_printOutResponderChain:sender];
    [[NSFontManager sharedFontManager] setSelectedFont:[self htmlFixedFont] isMultiple:NO];        
    [[NSFontManager sharedFontManager] orderFrontFontPanel:self];        
}


@end
