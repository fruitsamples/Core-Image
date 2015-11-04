/*

Version: 1.1

© Copyright 2007 Apple Computer, Inc. All rights reserved.

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
#import "FilterPanelController.h"
#import "IUUIController.h"
#import "LayerObject.h"
#import "FilterExportHandler.h"


@implementation IKFilterUIView (EventHandlerCategory)

- (void)mouseDown:(NSEvent*)inEvent
{
	[(FilterPanelController*)[[self window] delegate] selectFilter:[self filter]];
}

@end

@implementation NSTextField (EventHandlerCategory)	// this is to allow mouse forwarding from the filter label field so the filter can be selected

- (void)mouseDown:(NSEvent*)inEvent
{
	[[self target] mouseDown:inEvent];
}

@end

@implementation FilterPanelController

- (void)_tintFilterViewBackgrounds
{
	int		index = [layerArray count];
	
	while(--index >= 0)
	{
		LayerObject		*layer = [layerArray objectAtIndex:index];
		if(index == filterSelectionIndex)
			[layer setBackgroundColor:[NSColor alternateSelectedControlColor]];
		else
			[layer setBackgroundColor:[[NSColor controlAlternatingRowBackgroundColors] objectAtIndex:(index % 2)]];
	}
	[removeFilterButton setEnabled:filterSelectionIndex > 0];
	[exportFilterButton setEnabled:[layerArray count] > 1];
}

- (int)_indexFromFilter:(CIFilter*)inFilter
{
	int		index;
	
	for(index = 1; index < [layerArray count]; index++)
	{
		if([[layerArray objectAtIndex:index] filter] == inFilter)
			return index;
	}
	
	return 0;
}

- (void)awakeFromNib
{
	[self selectFilter:nil];
	[[filterContainerBox window] setBackgroundColor:[NSColor headerColor]];
	[[filterContainerBox window] orderFront:self];
}

 - (void)positionPalette
 {
	NSRect	windowRect = [[renderView window] frame];
	windowRect.origin.x = NSMaxX(windowRect);
	windowRect.origin.y = NSMaxY(windowRect);
	[[filterContainerBox window] setFrameOrigin:windowRect.origin];
 }
 
- (void)dealloc
{
	[layerArray release];
	[backgroundImage release];
	[super dealloc];
}

- (NSMutableArray*)_layerArray
{
	if(!layerArray)
	{
		layerArray = [[NSMutableArray alloc] init];
		ImageLayerObject	*backgroundLayer = [[ImageLayerObject alloc] init];
		[backgroundLayer setView:backgroundImageContainer];
		[layerArray insertObject:backgroundLayer atIndex:0];	// background layer is the bottom most layer
		[backgroundLayer release];
	}
	return layerArray;
}

- (ImageLayerObject*)backgroundLayer
{
	return [[self _layerArray] objectAtIndex:0];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
	[renderView setImage:[self filteredImage]];
}

- (void)_setupAllImageInputsToNotNil:(CIFilter*)inFilter
{
	NSArray				*inputKeys = [inFilter inputKeys];
	NSEnumerator		*enumerator;
	NSDictionary		*attributeSettings = nil;
	id					key;

	enumerator = [inputKeys objectEnumerator];
    while (key = [enumerator nextObject]) 
    {
		attributeSettings = [[inFilter attributes] objectForKey:key];
		if([[attributeSettings objectForKey:kCIAttributeClass] isEqualToString:@"CIImage"])
		{
			[inFilter setValue:backgroundImage forKey:key];
		}
	}

}

- (void)selectFilter:(CIFilter*)inFilter
{
	filterSelectionIndex = [self _indexFromFilter:inFilter];
	[self _tintFilterViewBackgrounds];
	[filterContainerBox setNeedsDisplay:YES];
}

- (void)addFilter:(NSNotification*)notification
{
	NSString	*filterName = [notification object];
	CIFilter	*newFilter = [CIFilter filterWithName:filterName];
	NSPoint		frameOrigin = NSMakePoint(0, 0);
	
	if(newFilter)
	{	
		NSRect			windowFrame = [[filterContainerBox window] frame];
		
		[newFilter setDefaults];
		[self _setupAllImageInputsToNotNil:newFilter];
		
		// now lets add the filter's view to the controller pallette
		NSDictionary	*options = [controller createOptionsDictionary];
		IKFilterUIView	*filterContentView = [newFilter viewForUIConfiguration:options excludedKeys:[NSArray arrayWithObject:@"inputImage"]];
		NSRect			contentBounds = [filterContentView bounds];
		contentBounds.size.width = [filterContainerBox bounds].size.width;
		
		// in this example we want to add the name of the filter as a title
		NSControlSize	controlSize = NSRegularControlSize;
		NSTextField		*labelField = [[[NSTextField alloc] initWithFrame:contentBounds] autorelease];
		NSRect			labelFrame = NSZeroRect;
		NSString		*titleString = [[newFilter attributes] objectForKey:kCIAttributeFilterDisplayName];
		NSFont			*labelFont;
		NSString		*sizeFlavor = [options objectForKey:IKUISizeFlavor];
		
		// get the desired label font from the view configuration
		if(sizeFlavor)
		{
			if([sizeFlavor compare:IKUISizeMini] == NSOrderedSame)
				controlSize = NSMiniControlSize;
			if([sizeFlavor compare:IKUISizeSmall] == NSOrderedSame)
				controlSize = NSSmallControlSize;
		}
		labelFont = [NSFont labelFontOfSize:[NSFont systemFontSizeForControlSize:controlSize]];
		
		[labelField setFont:labelFont];
		[labelField setEditable:NO];
		[labelField setStringValue:titleString];
		[labelField setDrawsBackground:NO];
		[labelField setBordered:NO];
		[labelField setBezeled:NO];
		[labelField sizeToFit];		
		[labelField setTarget:filterContentView]; // we use this to redirect mouse events to the filter view for filter selection in the palette
		[labelField setAutoresizingMask:NSViewMaxYMargin | NSViewMaxXMargin];
		labelFrame.size = [titleString sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:labelFont, NSFontAttributeName, nil]];
		[labelField setFrameOrigin:NSMakePoint(0.0, contentBounds.size.height)];
		contentBounds.size.height += labelFrame.size.height;
		
		// put the label and the filter ui view in one container view
		NSView			*filterContentPlustTitleView = [[[NSView alloc]initWithFrame:contentBounds] autorelease];
		[filterContentPlustTitleView addSubview:labelField];
		[filterContentPlustTitleView addSubview:filterContentView];

		// we use an NSClipViewer as a container as it provides easy background coloring capabilities
		NSClipView		*filterView = [[NSClipView alloc]initWithFrame:contentBounds];
		[filterView setDocumentView:filterContentPlustTitleView];
		[filterView setDrawsBackground:YES];
		[filterView setAutoresizingMask:NSViewMinYMargin];
		
		FilterLayerObject	*layerObject = [[FilterLayerObject alloc] init];
		[layerObject setFilter:newFilter];
		[layerObject setView:filterView];
		[[layerArray lastObject] removeObserver:self];			
		[layerObject bindInputLayer:[layerArray objectAtIndex:filterSelectionIndex]];
		if(filterSelectionIndex < ([layerArray count] - 1))
		{
			int				i;
			
			[[layerArray objectAtIndex:filterSelectionIndex + 1] bindInputLayer:layerObject];
			frameOrigin = [[[layerArray objectAtIndex:filterSelectionIndex] view] frame].origin;
			//setup the views to follow the resize
			for(i=0; i < [layerArray count]; i++)
			{
				[[[layerArray objectAtIndex:i] view] setAutoresizingMask:i > filterSelectionIndex ? NSViewMaxYMargin : NSViewMinYMargin];
			}
		} 			
		[layerArray insertObject:layerObject atIndex:filterSelectionIndex + 1];

		[layerObject release];
		
		windowFrame.size.height += [filterView bounds].size.height;
		windowFrame.origin.y -= [filterView bounds].size.height;
		[[filterContainerBox window] setFrame:windowFrame display:YES animate:YES];
		[filterContainerBox addSubview:filterView];
		[filterView setFrameOrigin:frameOrigin];
		[self selectFilter:newFilter];
		
		[[layerArray lastObject] addObserver:self];
		[renderView setImage:[self filteredImage]];
	}
}

- (IBAction)removeSelectedFilter:(id)sender
{
	if(filterSelectionIndex > 0)
	{
		NSRect			windowFrame = [[filterContainerBox window] frame];
		NSView			*filterView = nil;
		int				i;

		if(filterSelectionIndex == ([layerArray count] - 1))	// special case as we are deleting the last filter - no rebinding but changing the observer
		{
			[[layerArray objectAtIndex:filterSelectionIndex] removeObserver:self];
			[[layerArray objectAtIndex:filterSelectionIndex - 1] addObserver:self];		
		} else {
			[[layerArray objectAtIndex:filterSelectionIndex + 1] bindInputLayer:[layerArray objectAtIndex:filterSelectionIndex - 1]];
		}
		filterView = [[layerArray objectAtIndex:filterSelectionIndex] view];
		[layerArray removeObjectAtIndex:filterSelectionIndex];
		filterSelectionIndex--;
		//setup the views to follow the resize
		for(i=0; i < [layerArray count]; i++)
		{
			[[[layerArray objectAtIndex:i] view] setAutoresizingMask:i > filterSelectionIndex ? NSViewMaxYMargin : NSViewMinYMargin];
		}
		windowFrame.size.height -= [filterView bounds].size.height;
		windowFrame.origin.y += [filterView bounds].size.height;
		[filterView removeFromSuperview];
		
		[self _tintFilterViewBackgrounds];
		[[filterContainerBox window] setFrame:windowFrame display:YES animate:YES];
		[renderView setImage:[self filteredImage]];
	}
}

- (IBAction)exportFilterChain:(id)sender
{
	[exportHandler exportLayerArray:layerArray];
}

- (void)setBackgroundImage:(CIImage*)inImage
{
	[inImage retain];
	[backgroundImage release];
	backgroundImage = inImage;
	[[self backgroundLayer] setImage:backgroundImage];
	[renderView setImage:[self filteredImage]];
}

- (CIImage*)filteredImage
{
	return [(LayerObject*)[layerArray lastObject] outputImage];	
}

@end
