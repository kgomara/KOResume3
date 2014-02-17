// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Education.h instead.

#import <CoreData/CoreData.h>


extern const struct EducationAttributes {
	__unsafe_unretained NSString *city;
	__unsafe_unretained NSString *created_date;
	__unsafe_unretained NSString *earned_date;
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *sequence_number;
	__unsafe_unretained NSString *state;
	__unsafe_unretained NSString *title;
} EducationAttributes;

extern const struct EducationRelationships {
	__unsafe_unretained NSString *resume;
} EducationRelationships;

extern const struct EducationFetchedProperties {
} EducationFetchedProperties;

@class Resumes;









@interface EducationID : NSManagedObjectID {}
@end

@interface _Education : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (EducationID*)objectID;





@property (nonatomic, strong) NSString* city;



//- (BOOL)validateCity:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* created_date;



//- (BOOL)validateCreated_date:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* earned_date;



//- (BOOL)validateEarned_date:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* name;



//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* sequence_number;



@property int16_t sequence_numberValue;
- (int16_t)sequence_numberValue;
- (void)setSequence_numberValue:(int16_t)value_;

//- (BOOL)validateSequence_number:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* state;



//- (BOOL)validateState:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* title;



//- (BOOL)validateTitle:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) Resumes *resume;

//- (BOOL)validateResume:(id*)value_ error:(NSError**)error_;





@end

@interface _Education (CoreDataGeneratedAccessors)

@end

@interface _Education (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveCity;
- (void)setPrimitiveCity:(NSString*)value;




- (NSDate*)primitiveCreated_date;
- (void)setPrimitiveCreated_date:(NSDate*)value;




- (NSDate*)primitiveEarned_date;
- (void)setPrimitiveEarned_date:(NSDate*)value;




- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;




- (NSNumber*)primitiveSequence_number;
- (void)setPrimitiveSequence_number:(NSNumber*)value;

- (int16_t)primitiveSequence_numberValue;
- (void)setPrimitiveSequence_numberValue:(int16_t)value_;




- (NSString*)primitiveState;
- (void)setPrimitiveState:(NSString*)value;




- (NSString*)primitiveTitle;
- (void)setPrimitiveTitle:(NSString*)value;





- (Resumes*)primitiveResume;
- (void)setPrimitiveResume:(Resumes*)value;


@end
