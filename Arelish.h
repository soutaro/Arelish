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

#import <Foundation/Foundation.h>


@interface Arelish : NSObject<NSCopying> {
	NSManagedObjectContext* context_;
	NSEntityDescription* entityDescription_;
	
	NSMutableArray* predicates_;
	NSMutableArray* sortDescriptors_;
	NSUInteger limit_;
	NSUInteger offset_;
}

@property (nonatomic, readonly) NSMutableArray* predicates;
@property (nonatomic, readonly) NSMutableArray* sortDescriptors;

+(Arelish*) requestHelperWithEntity:(NSString*)entityName context:(NSManagedObjectContext*)context;

-(Arelish*) initWithEntity:(NSString*)entityName context:(NSManagedObjectContext*)context;
-(NSFetchRequest*) request;
-(NSArray*) fetch;

-(Arelish*) where:(NSPredicate*)predicate;
-(Arelish*) where:(NSString*)attr is:(id)value;
-(Arelish*) where:(NSString*)attr IN:(id)firstObj, ... NS_REQUIRES_NIL_TERMINATION;
-(Arelish*) where:(NSString*)attr equalsToInt:(NSInteger)value;

-(Arelish*) order:(NSSortDescriptor*)descr;
-(Arelish*) order:(NSString*)attr ascending:(BOOL)ascending;

-(Arelish*) limit:(NSUInteger)limit;
-(Arelish*) offset:(NSUInteger)offset;

@end
