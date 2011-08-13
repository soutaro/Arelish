//
//  UBCoreDataMigrationHelper.m
//  CoreDataManagerSample
//
//  Created by 宗太郎 松本 on 11/08/13.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "UBCoreDataMigrationHelper.h"

@interface Edge : NSObject {
    NSInteger srcNode_;
	NSInteger destNode_;
	NSMappingModel* mapping_;
}

@property (nonatomic, readonly) NSInteger srcNode;
@property (nonatomic, readonly) NSInteger destNode;
@property (nonatomic, readonly) NSMappingModel* mapping;

+(Edge*) edgeWithMappingModel:(NSMappingModel*)mapping src:(NSInteger)srcNode dest:(NSInteger)destNode;
-(Edge*) initWithMappingModel:(NSMappingModel*)mapping src:(NSInteger)srcNode dest:(NSInteger)destNode;

@end

@implementation Edge

@synthesize srcNode=srcNode_;
@synthesize destNode=destNode_;
@synthesize mapping=mapping_;

-(void)dealloc {
	[self.mapping release];
	[super dealloc];
}

+(Edge *)edgeWithMappingModel:(NSMappingModel *)mapping src:(NSInteger)srcNode dest:(NSInteger)destNode {
	return [[[self alloc] initWithMappingModel:mapping src:srcNode dest:destNode] autorelease];
}

-(Edge *)initWithMappingModel:(NSMappingModel *)mapping src:(NSInteger)srcNode dest:(NSInteger)destNode {
	self = [self init];
	
	self->mapping_ = [mapping retain];
	self->srcNode_ = srcNode;
	self->destNode_ = destNode;
	
	return self;
}

-(NSString *)description {
	return [NSString stringWithFormat:@"Edge:: %d => %d (%@)", self.srcNode, self.destNode, self.mapping];
}

@end

@interface UBCoreDataMigrationHelper ()

@property (nonatomic, retain) NSMutableArray* models;

-(void) loadModels;
-(void) loadMappings;
-(void) identifyCurrentModel;
-(void) constructPath:(NSMutableArray*)path start:(NSInteger)index;
-(NSArray*) compactPath:(NSMutableArray*)path;

-(Edge*) edgeForSrc:(NSInteger)src dest:(NSInteger)dest;
-(Edge*) edgeForSrc:(NSInteger)src;

-(BOOL) runMigration:(id<UBCoreDataMigrationListener>)listener step:(Edge*)edge;

@end

@implementation UBCoreDataMigrationHelper

@synthesize storeURL=storeURL_;
@synthesize models=models_;
@synthesize currentIndex=currentIndex_;
@synthesize edges=edges_;

- (id)init
{
    self = [super init];
    if (self) {
		self.models = [NSMutableArray array];
		self->edges_ = [[NSMutableArray array] retain];
    }
    
    return self;
}

-(void)dealloc {
	[self.storeURL release];
	[self.models release];
	[self.edges release];
	
	[super dealloc];
}

#pragma mark -

+(UBCoreDataMigrationHelper *)migrationHelperWithURL:(NSURL *)url {
	return [[[self alloc] initWithURL:url] autorelease];
}

#pragma mark - Properties

-(NSInteger)modelsCount {
	return [self.models count];
}

#pragma mark - Public

-(id)initWithURL:(NSURL *)url {
	self = [self init];
	
	self->storeURL_ = [url retain];
	
	[self loadModels];
	[self loadMappings];
	[self identifyCurrentModel];
	
	return self;
}

-(NSManagedObjectModel *)modelAtIndex:(NSUInteger)index {
	return [[self.models objectAtIndex:index] valueForKey:@"model"];
}

-(NSString *)modelPathAtIndex:(NSUInteger)index {
	return [[self.models objectAtIndex:index] valueForKey:@"path"];
}

-(NSString *)modelNameAtIndex:(NSUInteger)index {
	return [[self.models objectAtIndex:index] valueForKey:@"name"];
}

#pragma mark - Edges

-(Edge *)edgeForSrc:(NSInteger)src dest:(NSInteger)dest {
	for (Edge* edge in self.edges) {
		if (edge.srcNode == src && edge.destNode == dest) {
			return edge;
		}
	}
	return nil;
}

