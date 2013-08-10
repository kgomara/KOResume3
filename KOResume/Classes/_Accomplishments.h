// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Accomplishments.h instead.

#import <CoreData/CoreData.h>


@class Jobs;






@interface AccomplishmentsID : NSManagedObjectID {}
@end

@interface _Accomplishments : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (AccomplishmentsID*)objectID;




@property (nonatomic, retain) NSDate *created_date;


//- (BOOL)validateCreated_date:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSString *name;


//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSNumber *sequence_number;


@property short sequence_numberValue;
- (short)sequence_numberValue;
- (void)setSequence_numberValue:(short)value_;

//- (BOOL)validateSequence_number:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSString *summary;


//- (BOOL)validateSummary:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) Jobs* job;

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

- (short)primitiveSequence_numberValue;
- (void)setPrimitiveSequence_numberValue:(short)value_;




- (NSString*)primitiveSummary;
- (void)setPrimitiveSummary:(NSString*)value;





- (Jobs*)primitiveJob;
- (void)setPrimitiveJob:(Jobs*)value;


@end
