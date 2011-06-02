// Copyright (c) 2011 Soutaro Matsumoto
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "Arelish.h"

@implementation Arelish

@synthesize predicates=predicates_;
@synthesize sortDescriptors=sortDescriptors_;

-(id) init {
	self = [super init];
	
	self->predicates_ = [[NSMutableArray array] retain];
	self->sortDescriptors_ = [[NSMutableArray array] retain];
	
	return self;
}

-(void)dealloc {
	[self->context_ release];
	[self->entityDescription_ release];
	[self->predicates_ release];
	[self->sortDescriptors_ release];
	
	[super dealloc];
}

-(id)copyWithZone:(NSZone *)zone {
	Arelish* helper = [[Arelish alloc] init];
	helper->entityDescription_ = [self->entityDescription_ retain];
	helper->context_ = [self->context_ retain];
	
	helper->predicates_ = [self.predicates mutableCopyWithZone:zone];
	helper->sortDescriptors_ = [self.sortDescriptors mutableCopyWithZone:zone];
	helper->limit_ = self->limit_;
	helper->offset_ = self->offset_;
	
	return helper;
}

+(Arelish *)requestHelperWithEntity:(NSString *)entityName context:(NSManagedObjectContext *)context {
	return [[[Arelish alloc] initWithEntity:entityName context:context] autorelease];
}

-(Arelish *)initWithEntity:(NSString *)entityName context:(NSManagedObjectContext *)context {
	self = [self init];
	
	self->context_ = [context retain];
	self->entityDescription_ = [[NSEntityDescription entityForName:entityName inManagedObjectContext:context] retain];
	
	return self;
}

-(NSFetchRequest *)request {
	NSFetchRequest* req = [[[NSFetchRequest alloc] init] autorelease];
	
	[req setEntity:self->entityDescription_];
	[req setPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:self.predicates]];
	[req setSortDescriptors:self.sortDescriptors];
	[req setFetchLimit:self->limit_];
	[req setFetchOffset:self->offset_];
		
	return req;
}

-(NSArray *)fetch {
	return [self->context_ executeFetchRequest:[self request] error:nil];
}

-(Arelish *)where:(NSPredicate *)predicate {
	Arelish* helper = [[self copy] autorelease];
	
	[helper.predicates addObject:predicate];
	
	return helper;
}

-(Arelish *)where:(NSString *)attr is:(id)value {
	if ([[value class] conformsToProtocol:@protocol(NSFastEnumeration)]) {
		return [self where:[NSPredicate predicateWithFormat:@"%K IN %@", attr, value]];
	} else {
		return [self where:[NSPredicate predicateWithFormat:@"%K == %@", attr, value]];
	}
}

-(Arelish *)where:(NSString *)attr IN:(id)firstObj, ... {
	NSMutableArray* array = [NSMutableArray array];
	
	va_list args;
	va_start(args, firstObj);
	
	for (id arg = firstObj; arg != nil; arg = va_arg(args, id)) {
		[array addObject:arg];
	}
	
	va_end(args);
	
	return [self where:attr is:array];
}

-(Arelish *)where:(NSString *)attr equalsToInt:(NSInteger)value {
	return [self where:attr is:[NSNumber numberWithInt:value]];
}

-(Arelish *)order:(NSSortDescriptor *)descr {
	Arelish* helper = [[self copy] autorelease];
	
	[helper.sortDescriptors addObject:descr];
	
	return helper;
}

-(Arelish *)order:(NSString *)attr ascending:(BOOL)ascending {
	return [self order:[NSSortDescriptor sortDescriptorWithKey:attr ascending:ascending]];
}

-(Arelish *)limit:(NSUInteger)limit {
	Arelish* helper = [[self copy] autorelease];
	
	helper->limit_ = limit;
	
	return helper;
	
}

-(Arelish *)offset:(NSUInteger)offset {
	Arelish* helper = [[self copy] autorelease];
	
	helper->offset_ = offset;
	
	return helper;
	
}

@end
