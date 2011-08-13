//
//  UBCoreDataMigrationHelper.h
//  CoreDataManagerSample
//
//  Created by 宗太郎 松本 on 11/08/13.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UBCoreDataMigrationHelper;

@protocol UBCoreDataMigrationListener

-(void) migrationWillStart:(UBCoreDataMigrationHelper*)helper count:(NSInteger)count;

-(void) migrationStepWillStart:(UBCoreDataMigrationHelper*)helper srcModel:(NSDictionary*)srcModel destModel:(NSDictionary*)descModel;
-(void) migrationStepDidSuccess:(UBCoreDataMigrationHelper*)helper;
-(void) migrationStepDidFailure:(UBCoreDataMigrationHelper*)helper error:(NSError*)error;

-(void) migrationDidSuccess:(UBCoreDataMigrationHelper*)helper;
-(void) migrationDidFailure:(UBCoreDataMigrationHelper*)helper;

@end

@interface UBCoreDataMigrationHelper : NSObject {
	NSURL* storeURL_;
	NSMutableArray* models_;
	NSInteger currentIndex_;
	NSMutableArray* edges_;
}

@property (nonatomic, readonly) NSURL* storeURL;
@property (nonatomic, readonly) NSInteger modelsCount;
@property (nonatomic, readonly) NSInteger currentIndex;
@property (nonatomic, readonly) NSMutableArray* edges;

#pragma mark -

+(UBCoreDataMigrationHelper*) migrationHelperWithURL:(NSURL*)url;

#pragma mark -

-(id) initWithURL:(NSURL*)url;

-(NSManagedObjectModel*) modelAtIndex:(NSUInteger)index;
-(NSString*) modelPathAtIndex:(NSUInteger)index;
-(NSString*) modelNameAtIndex:(NSUInteger)index;

-(NSArray*) pathFromCurrentModel;
-(NSArray*) pathFrom:(NSInteger)modelIndex;

-(void) runMigration:(id<UBCoreDataMigrationListener>)listener;

@end
