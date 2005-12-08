/*
 *  $Id: ApplicationController.m 202 2005-12-04 21:50:52Z me $
 *
 *  Copyright (C) 2005 Stephen F. Booth <me@sbooth.org>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#import "ApplicationController.h"

#import "PreferencesController.h"
#import "AcknowledgmentsController.h"
#import "ComponentVersionsController.h"
#import "MediaController.h"
#import "TaskMaster.h"
#import "LogController.h"
#import "UpdateChecker.h"
#import "IOException.h"
#import "FreeDBProtocolValueTransformer.h";
#import "BooleanArrayValueTransformer.h";
#import "NegateBooleanArrayValueTransformer.h";

#include "AudioToolbox/AudioFile.h";

@implementation ApplicationController

+ (void)initialize
{
	// Set up the ValueTransformers
	NSValueTransformer			*transformer;
	
	transformer = [[[FreeDBProtocolValueTransformer alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:transformer forName:@"FreeDBProtocolValueTransformer"];

	transformer = [[[BooleanArrayValueTransformer alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:transformer forName:@"BooleanArrayValueTransformer"];

	transformer = [[[NegateBooleanArrayValueTransformer alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:transformer forName:@"NegateBooleanArrayValueTransformer"];
}

- (void) awakeFromNib
{
	[GrowlApplicationBridge setGrowlDelegate:self];
	
	// Force the log window to load (so log messages will show up)
	[[LogController sharedController] window];
}

- (BOOL) applicationShouldOpenUntitledFile:(NSApplication *)sender
{
	return NO;
}

- (IBAction) showPreferences:(id)sender
{
	[[PreferencesController sharedPreferences] showWindow:self];
}

- (IBAction) showAcknowledgments:(id)sender
{
	[[AcknowledgmentsController sharedController] showWindow:self];
}

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification
{
	
	OSStatus err;
	UInt32 propertySize;
	
	err = AudioFileGetGlobalInfoSize(
									 kAudioFileGlobalInfo_WritableTypes, 0, NULL, &propertySize);
	if (err) return err;
	
	OSType *types = (OSType*)malloc(propertySize);
	err = AudioFileGetGlobalInfo(
								 kAudioFileGlobalInfo_WritableTypes, 0, NULL, &propertySize,  types);
	if (err) return err;
	
	UInt32 numTypes = propertySize / sizeof(OSType);
	UInt32 i;
	for (i=0; i<numTypes; ++i)
	{
		CFStringRef name;
		UInt32 outSize = sizeof(name);
		err = AudioFileGetGlobalInfo(
									 kAudioFileGlobalInfo_FileTypeName, sizeof(OSType), types+i, &outSize,  &name);
		if (err) return err;
		
		NSArray *extensions;
		outSize = sizeof(extensions);
		err = AudioFileGetGlobalInfo(
									 kAudioFileGlobalInfo_ExtensionsForType, sizeof(OSType), types+i, &outSize,  &extensions);
		if (err) return err;

			
		NSLog(@"%@ %@", name, extensions);
	}
	
	// Setup MediaController to receive DiskAppeared/DiskDisappeared callbacks
	[MediaController sharedController];
}

- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *) sender
{
	if([[TaskMaster sharedController] hasActiveTasks]) {
		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
		[alert addButtonWithTitle:@"OK"];
		[alert addButtonWithTitle:@"Cancel"];
		[alert setMessageText:@"Really Quit?"];
		[alert setInformativeText:@"There are active ripping/encoding tasks."];
		[alert setAlertStyle:NSWarningAlertStyle];
		
		if(NSAlertSecondButtonReturn == [alert runModal]) {
			return NSTerminateCancel;
		}
		// Remove all tasks
		else {
			[[TaskMaster sharedController] removeAllTasks];
		}
	}
	
	return NSTerminateNow;
}

- (IBAction) showComponentVersions:(id)sender
{
	[[ComponentVersionsController sharedController] showWindow:self];
}

- (IBAction) toggleTasksPanel:(id)sender
{
	NSWindow *tasksWindow = [[TaskMaster sharedController] window];
	if([tasksWindow isVisible]) {
		[tasksWindow performClose:self];
	}
	else {
		[tasksWindow makeKeyAndOrderFront:self];
	}
}

- (IBAction) toggleLogPanel:(id)sender
{
	NSWindow *logWindow = [[LogController sharedController] window];
	if([logWindow isVisible]) {
		[logWindow performClose:self];
	}
	else {
		[logWindow makeKeyAndOrderFront:self];
	}
}

- (IBAction) checkForUpdate:(id)sender
{
	[[UpdateChecker sharedController] checkForUpdate];
}

- (IBAction) openHomeURL:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://sbooth.org/Max/"]];
}

- (NSDictionary *) registrationDictionaryForGrowl
{
	NSArray *defaultNotifications = [NSArray arrayWithObjects:
		@"Rip started",
		@"Rip completed",
		@"Rip stopped",
		@"Encode started",
		@"Encode completed",
		@"Encode stopped",
		nil
		];

	NSArray *allNotifications = [NSArray arrayWithObjects:
		@"Rip started",
		@"Rip completed",
		@"Rip stopped",
		@"Encode started",
		@"Encode completed",
		@"Encode stopped",
		nil
		];
	
	
	NSDictionary *regDict = [NSDictionary dictionaryWithObjectsAndKeys:
		@"Max", GROWL_APP_NAME, 
		allNotifications, GROWL_NOTIFICATIONS_ALL, 
		defaultNotifications, GROWL_NOTIFICATIONS_DEFAULT,
		nil];
	return regDict;
}

@end
