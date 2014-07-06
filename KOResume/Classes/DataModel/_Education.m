// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Education.m instead.

#import "_Education.h"

const struct EducationAttributes EducationAttributes = {
	.city = @"city",
	.created_date = @"created_date",
	.earned_date = @"earned_date",
	.name = @"name",
	.sequence_number = @"sequence_number",
	.state = @"state",
	.title = @"title",
};

const struct EducationRelationships EducationRelationships = {
	.resume = @"resume",
};

const struct EducationFetchedProperties EducationFetchedProperties = {
};

@implementation EducationID
@end

@implementation _Education

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Education" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Education";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Education" inManagedObjectContext:moc_];
}

- (EducationID*)objectID {
	return (EducationID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"sequence_numberValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"sequence_number"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}




@dynamic city;






@dynamic created_date;






@dynamic earned_date;






@dynamic name;






@dynamic sequence_number;



- (int16_t)sequence_numberValue {
	NSNumber *result = [self sequence_number];
	return [result shortValue];
}

- (void)setSequence_numberValue:(int16_t)value_ {
	[self setSequence_number:@(value_)];
}

- (int16_t)primitiveSequence_numberValue {
	NSNumber *result = [self primitiveSequence_number];
	return [result shortValue];
}

- (void)setPrimitiveSequence_numberValue:(int16_t)value_ {
	[self setPrimitiveSequence_number:@(value_)];
}





@dynamic state;






@dynamic title;






@dynamic resume;

	






@end
