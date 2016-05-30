//
//  BlurFocus.m
//  BlurFocus
//
//  Created by Wolfgang Baird on 4/30/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

@import AppKit;
#import <QuartzCore/QuartzCore.h>

typedef void * CGSConnection;
extern OSStatus CGSSetWindowBackgroundBlurRadius(CGSConnection connection, NSInteger   windowNumber, int radius);
extern CGSConnection CGSDefaultConnectionForThread();

@interface BlurFocus : NSObject
@end

@implementation BlurFocus

bool _filtersAdded = false;
NSArray *_filters;

CIFilter *_blurFilter, *_saturationFilter;
float blurRadius;
NSColor *tintColor;

+ (void)load
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wb_blurWindow:) name:NSWindowDidResignKeyNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wb_blurWindow:) name:NSWindowDidResignMainNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wb_restoreBlur:) name:NSWindowDidBecomeMainNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wb_restoreBlur:) name:NSWindowDidBecomeKeyNotification object:nil];
    NSLog(@"Grayifier loaded...");
}

+ (void)wb_blurWindow:(NSNotification *)note
{
    if (!_filtersAdded) {
        //        NSLog(@"Filter added");
        //        Yes, apply grayscale filter
        
        //        CIFilter *filt = [CIFilter filterWithName:@"CIColorMonochrome"]; // CIImage
        //        [filt setDefaults];
        //        [filt setValue:[CIColor colorWithRed:.3 green:.3 blue:.3 alpha:1] forKey:@"inputColor"];
        //
        //        CIFilter *filt2 = [CIFilter filterWithName:@"CIGammaAdjust"]; // CIImage
        //        [filt2 setDefaults];
        //        [filt2 setValue:[NSNumber numberWithFloat:0.3] forKey:@"inputPower"];
        //
        NSWindow *win = note.object;
        _filters = [[win.contentView superview] contentFilters];
        //        [[win.contentView superview] setWantsLayer:YES];
        //        [[win.contentView superview] setContentFilters:[NSArray arrayWithObjects:filt, filt2, nil]];
        
        NSView *_win = [[win contentView] superview];
        
        // Set up the default parameters
        blurRadius = 1.0;
        
        // To apply CIFilters on OS X 10.9, we need to set the property accordingly:
        [_win setWantsLayer:YES];
        [_win setLayerUsesCoreImageFilters:YES];
        
        // Set the layer to redraw itself once it's size is changed
        [_win.layer setNeedsDisplayOnBoundsChange:YES];
        
        // Next, we create the blur filter
        _blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
        [_blurFilter setDefaults];
        [_blurFilter setValue:[NSNumber numberWithFloat:blurRadius] forKey:@"inputRadius"];
        
        // Now we apply the two filters as the layer's background filters
        [_win setContentFilters:@[_blurFilter]];
        
        // ... and trigger a refresh
        [_win.layer setNeedsDisplay];
        
        [win setAlphaValue:0.9];
        
        _filtersAdded = !_filtersAdded;
    }
}

+ (void)wb_restoreBlur:(NSNotification *)note
{
    if (_filtersAdded) {
        //        NSLog(@"Filter removed");
        //        Yes, remove grayscale filter
        
        NSWindow *win = note.object;
        [[win.contentView superview] setWantsLayer:YES];
        [[win.contentView superview] setContentFilters:_filters];
        [win setViewsNeedDisplay:YES];
        [win setAlphaValue:1.0];
        _filtersAdded = !_filtersAdded;
    }
}

@end
