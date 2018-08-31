//
//  NGAnimatedBarButtonItem.h
//  AnimatedButtonTwo
//
//  Created by Nicholas Harris on 3/1/10.
//  Copyright 2010 Sirrahsoft LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NGAnimatedBarButtonItem : UIBarButtonItem {
	UIButton *button;
	NSArray *offToOnImages;
	NSArray *onToOffImages;
	UIImage *offImage;
	UIImage *onImage;
	CGFloat animationDuration;
	
	bool isOn;
	
	id target;
	SEL selector;
}

-(id) initWithImages:(NSArray*)images duration:(CGFloat)duration target:(id)aTarget selector:(SEL)aSelector;

@property (nonatomic, assign) BOOL on;

@end
