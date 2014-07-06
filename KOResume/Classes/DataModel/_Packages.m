// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Packages.m instead.

#import "_Packages.h"

const struct PackagesAttributes PackagesAttributes = {
	.cover_ltr = @"cover_ltr",
	.created_date = @"created_date",
	.name = @"name",
	.sequence_number = @"sequence_number",
};

const struct PackagesRelationships PackagesRelationships = {
	.resume = @"resume",
};

const struct PackagesFetchedProperties PackagesFetchedProperties = {
};

@implementation PackagesID
@end

@implementation _Packages

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Packages" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Packages";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Packages" inManagedObjectContext:moc_];
}

- (PackagesID*)objectID {
	return (PackagesID*)[super objectID];
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




@dynamic cover_ltr;






@dynamic created_date;






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





@dynamic resume;

	






@end
