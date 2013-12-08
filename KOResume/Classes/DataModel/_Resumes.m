// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Resumes.m instead.

#import "_Resumes.h"

@implementation ResumesID
@end

@implementation _Resumes

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Resumes" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Resumes";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Resumes" inManagedObjectContext:moc_];
}

- (ResumesID*)objectID {
	return (ResumesID*)[super objectID];
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






@dynamic email;






@dynamic home_phone;






@dynamic mobile_phone;






@dynamic name;






@dynamic postal_code;






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





@dynamic state;






@dynamic street1;






@dynamic street2;






@dynamic summary;






@dynamic education;

	
- (NSMutableSet*)educationSet {
	[self willAccessValueForKey:@"education"];
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"education"];
	[self didAccessValueForKey:@"education"];
	return result;
}
	

@dynamic job;

	
- (NSMutableSet*)jobSet {
	[self willAccessValueForKey:@"job"];
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"job"];
	[self didAccessValueForKey:@"job"];
	return result;
}
	

@dynamic package;

	





@end
