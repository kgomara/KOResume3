// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Education.h instead.

#import <CoreData/CoreData.h>


@class Resumes;









@interface EducationID : NSManagedObjectID {}
@end

@interface _Education : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (EducationID*)objectID;




@property (nonatomic, retain) NSString *city;


//- (BOOL)validateCity:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSDate *created_date;


//- (BOOL)validateCreated_date:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSDate *earned_date;


//- (BOOL)validateEarned_date:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSString *name;


//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSNumber *sequence_number;


@property short sequence_numberValue;
- (short)sequence_numberValue;
- (void)setSequence_numberValue:(short)value_;

//- (BOOL)validateSequence_number:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSString *state;


//- (BOOL)validateState:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSString *title;


//- (BOOL)validateTitle:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) Resumes* resume;

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

- (short)primitiveSequence_numberValue;
- (void)setPrimitiveSequence_numberValue:(short)value_;




- (NSString*)primitiveState;
- (void)setPrimitiveState:(NSString*)value;




- (NSString*)primitiveTitle;
- (void)setPrimitiveTitle:(NSString*)value;





- (Resumes*)primitiveResume;
- (void)setPrimitiveResume:(Resumes*)value;


@end
