//
//  UBCoreDataHelper.h
//  CoreDataManagerSample
//
//  Created by 宗太郎 松本 on 11/08/13.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface UBCoreDataHelper : NSObject {
	NSManagedObjectContext* managedObjectContext_;
	NSManagedObjectModel* managedObjectModel_;
	NSPersistentStoreCoordinator* persistentStoreCoordinator_;
	NSURL* storeURL_;
}

#pragma mark -

+(UBCoreDataHelper*) sharedInstance;

#pragma mark -

@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain) NSURL* storeURL;
@property (nonatomic, readonly) NSDictionary* storeMetadata;

#pragma mark -

-(void) save;
-(BOOL) isMigrationRequired;

@end