-(Edge *)edgeForSrc:(NSInteger)src {
	for (NSInteger dest = self.modelsCount-1; dest > src; dest--) {
		Edge* e = [self edgeForSrc:src dest:dest];
		if (e) {
			return e;
		}
	}
	
	return nil;
}

#pragma mark - Privates

-(void)loadModels {
	NSMutableArray *modelPaths = [NSMutableArray array];
	NSArray* otherModels = [[NSBundle mainBundle] pathsForResourcesOfType:@"mom" inDirectory:nil];
	[modelPaths addObjectsFromArray:otherModels];
	
	NSArray *momdArray = [[NSBundle mainBundle] pathsForResourcesOfType:@"momd" inDirectory:nil];
	for (NSString *momdPath in momdArray) {
		NSString *resourceSubpath = [momdPath lastPathComponent];
		NSArray *array = [[NSBundle mainBundle] pathsForResourcesOfType:@"mom" inDirectory:resourceSubpath];
		[modelPaths addObjectsFromArray:array];
	}
	
	modelPaths = [[modelPaths sortedArrayUsingComparator:^(id a, id b) {
		NSString* x = a;
		x = [[x stringByReplacingOccurrencesOfString:@"." withString:@"0"] stringByReplacingOccurrencesOfString:@" " withString:@""];
		NSString* y = b;
		y = [[y stringByReplacingOccurrencesOfString:@"." withString:@"0"] stringByReplacingOccurrencesOfString:@" " withString:@""];
		return [x compare:y options:NSNumericSearch];
	}] mutableCopy];
	
	for (NSString* path in modelPaths) {
		NSManagedObjectModel* model = [[[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path]] autorelease];
		NSString* name = [[path lastPathComponent] stringByDeletingPathExtension];
		
		NSDictionary* dic = [NSDictionary dictionaryWithObjectsAndKeys:path, @"path", name, @"name", model, @"model", nil];
		[self.models addObject:dic];
	}
}

-(void) loadMappings {
	NSInteger count = self.modelsCount;
	
	for (NSInteger i = 0; i < count-1; i++) {
		NSManagedObjectModel* m1 = [self modelAtIndex:i];
		
		BOOL mappingFound = NO;
		
		for (NSInteger j = count-1; i < j; j--) {
			NSManagedObjectModel* m2 = [self modelAtIndex:j];
			
			NSMappingModel* map = [NSMappingModel mappingModelFromBundles:nil forSourceModel:m1	destinationModel:m2];
			if (map) {
				Edge* edge = [Edge edgeWithMappingModel:map src:i dest:j];
				[self.edges addObject:edge];
				mappingFound = YES;
				break;
			}
		}
		
		if (!mappingFound) {
			Edge* edge = [Edge edgeWithMappingModel:nil src:i dest:i+1];
			[self.edges addObject:edge];
		}
	}
}

-(void)identifyCurrentModel {
	NSDictionary* metadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType URL:self.storeURL error:nil];
	NSManagedObjectModel *model = [NSManagedObjectModel mergedModelFromBundles:nil forStoreMetadata:metadata];
	
	for (NSUInteger i = 0; i < self.modelsCount; i++) {
		NSManagedObjectModel* m = [self modelAtIndex:i];
		if ([m isEqual:model]) {
			currentIndex_ = i;
			return;
		}
	}
	
	// Error
	NSAssert(NO, @"No current model found");
}

-(NSArray *)pathFromCurrentModel {
	return [self pathFrom:self.currentIndex];
}

-(NSArray *)pathFrom:(NSInteger)currentIndex {
	NSMutableArray* path = [NSMutableArray array];
	
	[self constructPath:path start:currentIndex];
	return [self compactPath:path];
}

-(void)constructPath:(NSMutableArray*)path start:(NSInteger)index {
	NSInteger from = index;
	
	while (from != self.modelsCount-1) {
		Edge* e = [self edgeForSrc:from];
		[path addObject:e];
		from = e.destNode;
	}
}

