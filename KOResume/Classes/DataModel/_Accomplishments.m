// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Accomplishments.m instead.

#import "_Accomplishments.h"

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

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"sequence_numberValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"sequence_number"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}

	return keyPaths;
}




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





@dynamic summary;






@dynamic job;

	





@end
