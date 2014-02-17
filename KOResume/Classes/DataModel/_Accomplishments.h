// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Accomplishments.h instead.

#import <CoreData/CoreData.h>


extern const struct AccomplishmentsAttributes {
	__unsafe_unretained NSString *created_date;
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *sequence_number;
	__unsafe_unretained NSString *summary;
} AccomplishmentsAttributes;

extern const struct AccomplishmentsRelationships {
	__unsafe_unretained NSString *job;
} AccomplishmentsRelationships;

extern const struct AccomplishmentsFetchedProperties {
} AccomplishmentsFetchedProperties;

@class Jobs;






@interface AccomplishmentsID : NSManagedObjectID {}
@end

@interface _Accomplishments : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (AccomplishmentsID*)objectID;





@property (nonatomic, strong) NSDate* created_date;



//- (BOOL)validateCreated_date:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* name;



//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* sequence_number;



@property int16_t sequence_numberValue;
- (int16_t)sequence_numberValue;
- (void)setSequence_numberValue:(int16_t)value_;

//- (BOOL)validateSequence_number:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* summary;



//- (BOOL)validateSummary:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) Jobs *job;

//- (BOOL)validateJob:(id*)value_ error:(NSError**)error_;





@end

@interface _Accomplishments (CoreDataGeneratedAccessors)

@end

@interface _Accomplishments (CoreDataGeneratedPrimitiveAccessors)


- (NSDate*)primitiveCreated_date;
- (void)setPrimitiveCreated_date:(NSDate*)value;




- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;




- (NSNumber*)primitiveSequence_number;
- (void)setPrimitiveSequence_number:(NSNumber*)value;

- (int16_t)primitiveSequence_numberValue;
- (void)setPrimitiveSequence_numberValue:(int16_t)value_;




- (NSString*)primitiveSummary;
- (void)setPrimitiveSummary:(NSString*)value;





- (Jobs*)primitiveJob;
- (void)setPrimitiveJob:(Jobs*)value;


@end
