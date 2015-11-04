#import "CIExposureView.h"

@implementation CIExposureView

- (void)awakeFromNib 
{
    /*
    **  Enabling QuartzGL for this window greatly improves
    **  rendering preformance when Core Image drawing goes
    **  to a Core Graphics context.
    */
    [[self window] setPreferredBackingLocation:
        NSWindowBackingLocationVideoMemory];
}

- (void)sliderChanged: (id)sender
{
    exposureValue = [sender floatValue];
    [self setNeedsDisplay: YES];
}

- (void)drawRect: (NSRect)rect
{
    CIContext *context = [[NSGraphicsContext currentContext] CIContext];
    CGRect     cg = CGRectMake(NSMinX(rect), NSMinY(rect),
        NSWidth(rect), NSHeight(rect));
    
    if(filter == nil)
    {
        CIImage   *image;

        /*
        **  First time around, we load the image from disk and
        **  instantiate the filter object. Holding on to the image
        **  and the filter does improve performance as it will
        **  avoid memory allocations and I/O on subsequent draw
        **  calls.
        */
        image    = [CIImage imageWithContentsOfURL: [NSURL fileURLWithPath:
            [[NSBundle mainBundle] pathForResource: @"Rose" ofType: @"jpg"]]];
        filter   = [CIFilter filterWithName: @"CIExposureAdjust"
            keysAndValues: @"inputImage", image, nil];

        [filter retain];
    }

    [filter setValue: [NSNumber numberWithFloat: exposureValue]
        forKey: @"inputEV"];

    if(context != nil)
        [context drawImage: [filter valueForKey: @"outputImage"]
            atPoint: cg.origin  fromRect: cg];
}

@end
