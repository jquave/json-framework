/*
 Copyright (c) 2010, Stig Brautaset.
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are
 met:
 
   Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
  
   Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
 
   Neither the name of the the author nor the names of its contributors
   may be used to endorse or promote products derived from this software
   without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
 IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "SBJsonStreamParserAdapter.h"

@interface SBJsonStreamParserAdapter ()

- (void)pop;
- (void)parser:(SBJsonStreamParser*)parser foundObject:(id)obj;

@end



@implementation SBJsonStreamParserAdapter

@synthesize delegate;

#pragma mark Housekeeping

- (id)init {
	self = [super init];
	if (self) {
		keyStack = [NSMutableArray new];
		stack = [NSMutableArray new];
		
		currentType = SBJsonStreamParserAdapterNone;
	}
	return self;
}	

- (void)dealloc {
	[top release];
	[keyStack release];
	[stack release];
	[super dealloc];
}

#pragma mark Private methods

- (void)pop {
	[stack removeLastObject];
	array = nil;
	dict = nil;
	currentType = SBJsonStreamParserAdapterNone;
	
	id value = [stack lastObject];
	
	if ([value isKindOfClass:[NSArray class]]) {
		array = value;
		currentType = SBJsonStreamParserAdapterArray;
	} else if ([value isKindOfClass:[NSDictionary class]]) {
		dict = value;
		currentType = SBJsonStreamParserAdapterObject;
	}
}

- (void)parser:(SBJsonStreamParser*)parser foundObject:(id)obj {
	switch (currentType) {
		case SBJsonStreamParserAdapterArray:
			[array addObject:obj];
			break;

		case SBJsonStreamParserAdapterObject:
			[dict setObject:obj forKey:key];
			[keyStack removeLastObject];
			key = [keyStack lastObject];
			break;
			
		case SBJsonStreamParserAdapterNone:
			if ([top isKindOfClass:[NSArray class]]) {
				[delegate parser:parser foundArray:top];
			} else {
				[delegate parser:parser foundObject:top];
			}				
			break;

		default:
			break;
	}
}



#pragma mark Delegate methods

- (void)parserStartedObject:(SBJsonStreamParser*)parser {
	dict = [[NSMutableDictionary new] autorelease];
	if (!top)
		top = [dict retain];
	[stack addObject:dict];
	currentType = SBJsonStreamParserAdapterObject;
}

- (void)parser:(SBJsonStreamParser*)parser foundObjectKey:(NSString*)key_ {
	key = key_;
	[keyStack addObject:key_];
}

- (void)parserEndedObject:(SBJsonStreamParser*)parser {
	id value = [[stack lastObject] retain];
	[self pop];
	[self parser:parser foundObject:value];
	[value release];
}

- (void)parserStartedArray:(SBJsonStreamParser*)parser {
	array = [[NSMutableArray new] autorelease];
	if (!top)
		top = [array retain];
	[stack addObject:array];
	currentType = SBJsonStreamParserAdapterArray;
}

- (void)parserEndedArray:(SBJsonStreamParser*)parser {
	id value = [[stack lastObject] retain];
	[self pop];
	[self parser:parser foundObject:value];
	[value release];
}

- (void)parser:(SBJsonStreamParser*)parser foundBoolean:(BOOL)x {
	[self parser:parser foundObject:[NSNumber numberWithBool:x]];
}

- (void)parserFoundNull:(SBJsonStreamParser*)parser {
	[self parser:parser foundObject:[NSNull null]];
}

- (void)parser:(SBJsonStreamParser*)parser foundInteger:(NSInteger)num {
	[self parser:parser foundObject:[NSNumber numberWithInteger:num]];
}

- (void)parser:(SBJsonStreamParser*)parser foundDouble:(double)num {
	[self parser:parser foundObject:[NSNumber numberWithDouble:num]];
}

- (void)parser:(SBJsonStreamParser*)parser foundString:(NSString*)string {
	[self parser:parser foundObject:string];
}

@end
