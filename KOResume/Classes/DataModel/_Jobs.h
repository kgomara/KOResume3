// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Jobs.h instead.

#import <CoreData/CoreData.h>


extern const struct JobsAttributes {
	__unsafe_unretained NSString *city;
	__unsafe_unretained NSString *created_date;
	__unsafe_unretained NSString *end_date;
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *sequence_number;
	__unsafe_unretained NSString *start_date;
	__unsafe_unretained NSString *state;
	__unsafe_unretained NSString *summary;
	__unsafe_unretained NSString *title;
	__unsafe_unretained NSString *uri;
} JobsAttributes;

extern const struct JobsRelationships {
	__unsafe_unretained NSString *accomplishment;
	__unsafe_unretained NSString *resume;
} JobsRelationships;

extern const struct JobsFetchedProperties {
} JobsFetchedProperties;

@class Accomplishments;
@class Resumes;












@interface JobsID : NSManagedObjectID {}
@end

@interface _Jobs : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (JobsID*)objectID;





@property (nonatomic, strong) NSString* city;



//- (BOOL)validateCity:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* created_date;



//- (BOOL)validateCreated_date:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* end_date;



//- (BOOL)validateEnd_date:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* name;



//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* sequence_number;



@property int16_t sequence_numberValue;
- (int16_t)sequence_numberValue;
- (void)setSequence_numberValue:(int16_t)value_;

//- (BOOL)validateSequence_number:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* start_date;



//- (BOOL)validateStart_date:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* state;



//- (BOOL)validateState:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* summary;



//- (BOOL)validateSummary:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* title;



//- (BOOL)validateTitle:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* uri;



//- (BOOL)validateUri:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSSet *accomplishment;

- (NSMutableSet*)accomplishmentSet;




@property (nonatomic, strong) Resumes *resume;

//- (BOOL)validateResume:(id*)value_ error:(NSError**)error_;





@end

@interface _Jobs (CoreDataGeneratedAccessors)

- (void)addAccomplishment:(NSSet*)value_;
- (void)removeAccomplishment:(NSSet*)value_;
- (void)addAccomplishmentObject:(Accomplishments*)value_;
- (void)removeAccomplishmentObject:(Accomplishments*)value_;

@end

@interface _Jobs (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveCity;
- (void)setPrimitiveCity:(NSString*)value;




- (NSDate*)primitiveCreated_date;
- (void)setPrimitiveCreated_date:(NSDate*)value;




- (NSDate*)primitiveEnd_date;
- (void)setPrimitiveEnd_date:(NSDate*)value;




- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;




- (NSNumber*)primitiveSequence_number;
- (void)setPrimitiveSequence_number:(NSNumber*)value;

- (int16_t)primitiveSequence_numberValue;
- (void)setPrimitiveSequence_numberValue:(int16_t)value_;




- (NSDate*)primitiveStart_date;
- (void)setPrimitiveStart_date:(NSDate*)value;




- (NSString*)primitiveState;
- (void)setPrimitiveState:(NSString*)value;




- (NSString*)primitiveSummary;
- (void)setPrimitiveSummary:(NSString*)value;




- (NSString*)primitiveTitle;
- (void)setPrimitiveTitle:(NSString*)value;




- (NSString*)primitiveUri;
- (void)setPrimitiveUri:(NSString*)value;





- (NSMutableSet*)primitiveAccomplishment;
- (void)setPrimitiveAccomplishment:(NSMutableSet*)value;



- (Resumes*)primitiveResume;
- (void)setPrimitiveResume:(Resumes*)value;


@end
