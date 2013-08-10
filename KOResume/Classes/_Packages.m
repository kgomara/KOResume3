// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Packages.m instead.

#import "_Packages.h"

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

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"sequence_numberValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"sequence_number"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}

	return keyPaths;
}




@dynamic cover_ltr;






@dynamic created_date;






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





@dynamic resume;

	





@end
