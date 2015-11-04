/*

File: CIDraw.m

Abstract:   DoDraw encapsulates all the Core Image drawing.

Version: 1.1

© Copyright 2006 Apple Computer, Inc. All rights reserved.

IMPORTANT:  This Apple software is supplied to 
you by Apple Computer, Inc. ("Apple") in 
consideration of your agreement to the following 
terms, and your use, installation, modification 
or redistribution of this Apple software 
constitutes acceptance of these terms.  If you do 
not agree with these terms, please do not use, 
install, modify or redistribute this Apple 
software.

In consideration of your agreement to abide by 
the following terms, and subject to these terms, 
Apple grants you a personal, non-exclusive 
license, under Apple's copyrights in this 
original Apple software (the "Apple Software"), 
to use, reproduce, modify and redistribute the 
Apple Software, with or without modifications, in 
source and/or binary forms; provided that if you 
redistribute the Apple Software in its entirety 
and without modifications, you must retain this 
notice and the following text and disclaimers in 
all such redistributions of the Apple Software. 
Neither the name, trademarks, service marks or 
logos of Apple Computer, Inc. may be used to 
endorse or promote products derived from the 
Apple Software without specific prior written 
permission from Apple.  Except as expressly 
stated in this notice, no other rights or 
licenses, express or implied, are granted by 
Apple herein, including but not limited to any 
patent rights that may be infringed by your 
derivative works or by other works in which the 
Apple Software may be incorporated.

The Apple Software is provided by Apple on an "AS 
IS" basis.  APPLE MAKES NO WARRANTIES, EXPRESS OR 
IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED 
WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY 
AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING 
THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE 
OR IN COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY 
SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL 
DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
OF USE, DATA, OR PROFITS; OR BUSINESS 
INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, 
REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF 
THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER 
UNDER THEORY OF CONTRACT, TORT (INCLUDING 
NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN 
IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF 
SUCH DAMAGE.

*/ 


#import <QuartzCore/QuartzCore.h>
#include "CIDraw.h"

SInt32	    gGammaValue = 75;

const float opaqueBlack[] = { 0.0, 0.0, 0.0, 1.0 };

void drawRomanText(CGContextRef context, CGRect destRect)
{
    static const char *text = "A Carbon Example...";
    size_t textlen = strlen(text);
    static const float fontSize = 40;
    
    // Set the fill color space. This sets the 
    // fill painting color to opaque black.
    CGContextSetFillColorSpace(context, CGColorSpaceCreateDeviceRGB());
    // The Cocoa framework calls the draw method with an undefined
    // text matrix. It's best to set it to what is needed by
    // this code: the identity transform.
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);

    // Choose the font with the PostScript name "Times-Roman", at
    // fontSize points, with the encoding MacRoman encoding.
    CGContextSelectFont(context, "Times-Roman", fontSize, 
					    kCGEncodingMacRoman);

    CGContextSetFillColor(context, opaqueBlack);
    // Default text drawing mode is fill.
    CGContextShowTextAtPoint(context, 1.0, 15.0, text, textlen);

}

CIImage* generateBackgroundImage(void)
{
    static CIImage  *sBackgroundImage = nil;
    
    if(!sBackgroundImage)
    {
	CIFilter *randomGeneratorFilter = [CIFilter filterWithName:@"CIRandomGenerator"];
	CIFilter *blurFilter = [CIFilter filterWithName:@"CIMotionBlur"];
	CIFilter *matrixFilter = [CIFilter filterWithName:@"CIColorMatrix"];
	
	[randomGeneratorFilter setDefaults];
	[blurFilter setDefaults];
	[blurFilter setValue:[randomGeneratorFilter valueForKey: @"outputImage"] forKey:@"inputImage"];
	[matrixFilter setDefaults];
	[matrixFilter setValue:[CIVector vectorWithX: 0.0  Y: 0.0  Z: 0.0  W: 0.6]  forKey:@"inputRVector"];
	[matrixFilter setValue:[CIVector vectorWithX: 0.0  Y: 0.0  Z: 0.0  W: 0.5]  forKey:@"inputGVector"];
	[matrixFilter setValue:[CIVector vectorWithX: 0.0  Y: 0.0  Z: 0.0  W: 0.4]  forKey:@"inputBVector"];
	[matrixFilter setValue:[CIVector vectorWithX: 0.0  Y: 0.0  Z: 0.0  W: 0.0]  forKey:@"inputAVector"];
	[matrixFilter setValue:[CIVector vectorWithX: 0.0  Y: 0.0  Z: 0.0  W: 1.0]  forKey:@"inputBiasVector"];
	[matrixFilter setValue:[blurFilter valueForKey: @"outputImage"] forKey:@"inputImage"];
	
	sBackgroundImage = [[matrixFilter valueForKey: @"outputImage"] retain];
    }
    return sBackgroundImage;
}

void DoDraw(CGContextRef inContext, CGRect bounds)
{
    NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
    CIContext		*ciContext = [CIContext contextWithCGContext:inContext options:nil];
    CIFilter		*wrapFilter = [CIFilter filterWithName:@"CICircularWrap"];
    CIFilter		*gammaFilter = [CIFilter filterWithName:@"CIGammaAdjust"];
    CGRect		layerRect = CGRectMake(0.0, 0.0, 340.0, 70.0);
    
    static CIImage	*textImage = nil;
    
    if(!textImage)
    {
	CGLayerRef	layer = [ciContext createCGLayerWithSize: layerRect.size  info: nil];
	CGContextRef	context = CGLayerGetContext(layer);

	drawRomanText(context, layerRect);
	textImage = [[CIImage alloc] initWithCGLayer:layer];
	CGLayerRelease(layer);
    }

    [wrapFilter setDefaults];
    [wrapFilter setValue:[CIVector vectorWithX: 240.0  Y: -80.0] forKey:@"inputCenter"];
    [wrapFilter setValue:[NSNumber numberWithFloat:300.0] forKey:@"inputRadius"];
    [wrapFilter setValue:[NSNumber numberWithFloat:0.68*M_PI] forKey:@"inputAngle"];
    [wrapFilter setValue:textImage forKey:@"inputImage"];
    layerRect = [[wrapFilter valueForKey: @"outputImage"] extent];

    [gammaFilter setDefaults];
    [gammaFilter setValue:[NSNumber numberWithFloat: 1.0 + ((float)gGammaValue / 100.0)] forKey:@"inputPower"];
    [gammaFilter setValue:generateBackgroundImage() forKey:@"inputImage"];

    [ciContext drawImage: [gammaFilter valueForKey: @"outputImage"] atPoint: CGPointZero fromRect: bounds];
    [ciContext drawImage: [wrapFilter valueForKey: @"outputImage"] atPoint: CGPointZero  fromRect: bounds];

    [pool release];
}