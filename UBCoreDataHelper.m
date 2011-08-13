//
//  UBCoreDataHelper.m
//  CoreDataManagerSample
//
//  Created by 宗太郎 松本 on 11/08/13.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "UBCoreDataHelper.h"

@implementation UBCoreDataHelper

#pragma mark - Singleton

-(oneway void) release {
	// なにもしない
}

-(id) retain {
	// なにもしない
    return self;
}

-(unsigned) retainCount {
	// 減らない
    return UINT_MAX;
}

-(id) autorelease {
	// なにもしない
    return self;
}

#pragma mark - Class Methods

static UBCoreDataHelper* sharedInstance = nil;

+(UBCoreDataHelper *)sharedInstance {
	@synchronized (self) {
		if (sharedInstance == nil) {
			sharedInstance = [[UBCoreDataHelper alloc] init];
		}
	}
	return sharedInstance;
}

#pragma mark -

- (id)init
{
    self = [super init];
    if (self) {
		NSArray *sqlitePaths = [[NSBundle mainBundle] pathsForResourcesOfType:@"sqlite" inDirectory:nil];
		if ([sqlitePaths count] > 0) {
			self.storeURL = [NSURL fileURLWithPath:[sqlitePaths objectAtIndex:0]];
		}
	}
    
    return self;
}

#pragma mark - Properties

-(NSManagedObjectContext *)managedObjectContext {
	if (self->managedObjectContext_) {
		return self->managedObjectContext_;
	}
	
	NSPersistentStoreCoordinator *coordinator = self.persistentStoreCoordinator;
	if (coordinator) {
		managedObjectContext_ = [[NSManagedObjectContext alloc] init];
		[managedObjectContext_ setPersistentStoreCoordinator:coordinator];
	}
	
	return managedObjectContext_;
}

-(NSManagedObjectModel *)managedObjectModel {
	if (self->managedObjectModel_){
		return self->managedObjectModel_;
	}
	
	self->managedObjectModel_ = [[NSManagedObjectModel mergedModelFromBundles:[NSArray arrayWithObject:[NSBundle mainBundle]]] retain];
	
	//NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"CoreDataMigration" withExtension:@"momd"];
	//self->managedObjectModel_ = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
	
	return self->managedObjectModel_;
}

-(NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	if (self->persistentStoreCoordinator_) {
        return self->persistentStoreCoordinator_;
    }
    
    NSURL *storeURL = self.storeURL;
    NSError *error = nil;
	
	self->persistentStoreCoordinator_ = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![self->persistentStoreCoordinator_ addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
    {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return self->persistentStoreCoordinator_;
}

-(NSDictionary *)storeMetadata {
	return [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType URL:self.storeURL error:nil];
}

-(NSURL *)storeURL {
	return self->storeURL_;
}

-(void)setStoreURL:(NSURL *)storeURL {
	[self->storeURL_ autorelease];
	self->storeURL_ = [storeURL retain];
	
	[self->persistentStoreCoordinator_ autorelease];
	[self->managedObjectModel_ autorelease];
	[self->managedObjectContext_ autorelease];
	
	self->persistentStoreCoordinator_ = nil;
	self->managedObjectModel_ = nil;
	self->managedObjectContext_ = nil;
}

#pragma mark -

#pragma mark -

-(BOOL) isMigrationRequired {
	NSError* error = nil;
	NSDictionary* sourceMetaData = self.storeMetadata;
	
	if (error) {
		NSLog(@"Checking migration was failed (%@, %@)", error, [error userInfo]);
		abort();
	}
	
	if (sourceMetaData && ![self.managedObjectModel isConfiguration:nil compatibleWithStoreMetadata:sourceMetaData]) {
		return YES;
	} else {
		return NO;
	}
}

-(void)save {
	NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

@end
