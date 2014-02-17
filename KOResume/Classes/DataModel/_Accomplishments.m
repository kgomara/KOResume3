// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Accomplishments.m instead.

#import "_Accomplishments.h"

const struct AccomplishmentsAttributes AccomplishmentsAttributes = {
	.created_date = @"created_date",
	.name = @"name",
	.sequence_number = @"sequence_number",
	.summary = @"summary",
};

const struct AccomplishmentsRelationships AccomplishmentsRelationships = {
	.job = @"job",
};

const struct AccomplishmentsFetchedProperties AccomplishmentsFetchedProperties = {
};

@implementation AccomplishmentsID
@end

@implementation _Accomplishments

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Accomplishments" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Accomplishments";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Accomplishments" inManagedObjectContext:moc_];
}

- (AccomplishmentsID*)objectID {
	return (AccomplishmentsID*)[super objectID];
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




@dynamic created_date;






@dynamic name;






@dynamic sequence_number;



- (int16_t)sequence_numberValue {
	NSNumber *result = [self sequence_number];
	return [result shortValue];
}

- (void)setSequence_numberValue:(int16_t)value_ {
	[self setSequence_number:[NSNumber numberWithShort:value_]];
}

- (int16_t)primitiveSequence_numberValue {
	NSNumber *result = [self primitiveSequence_number];
	return [result shortValue];
}

- (void)setPrimitiveSequence_numberValue:(int16_t)value_ {
	[self setPrimitiveSequence_number:[NSNumber numberWithShort:value_]];
}





@dynamic summary;






@dynamic job;

	






@end
