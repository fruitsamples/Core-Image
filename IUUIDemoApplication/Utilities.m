/*

Utilities.m

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

#import "Utilities.h"
#import "FilterPanelController.h"


@implementation BackgroundClipView 

- (void)mouseDown:(NSEvent*)inEvent
{
	[(FilterPanelController*)[[self window] delegate] selectFilter:nil];
}

@end

@implementation PathToCIImageValueTransformer

/*

	A custom value transformer class that allows us to use a path from an image well to create a CIImage.
	
*/

static NSBitmapImageRep *BitmapImageRepFromNSImage(NSImage *nsImage) {
    // See if the NSImage has an NSBitmapImageRep.  If so, return the first NSBitmapImageRep encountered.  An NSImage that is initialized by loading the contents of a bitmap image file (such as JPEG, TIFF, or PNG) and, not subsequently rescaled, will usually have a single NSBitmapImageRep.
    NSEnumerator *enumerator = [[nsImage representations] objectEnumerator];
    NSImageRep *representation;
    while ((representation = [enumerator nextObject]) != nil) {
        if ([representation isKindOfClass:[NSBitmapImageRep class]]) {
            return (NSBitmapImageRep *)representation;
        }
    }

    // If we didn't find an NSBitmapImageRep (perhaps because we received a PDF image), we can create one using one of two approaches: (1) lock focus on the NSImage, and create the bitmap using -[NSBitmapImageRep initWithFocusedViewRect:], or (2) (Tiger and later) create an NSBitmapImageRep, and an NSGraphicsContext that draws into it using +[NSGraphicsContext graphicsContextWithBitmapImageRep:], and composite the NSImage into the bitmap graphics context.  We'll use approach (1) here, since it is simple and supported on all versions of Mac OS X.
    NSSize size = [nsImage size];
    [nsImage lockFocus];
    NSBitmapImageRep *bitmapImageRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0, 0, size.width, size.height)];
    [nsImage unlockFocus];

    return [bitmapImageRep autorelease];
}

+ (Class)transformedValueClass
{
    return [CIImage class];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;   
}

- (id)transformedValue:(id)value
{
    if (value == nil) return nil;

    if (![value isKindOfClass:[CIImage class]]) {
        [NSException raise: NSInternalInconsistencyException
                    format: @"Value is not a CIImage object.  No idea what to do. (Value is an instance of %@).",
		     [value class]];
    }
	
	NSSize		imageSize = NSMakeSize(48, 48);
	
	CGRect		imageRect = [value extent];
	if(!CGRectIsInfinite(imageRect))
	{
		imageSize.width = imageRect.size.width;
		imageSize.height = imageRect.size.height;
	}
	NSCIImageRep		*ciImageRep = [NSCIImageRep imageRepWithCIImage:value];
	NSImage				*returnImage = [[[NSImage alloc] initWithSize:imageSize] autorelease];
	[returnImage addRepresentation:ciImageRep];
    return returnImage; //returnImage;
}

- (id)reverseTransformedValue:(id)value
{
    if (value == nil) return nil;
    
	CIImage	*returnImage = nil;
	
    if ([value isKindOfClass:[NSString class]]) {
		NSURL	*imageURL = [NSURL fileURLWithPath:value];
        returnImage = [CIImage imageWithContentsOfURL:imageURL];
    } else if ([value isKindOfClass:[NSURL class]]) {
        returnImage = [CIImage imageWithContentsOfURL:value];
    } else if ([value isKindOfClass:[NSImage class]]) {
        returnImage = [[[CIImage alloc]initWithBitmapImageRep:BitmapImageRepFromNSImage(value)] autorelease];
    } else {
		[NSException raise: NSInternalInconsistencyException
                    format: @"Value is not a NSString object.  No idea what to do. (Value is an instance of %@).",
		     [value class]];
	}
    return returnImage;
}

@end

