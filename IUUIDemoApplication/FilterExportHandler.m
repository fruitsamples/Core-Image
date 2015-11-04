/*

Version: 1.0

© Copyright 2007 Apple, Inc. All rights reserved.

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

#import "FilterExportHandler.h" 
#import "LayerObject.h"


@interface FilterExportHandler (FilterExportHandler_Internal)

- (void)_createExportKeyArrayFromLayerArray:(NSArray*)layerArray;
- (IBAction)_finish:(id)sender;
@end

@implementation FilterExportHandler

- (void)exportLayerArray:(NSArray*)layerArray
{
	[self _createExportKeyArrayFromLayerArray:layerArray];
	if([NSApp runModalForWindow:exportDialog])
	{
		NSSavePanel			*savePanel = [NSSavePanel savePanel];
		NSMutableDictionary	*classAttributes = [NSMutableDictionary dictionary];
		
		[classAttributes setObject:[nameField stringValue] forKey:kCIAttributeFilterDisplayName];
		[classAttributes setObject:[descriptionField stringValue] forKey:kCIAttributeDescription];
		[classAttributes setObject:[NSArray arrayWithObject:[[categoryPopUp selectedItem] representedObject]] forKey:kCIAttributeFilterCategories];
		[generator setClassAttributes:classAttributes];

		//setup the exported keys
		NSEnumerator	*enumerator = [exportKeyArray objectEnumerator];
		NSDictionary	*exportKeyDict;
		
		while(exportKeyDict = [enumerator nextObject])
		{
			if([[exportKeyDict objectForKey:@"Export"] boolValue] == YES )
				[generator exportKey:[exportKeyDict objectForKey:@"Key"] fromObject:[exportKeyDict objectForKey:@"Filter"] withName:[exportKeyDict objectForKey:@"Name"]];
		}
		[exportDialog close];
    
		[savePanel setTitle:@"Save filter"];
		if([savePanel runModalForDirectory:nil file:[NSString stringWithFormat:@"%@.cifilter", [nameField stringValue]]] == NSFileHandlingPanelOKButton)
		{
			[generator writeToURL:[savePanel URL] atomically:YES];
		}
	} else {
		[exportDialog close];
	}
}

- (IBAction)_finish:(id)sender
{
	[NSApp stopModalWithCode:[sender tag]];
}

- (void)awakeFromNib
{
	//setup categoriesPopUp
	
	[categoryPopUp addItemWithTitle:[CIFilter localizedNameForCategory:kCICategoryDistortionEffect]]; 
	[categoryPopUp addItemWithTitle:[CIFilter localizedNameForCategory:kCICategoryGeometryAdjustment]];
	[categoryPopUp addItemWithTitle:[CIFilter localizedNameForCategory:kCICategoryCompositeOperation]];
	[categoryPopUp addItemWithTitle:[CIFilter localizedNameForCategory:kCICategoryHalftoneEffect]];
	[categoryPopUp addItemWithTitle:[CIFilter localizedNameForCategory:kCICategoryColorAdjustment]];
	[categoryPopUp addItemWithTitle:[CIFilter localizedNameForCategory:kCICategoryColorEffect]];
	[categoryPopUp addItemWithTitle:[CIFilter localizedNameForCategory:kCICategoryTransition]];
	[categoryPopUp addItemWithTitle:[CIFilter localizedNameForCategory:kCICategoryTileEffect]];
	[categoryPopUp addItemWithTitle:[CIFilter localizedNameForCategory:kCICategoryGenerator]];
	[categoryPopUp addItemWithTitle:[CIFilter localizedNameForCategory:kCICategoryReduction]];
	[categoryPopUp addItemWithTitle:[CIFilter localizedNameForCategory:kCICategoryGradient]];
	[categoryPopUp addItemWithTitle:[CIFilter localizedNameForCategory:kCICategoryStylize]];
	[categoryPopUp addItemWithTitle:[CIFilter localizedNameForCategory:kCICategorySharpen]];
	[categoryPopUp addItemWithTitle:[CIFilter localizedNameForCategory:kCICategoryBlur]];
	[[categoryPopUp itemWithTitle:[CIFilter localizedNameForCategory:kCICategoryDistortionEffect]] setRepresentedObject:kCICategoryDistortionEffect]; 
	[[categoryPopUp itemWithTitle:[CIFilter localizedNameForCategory:kCICategoryGeometryAdjustment]] setRepresentedObject:kCICategoryGeometryAdjustment];
	[[categoryPopUp itemWithTitle:[CIFilter localizedNameForCategory:kCICategoryCompositeOperation]] setRepresentedObject:kCICategoryCompositeOperation];
	[[categoryPopUp itemWithTitle:[CIFilter localizedNameForCategory:kCICategoryHalftoneEffect]] setRepresentedObject:kCICategoryHalftoneEffect];
	[[categoryPopUp itemWithTitle:[CIFilter localizedNameForCategory:kCICategoryColorAdjustment]] setRepresentedObject:kCICategoryColorAdjustment];
	[[categoryPopUp itemWithTitle:[CIFilter localizedNameForCategory:kCICategoryColorEffect]] setRepresentedObject:kCICategoryColorEffect];
	[[categoryPopUp itemWithTitle:[CIFilter localizedNameForCategory:kCICategoryTransition]] setRepresentedObject:kCICategoryTransition];
	[[categoryPopUp itemWithTitle:[CIFilter localizedNameForCategory:kCICategoryTileEffect]] setRepresentedObject:kCICategoryTileEffect];
	[[categoryPopUp itemWithTitle:[CIFilter localizedNameForCategory:kCICategoryGenerator]] setRepresentedObject:kCICategoryGenerator];
	[[categoryPopUp itemWithTitle:[CIFilter localizedNameForCategory:kCICategoryReduction]] setRepresentedObject:kCICategoryReduction];
	[[categoryPopUp itemWithTitle:[CIFilter localizedNameForCategory:kCICategoryGradient]] setRepresentedObject:kCICategoryGradient];
	[[categoryPopUp itemWithTitle:[CIFilter localizedNameForCategory:kCICategoryStylize]] setRepresentedObject:kCICategoryStylize];
	[[categoryPopUp itemWithTitle:[CIFilter localizedNameForCategory:kCICategorySharpen]] setRepresentedObject:kCICategorySharpen];
	[[categoryPopUp itemWithTitle:[CIFilter localizedNameForCategory:kCICategoryBlur]] setRepresentedObject:kCICategoryBlur];

	[categoryPopUp selectItemWithTitle:[CIFilter localizedNameForCategory:kCICategoryStylize]];
}

- (void)_createExportKeyArrayFromLayerArray:(NSArray*)layerArray
{
	NSUInteger	index, max = [layerArray count];
	
	[exportKeyArray release];
	exportKeyArray = nil;
	exportKeyArray = [[NSMutableArray alloc] init];
	
	[generator release];
	generator = nil;
	generator = [[CIFilterGenerator filterGenerator] retain];


	for(index = 1; index < max; index++) // skip over first layer as it is the background image
	{
		FilterLayerObject		*layer = [layerArray objectAtIndex:index];
		CIFilter				*filter = [layer filter];
		
		if(filter)
		{
			NSEnumerator	*enumerator = [[filter inputKeys] objectEnumerator];
			NSString		*currentKey;
			NSString		*filterName = [[filter attributes] objectForKey:kCIAttributeFilterDisplayName];
			
			//create connection in generator
			NSDictionary	*bindingInfo = [filter infoForBinding:kCIInputImageKey];
			
			if(bindingInfo)
			{
				id	sourceObject = [bindingInfo objectForKey:NSObservedObjectKey];
				
				if(![sourceObject isKindOfClass:[CIFilter class]]) 
					sourceObject = nil;
				[generator connectObject:sourceObject
							withKey:[bindingInfo objectForKey:NSObservedKeyPathKey] 
							toObject:filter withKey:kCIInputImageKey];
			}
			
			while(currentKey = [enumerator nextObject])
			{
				NSDictionary			*keyAttributes = [[filter attributes] objectForKey:currentKey];
				BOOL					doExport = NO;
				NSMutableDictionary		*exportKeyDict = nil;
				
				if([[keyAttributes objectForKey:kCIAttributeClass] isEqualToString:@"CIImage"])
				{
					if(![currentKey isEqualToString:kCIInputImageKey])	// export all images that are not inputImages
						doExport = YES;
					else if([currentKey isEqualToString:kCIInputImageKey] && (index == 1))	//only the first image
						doExport = YES;
				}
				

				exportKeyDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:doExport], @"Export",
																			filterName, @"FilterName",
																			filter, @"Filter",
																			currentKey, @"Key",
																			currentKey, @"Name", // TODO make exported name unique
																			nil];
				[exportKeyArray addObject:exportKeyDict];
			}
		}
	}	
	if(max > 1) // in this sample we do not support to export just the background image as a filter
	{
		CIFilter	*lastFilter = [[layerArray objectAtIndex:index-1] filter];
		if(lastFilter)
			[generator exportKey:kCIOutputImageKey fromObject:lastFilter withName:kCIOutputImageKey];
	}
}


#pragma mark NSTableDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [exportKeyArray count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	return [[exportKeyArray objectAtIndex:row] objectForKey:[tableColumn identifier]];
}


- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;
{
	[[exportKeyArray objectAtIndex:row] setObject:object forKey:[tableColumn identifier]];
}


@end
