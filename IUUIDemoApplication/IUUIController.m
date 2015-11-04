/*

Version: 1.0.3

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

#import "IUUIController.h"

@interface IUUIController (private)
- (void)setupMenuItems;
- (NSDictionary*)createOptionsDictionary;
@end

@implementation IUUIController

- (NSDictionary*)createOptionsDictionary
{
	NSMutableDictionary	*options = [[[NSMutableDictionary alloc] init] autorelease];
	
	switch(filterSizeFlavorSelection)
	{
		case 0:
			[options setObject:IKUISizeSmall forKey:IKUISizeFlavor];
			break;
		case 1:
			[options setObject:IKUISizeMini forKey:IKUISizeFlavor];
			break;
		default:
			[options setObject:IKUISizeRegular forKey:IKUISizeFlavor];
			break;
	}
	switch(filterSetSelection)
	{
		case 0:
			[options setObject:kCIUISetBasic forKey:kCIUIParameterSet];
			break;
		case 1:
			[options setObject:kCIUISetIntermediate forKey:kCIUIParameterSet];
			break;
		case 2:
			[options setObject:kCIUISetAdvanced forKey:kCIUIParameterSet];
			break;
		default:
			[options setObject:kCIUISetDevelopment forKey:kCIUIParameterSet];
			break;
	}
	return options;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:filterController];
	[super dealloc];
}

- (void)awakeFromNib
{
	[CIPlugIn loadAllPlugIns];
	[self setupMenuItems];
	[[NSNotificationCenter defaultCenter] addObserver:filterController 
												selector:@selector(addFilter:)
												name:IKFilterBrowserFilterDoubleClickNotification 
												object:nil];
												
	NSURL *URL = [NSURL fileURLWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"jpg"]];
	CIImage		*image = [CIImage imageWithContentsOfURL:URL];
	CGRect		imageRect = [image extent];
	NSRect		screenRect = [[[renderView window] screen] frame];
	NSSize		contentSize;
	
	// make sure the window fits on the screen and the image gets scaled to if needed using an affine transform
	// This means we will be processing the scaled image, not the high-res image and then scale it, which might be
	// needed by some image processing applications. But in this case it enhances the performance and you can still
	// preview the effects of a filter by scaling the parameter (eg. half the blur radius for a half size image) but 
	// in this sample we leave this as an exercise to the reader.
	contentSize.width = MIN(imageRect.size.width, screenRect.size.width);
	contentSize.height = MIN(imageRect.size.height, screenRect.size.height);
	[[renderView window] setContentSize:contentSize];
	if((contentSize.width < imageRect.size.width) || (contentSize.height < imageRect.size.height))
	{
		CGFloat					scale = MIN((contentSize.width / imageRect.size.width), (contentSize.height / imageRect.size.height));
		NSAffineTransform		*transform = [NSAffineTransform transform];
		[transform scaleBy:scale];
		CIFilter				*scaleFilter = [CIFilter filterWithName:@"CIAffineTransform" keysAndValues:kCIInputImageKey, image, kCIInputTransformKey, transform, nil];
		
		image = [scaleFilter valueForKey:kCIOutputImageKey];
	}
	[filterController setBackgroundImage:image];
	[filterController positionPalette];
}

- (IBAction)addFilter:(id)sender
{
}

- (IBAction)showFilterBrowserPanel:(id)sender
{
	NSDictionary		*filterBrowserOptions = [self createOptionsDictionary];
	
	if(!filterBrowserPanel)
		filterBrowserPanel = [[IKFilterBrowserPanel filterBrowserPanelWithStyleMask:filterBrowserStyleMask] retain];
	
	if(filterBrowserInSheet)
	{
		[filterBrowserPanel beginSheetWithOptions:filterBrowserOptions modalForWindow:[renderView window] modalDelegate:self didEndSelector:@selector(browserPaneldidEndSelector:returnCode:contextInfo:) contextInfo:nil];
	} else {
		[filterBrowserPanel beginWithOptions:filterBrowserOptions modelessDelegate:self didEndSelector:@selector(browserPaneldidEndSelector:returnCode:contextInfo:) contextInfo:nil];	
	}
}

- (IBAction)testSelection:(id)sender
{
	switch([sender tag])
	{
		case 0:
		case 1:
		case 2:
		case 3:
			filterSetSelection = [sender tag];
			break;

		case 10:
		case 11:
		case 12:
			filterSizeFlavorSelection = [sender tag] - 10;
			break;
			
		case 20:
			filterBrowserInSheet = !filterBrowserInSheet;
			break;

		case 100:
			[filterBrowserPanel release];	// force a new browser window
			filterBrowserPanel = nil;
			filterBrowserStyleMask = ~filterBrowserStyleMask & NSTexturedBackgroundWindowMask;
	}
	[self setupMenuItems];
}

- (void)setupMenuItems
{
	NSArray			*menuItems = [testMenu itemArray];
	NSEnumerator	*menuItemsIterator = [menuItems objectEnumerator];
	NSMenuItem		*curItem;
	
	while(curItem = [menuItemsIterator nextObject])
	{
		if([curItem tag] == filterSetSelection || [curItem tag] == (filterSizeFlavorSelection + 10))
			[curItem setState:NSOnState];
		else 
			[curItem setState:NSOffState];
	}
	curItem = [testMenu itemWithTag:20];
	if(filterBrowserInSheet)
		[curItem setState:NSOnState];
	else 
		[curItem setState:NSOffState];
	curItem = [testMenu itemWithTag:100];
	if(filterBrowserStyleMask & NSTexturedBackgroundWindowMask)
		[curItem setState:NSOnState];
	else 
		[curItem setState:NSOffState];
	
}

- (void)browserPaneldidEndSelector:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
}

@end
