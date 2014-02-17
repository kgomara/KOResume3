// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Resumes.h instead.

#import <CoreData/CoreData.h>


extern const struct ResumesAttributes {
	__unsafe_unretained NSString *city;
	__unsafe_unretained NSString *created_date;
	__unsafe_unretained NSString *email;
	__unsafe_unretained NSString *home_phone;
	__unsafe_unretained NSString *mobile_phone;
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *postal_code;
	__unsafe_unretained NSString *sequence_number;
	__unsafe_unretained NSString *state;
	__unsafe_unretained NSString *street1;
	__unsafe_unretained NSString *street2;
	__unsafe_unretained NSString *summary;
} ResumesAttributes;

extern const struct ResumesRelationships {
	__unsafe_unretained NSString *education;
	__unsafe_unretained NSString *job;
	__unsafe_unretained NSString *package;
} ResumesRelationships;

extern const struct ResumesFetchedProperties {
} ResumesFetchedProperties;

@class Education;
@class Jobs;
@class Packages;














@interface ResumesID : NSManagedObjectID {}
@end

@interface _Resumes : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (ResumesID*)objectID;





@property (nonatomic, strong) NSString* city;



//- (BOOL)validateCity:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* created_date;



//- (BOOL)validateCreated_date:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* email;



//- (BOOL)validateEmail:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* home_phone;



//- (BOOL)validateHome_phone:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* mobile_phone;



//- (BOOL)validateMobile_phone:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* name;



//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* postal_code;



//- (BOOL)validatePostal_code:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* sequence_number;



@property int16_t sequence_numberValue;
- (int16_t)sequence_numberValue;
- (void)setSequence_numberValue:(int16_t)value_;

//- (BOOL)validateSequence_number:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* state;



//- (BOOL)validateState:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* street1;



//- (BOOL)validateStreet1:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* street2;



//- (BOOL)validateStreet2:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* summary;



//- (BOOL)validateSummary:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSSet *education;

- (NSMutableSet*)educationSet;




@property (nonatomic, strong) NSSet *job;

- (NSMutableSet*)jobSet;




@property (nonatomic, strong) Packages *package;

//- (BOOL)validatePackage:(id*)value_ error:(NSError**)error_;





@end

@interface _Resumes (CoreDataGeneratedAccessors)

- (void)addEducation:(NSSet*)value_;
- (void)removeEducation:(NSSet*)value_;
- (void)addEducationObject:(Education*)value_;
- (void)removeEducationObject:(Education*)value_;

- (void)addJob:(NSSet*)value_;
- (void)removeJob:(NSSet*)value_;
- (void)addJobObject:(Jobs*)value_;
- (void)removeJobObject:(Jobs*)value_;

@end

@interface _Resumes (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveCity;
- (void)setPrimitiveCity:(NSString*)value;




- (NSDate*)primitiveCreated_date;
- (void)setPrimitiveCreated_date:(NSDate*)value;




- (NSString*)primitiveEmail;
- (void)setPrimitiveEmail:(NSString*)value;




- (NSString*)primitiveHome_phone;
- (void)setPrimitiveHome_phone:(NSString*)value;




- (NSString*)primitiveMobile_phone;
- (void)setPrimitiveMobile_phone:(NSString*)value;




- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;




- (NSString*)primitivePostal_code;
- (void)setPrimitivePostal_code:(NSString*)value;




- (NSNumber*)primitiveSequence_number;
- (void)setPrimitiveSequence_number:(NSNumber*)value;

- (int16_t)primitiveSequence_numberValue;
- (void)setPrimitiveSequence_numberValue:(int16_t)value_;




- (NSString*)primitiveState;
- (void)setPrimitiveState:(NSString*)value;




- (NSString*)primitiveStreet1;
- (void)setPrimitiveStreet1:(NSString*)value;




- (NSString*)primitiveStreet2;
- (void)setPrimitiveStreet2:(NSString*)value;




- (NSString*)primitiveSummary;
- (void)setPrimitiveSummary:(NSString*)value;





- (NSMutableSet*)primitiveEducation;
- (void)setPrimitiveEducation:(NSMutableSet*)value;



- (NSMutableSet*)primitiveJob;
- (void)setPrimitiveJob:(NSMutableSet*)value;



- (Packages*)primitivePackage;
- (void)setPrimitivePackage:(Packages*)value;


@end
