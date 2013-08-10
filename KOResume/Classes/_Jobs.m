// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Jobs.m instead.

#import "_Jobs.h"

@implementation JobsID
@end

@implementation _Jobs

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Jobs" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Jobs";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Jobs" inManagedObjectContext:moc_];
}

- (JobsID*)objectID {
	return (JobsID*)[super objectID];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"sequence_numberValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"sequence_number"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}

	return keyPaths;
}




@dynamic city;






@dynamic created_date;






@dynamic end_date;






@dynamic name;






@dynamic sequence_number;



- (short)sequence_numberValue {
	NSNumber *result = [self sequence_number];
	return [result shortValue];
}

- (void)setSequence_numberValue:(short)value_ {
	[self setSequence_number:[NSNumber numberWithShort:value_]];
}

- (short)primitiveSequence_numberValue {
	NSNumber *result = [self primitiveSequence_number];
	return [result shortValue];
}

- (void)setPrimitiveSequence_numberValue:(short)value_ {
	[self setPrimitiveSequence_number:[NSNumber numberWithShort:value_]];
}





@dynamic start_date;






@dynamic state;






@dynamic summary;






@dynamic title;






@dynamic uri;






@dynamic accomplishment;

	
- (NSMutableSet*)accomplishmentSet {
	[self willAccessValueForKey:@"accomplishment"];
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"accomplishment"];
	[self didAccessValueForKey:@"accomplishment"];
	return result;
}
	

@dynamic resume;

	





@end