-(NSArray*)compactPath:(NSMutableArray*)path {
	NSInteger pathLength = [path count];
	
	if (pathLength == 0) {
		return path;
	}
	
	NSMutableArray* compactPath = [NSMutableArray array];
	
	Edge* firstEdge = [path objectAtIndex:0];
	
	[compactPath addObject:firstEdge];
	BOOL skipLast = firstEdge.mapping == nil;
	
	for (NSInteger i = 1; i < pathLength; i++) {
		Edge* e = [path objectAtIndex:i];
		if (e.mapping) {
			[compactPath addObject:e];
			skipLast = NO;
		} else {
			if (skipLast) {
				Edge* e2 = [compactPath lastObject];
				[compactPath removeLastObject];
				Edge* e3 = [Edge edgeWithMappingModel:nil src:e2.srcNode dest:e.destNode];
				[compactPath addObject:e3];
			} else {
				[compactPath addObject:e];
			}
			skipLast = YES;
		}
	}
	
	return compactPath;
}

-(void)runMigration:(id<UBCoreDataMigrationListener>)listener {
	NSArray* path = [self pathFromCurrentModel];
	
	[listener migrationWillStart:self count:[path count]];
	
	for (Edge* edge in path) {
		if (![self runMigration:listener step:edge]) {
			[listener migrationDidFailure:self];
			return;
		}
	}
	
	[listener migrationDidSuccess:self];
}

-(BOOL)runMigration:(id<UBCoreDataMigrationListener>)listener step:(Edge *)edge {
	NSError** error = nil;
	
	[listener migrationStepWillStart:self srcModel:[self.models objectAtIndex:edge.srcNode] destModel:[self.models objectAtIndex:edge.destNode]];
	
	NSManagedObjectModel* srcModel = [self modelAtIndex:edge.srcNode];
	NSManagedObjectModel* destModel = [self modelAtIndex:edge.destNode];
	
	NSMappingModel* mappingModel = edge.mapping;
	if (!mappingModel) {
		mappingModel = [NSMappingModel inferredMappingModelForSourceModel:srcModel destinationModel:destModel error:error];
		if (!mappingModel) {
			[listener migrationStepDidFailure:self error:*error];
			return NO;
		}
	}
	
	NSMigrationManager *manager = [[[NSMigrationManager alloc] initWithSourceModel:srcModel destinationModel:destModel] autorelease];
	
	NSString *modelName = [self modelNameAtIndex:edge.destNode];
	NSString *storeExtension = [[self.storeURL path] pathExtension];
	NSString *storePath = [[self.storeURL path] stringByDeletingPathExtension];
	
	storePath = [NSString stringWithFormat:@"%@.%@.%@", storePath, modelName, storeExtension];
	NSURL *destinationStoreURL = [NSURL fileURLWithPath:storePath];
	
	BOOL result;
	
	@try {
		result = [manager migrateStoreFromURL:self.storeURL
										 type:NSSQLiteStoreType
									  options:nil 
							 withMappingModel:mappingModel 
							 toDestinationURL:destinationStoreURL 
							  destinationType:NSSQLiteStoreType 
						   destinationOptions:nil 
										error:error];
	}
	@catch (NSException *exception) {
		NSError* err = [NSError errorWithDomain:@"UBCoreDataMigrationHelper" code:0 userInfo:[NSDictionary dictionaryWithObject:exception forKey:@"exception"]];
		[listener migrationStepDidFailure:self error:err];
	}
	@finally {
		// nothing to do
	}
	
	if (!result) {
		[listener migrationStepDidFailure:self error:*error];
		return NO;
	}
	
	NSString *guid = [[NSProcessInfo processInfo] globallyUniqueString];
	guid = [guid stringByAppendingPathExtension:modelName];
	guid = [guid stringByAppendingPathExtension:storeExtension];
	NSString *appSupportPath = [storePath stringByDeletingLastPathComponent];
	NSString *backupPath = [appSupportPath stringByAppendingPathComponent:guid];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if (![fileManager moveItemAtPath:[self.storeURL path] toPath:backupPath error:error]) {
		[listener migrationStepDidFailure:self error:*error];
		return NO;
	}
	
	if (![fileManager moveItemAtPath:storePath toPath:[self.storeURL path] error:error]) {
		[listener migrationStepDidFailure:self error:*error];
		[fileManager moveItemAtPath:backupPath toPath:[self.storeURL path] error:nil];
		return NO;
	}
	
	[listener migrationStepDidSuccess:self];
	return YES;
}

@end
