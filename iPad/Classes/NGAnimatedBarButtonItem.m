//
//  NGAnimatedBarButtonItem.m
//  AnimatedButtonTwo
//
//  Created by Nicholas Harris on 3/1/10.
//  Copyright 2010 Sirrahsoft LLC. All rights reserved.
//

#import <QuartzCore/CAAnimation.h>
#import "NGAnimatedBarButtonItem.h"


@implementation NGAnimatedBarButtonItem

-(id) initWithImages:(NSArray*)images duration:(CGFloat)duration target:(id)aTarget selector:(SEL)aSelector
{
	isOn = NO;
	offImage = [[images objectAtIndex:0]retain];
	onImage = [[images objectAtIndex:images.count-1]retain];
	animationDuration = duration;
	
	NSMutableArray *mutableOffToOnImages = [NSMutableArray arrayWithCapacity:images.count];
	NSMutableArray *mutableOnToOffImages = [NSMutableArray arrayWithCapacity:images.count];
	
	for(int i=0; i<images.count; i++)
	{
		UIImage *img = [images objectAtIndex:i];
		[mutableOffToOnImages addObject:(id)[img CGImage]];
		[mutableOnToOffImages insertObject:(id)[img CGImage] atIndex:0];
	}
	offToOnImages = [[NSArray arrayWithArray:mutableOffToOnImages]retain];
	onToOffImages = [[NSArray arrayWithArray:mutableOnToOffImages]retain];
	
	button = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, offImage.size.width, offImage.size.height)];
	[button addTarget:self action:@selector(handleButtonTouch) forControlEvents:UIControlEventTouchUpInside];	
	[button layer].contents = (id)[offImage CGImage];
	button.adjustsImageWhenDisabled = NO;
	button.adjustsImageWhenHighlighted = NO;
	
	target = aTarget;
	selector = aSelector;
	
	[super initWithCustomView:button];
	return self;
}

-(void)handleButtonTouch
{
	CALayer *buttonLayer = [button layer];
	if([buttonLayer animationForKey:@"animateLayer"])
		return;
	
	[button setImage:nil forState:UIControlStateNormal];
	
	CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
	if(isOn)
		[animation setValues:onToOffImages];
	else
		[animation setValues:offToOnImages];
	[animation setDuration:animationDuration];
	[animation setAutoreverses:NO];
	[buttonLayer addAnimation:animation forKey:@"animateLayer"];
	
	if(isOn)
		buttonLayer.contents = (id)[offImage CGImage];
	else
		buttonLayer.contents = (id)[onImage CGImage];
	
	isOn = !isOn;
	
	if((target) && ([target respondsToSelector:selector]))
		[target performSelector:selector];
}

-(void) setOn:(BOOL)b
{
	isOn = b;
	if(isOn)
		[button layer].contents = (id)[onImage CGImage];
	else
		[button layer].contents = (id)[offImage CGImage];
}

-(BOOL) on
{
	return isOn;
}

-(void) dealloc
{
	[super dealloc];
	[button release];
	[offToOnImages release];
	[onToOffImages release];
	[offImage release];
	[onImage release];
}

@end
