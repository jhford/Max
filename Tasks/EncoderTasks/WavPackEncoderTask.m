/*
 *  $Id$
 *
 *  Copyright (C) 2005, 2006 Stephen F. Booth <me@sbooth.org>
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

#import "WavPackEncoderTask.h"
#import "WavPackEncoder.h"
#import "IOException.h"

#include <WavPack/wputils.h>

@interface AudioMetadata (TagMappings)
+ (NSString *)			customizeWavPackTag:(NSString *)tag;
@end

@implementation WavPackEncoderTask

- (id) initWithTask:(PCMGeneratingTask *)task
{
	if((self = [super initWithTask:task])) {
		_encoderClass = [WavPackEncoder class];
		return self;
	}
	return nil;
}

- (void) writeTags
{
	AudioMetadata								*metadata				= [self metadata];
	unsigned									trackNumber				= 0;
	unsigned									trackTotal				= 0;
	unsigned									discNumber				= 0;
	unsigned									discTotal				= 0;
	BOOL										compilation				= NO;
	NSString									*album					= nil;
	NSString									*artist					= nil;
	NSString									*composer				= nil;
	NSString									*title					= nil;
	unsigned									year					= 0;
	NSString									*genre					= nil;
	NSString									*comment				= nil;
	NSString									*trackComment			= nil;
	NSString									*isrc					= nil;
	NSString									*mcn					= nil;
	NSString									*bundleVersion;
    WavpackContext								*wpc					= NULL;
	char										error [80];
	
	
	wpc = WavpackOpenFileInput([_outputFilename fileSystemRepresentation], error, OPEN_EDIT_TAGS, 0);
	if(NULL == wpc) {
		@throw [IOException exceptionWithReason:NSLocalizedStringFromTable(@"Unable to open the output file.", @"Exceptions", @"") 
									   userInfo:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObject:[NSString stringWithCString:error encoding:NSASCIIStringEncoding]] forKeys:[NSArray arrayWithObject:@"errorString"]]];
	}
	
	// Album title
	album = [metadata albumTitle];
	if(nil != album) {
		WavpackAppendTagItem(wpc, [[AudioMetadata customizeWavPackTag:@"ALBUM"] cStringUsingEncoding:NSASCIIStringEncoding], [album UTF8String], strlen([album UTF8String]));
	}
	
	// Artist
	artist = [metadata trackArtist];
	if(nil == artist) {
		artist = [metadata albumArtist];
	}
	if(nil != artist) {
		WavpackAppendTagItem(wpc, [[AudioMetadata customizeWavPackTag:@"ARTIST"] cStringUsingEncoding:NSASCIIStringEncoding], [artist UTF8String], strlen([artist UTF8String]));
	}
	
	// Composer
	composer = [metadata trackComposer];
	if(nil == composer) {
		composer = [metadata albumComposer];
	}
	if(nil != composer) {
		WavpackAppendTagItem(wpc, [[AudioMetadata customizeWavPackTag:@"COMPOSER"] cStringUsingEncoding:NSASCIIStringEncoding], [composer UTF8String], strlen([composer UTF8String]));
	}
	
	// Genre
	genre = [metadata trackGenre];
	if(nil == genre) {
		genre = [metadata albumGenre];
	}
	if(nil != genre) {
		WavpackAppendTagItem(wpc, [[AudioMetadata customizeWavPackTag:@"GENRE"] cStringUsingEncoding:NSASCIIStringEncoding], [genre UTF8String], strlen([genre UTF8String]));
	}
	
	// Year
	year = [metadata trackYear];
	if(0 == year) {
		year = [metadata albumYear];
	}
	if(0 != year) {
		WavpackAppendTagItem(wpc, [[AudioMetadata customizeWavPackTag:@"YEAR"] cStringUsingEncoding:NSASCIIStringEncoding], [[NSString stringWithFormat:@"%u", year] UTF8String], strlen([[NSString stringWithFormat:@"%u", year] UTF8String]));
	}
	
	// Comment
	comment			= [metadata albumComment];
	trackComment	= [metadata trackComment];
	if(nil != trackComment) {
		comment = (nil == comment ? trackComment : [NSString stringWithFormat:@"%@\n%@", trackComment, comment]);
	}
	if(_writeSettingsToComment) {
		comment = (nil == comment ? [self settings] : [NSString stringWithFormat:@"%@\n%@", comment, [self settings]]);
	}
	if(nil != comment) {
		WavpackAppendTagItem(wpc, [[AudioMetadata customizeWavPackTag:@"COMMENT"] cStringUsingEncoding:NSASCIIStringEncoding], [comment UTF8String], strlen([comment UTF8String]));
	}
	
	// Track title
	title = [metadata trackTitle];
	if(nil != title) {
		WavpackAppendTagItem(wpc, [[AudioMetadata customizeWavPackTag:@"TITLE"] cStringUsingEncoding:NSASCIIStringEncoding], [title UTF8String], strlen([title UTF8String]));
	}
	
	// Track number
	trackNumber = [metadata trackNumber];
	if(0 != trackNumber) {
		WavpackAppendTagItem(wpc, [[AudioMetadata customizeWavPackTag:@"TRACK"] cStringUsingEncoding:NSASCIIStringEncoding], [[NSString stringWithFormat:@"%u", trackNumber] UTF8String], strlen([[NSString stringWithFormat:@"%u", trackNumber] UTF8String]));
	}
	
	// Track total
	trackTotal = [metadata albumTrackCount];
	if(0 != trackTotal) {
		WavpackAppendTagItem(wpc, [[AudioMetadata customizeWavPackTag:@"TRACKTOTAL"] cStringUsingEncoding:NSASCIIStringEncoding], [[NSString stringWithFormat:@"%u", trackTotal] UTF8String], strlen([[NSString stringWithFormat:@"%u", trackTotal] UTF8String]));
	}
	
	// Disc number
	discNumber = [metadata discNumber];
	if(0 != discNumber) {
		WavpackAppendTagItem(wpc, [[AudioMetadata customizeWavPackTag:@"DISCNUMBER"] cStringUsingEncoding:NSASCIIStringEncoding], [[NSString stringWithFormat:@"%u", discNumber] UTF8String], strlen([[NSString stringWithFormat:@"%u", discNumber] UTF8String]));
	}
	
	// Discs in set
	discTotal = [metadata discTotal];
	if(0 != discTotal) {
		WavpackAppendTagItem(wpc, [[AudioMetadata customizeWavPackTag:@"DISCTOTAL"] cStringUsingEncoding:NSASCIIStringEncoding], [[NSString stringWithFormat:@"%u", discTotal] UTF8String], strlen([[NSString stringWithFormat:@"%u", discTotal] UTF8String]));
	}
	
	// Compilation
	compilation = [metadata compilation];
	if(compilation) {
		WavpackAppendTagItem(wpc, [[AudioMetadata customizeWavPackTag:@"COMPILATION"] cStringUsingEncoding:NSASCIIStringEncoding], [@"1" UTF8String], strlen([@"1" UTF8String]));
	}
	
	// ISRC
	isrc = [metadata ISRC];
	if(nil != isrc) {
		WavpackAppendTagItem(wpc, [[AudioMetadata customizeWavPackTag:@"ISRC"] cStringUsingEncoding:NSASCIIStringEncoding], [isrc UTF8String], strlen([isrc UTF8String]));
	}
	
	// MCN
	mcn = [metadata MCN];
	if(nil != mcn) {
		WavpackAppendTagItem(wpc, [[AudioMetadata customizeWavPackTag:@"MCN"] cStringUsingEncoding:NSASCIIStringEncoding], [mcn UTF8String], strlen([mcn UTF8String]));
	}
	
	// Encoded by
	bundleVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
	WavpackAppendTagItem(wpc, "TOOL NAME", "Max", strlen("Max"));
	WavpackAppendTagItem(wpc, "TOOL VERSION", [bundleVersion UTF8String], strlen([bundleVersion UTF8String]));
	
	// Encoder settings
	WavpackAppendTagItem(wpc, "ENCODING", [[self settings] UTF8String], strlen([[self settings] UTF8String]));	

	if(0 == WavpackWriteTag(wpc)) {
		@throw [IOException exceptionWithReason:NSLocalizedStringFromTable(@"Unable to write to the output file.", @"Exceptions", @"") 
									   userInfo:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObject:[NSString stringWithCString:error encoding:NSASCIIStringEncoding]] forKeys:[NSArray arrayWithObject:@"errorString"]]];
	}
	
	if(NULL != WavpackCloseFile(wpc)) {
		@throw [IOException exceptionWithReason:NSLocalizedStringFromTable(@"Unable to close the output file.", @"Exceptions", @"") 
									   userInfo:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObject:[NSString stringWithCString:error encoding:NSASCIIStringEncoding]] forKeys:[NSArray arrayWithObject:@"errorString"]]];
	}
}

- (NSString *)		extension						{ return @"wv"; }
- (NSString *)		outputFormat					{ return NSLocalizedStringFromTable(@"WavPack", @"General", @""); }

@end