// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Packages.h instead.

#import <CoreData/CoreData.h>


extern const struct PackagesAttributes {
	__unsafe_unretained NSString *cover_ltr;
	__unsafe_unretained NSString *created_date;
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *sequence_number;
} PackagesAttributes;

extern const struct PackagesRelationships {
	__unsafe_unretained NSString *resume;
} PackagesRelationships;

extern const struct PackagesFetchedProperties {
} PackagesFetchedProperties;

@class Resumes;






@interface PackagesID : NSManagedObjectID {}
@end

@interface _Packages : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (PackagesID*)objectID;





@property (nonatomic, strong) NSString* cover_ltr;



//- (BOOL)validateCover_ltr:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* created_date;



//- (BOOL)validateCreated_date:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* name;



//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* sequence_number;



@property int16_t sequence_numberValue;
- (int16_t)sequence_numberValue;
- (void)setSequence_numberValue:(int16_t)value_;

//- (BOOL)validateSequence_number:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) Resumes *resume;

//- (BOOL)validateResume:(id*)value_ error:(NSError**)error_;





@end

@interface _Packages (CoreDataGeneratedAccessors)

@end

@interface _Packages (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveCover_ltr;
- (void)setPrimitiveCover_ltr:(NSString*)value;




- (NSDate*)primitiveCreated_date;
- (void)setPrimitiveCreated_date:(NSDate*)value;




- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;




- (NSNumber*)primitiveSequence_number;
- (void)setPrimitiveSequence_number:(NSNumber*)value;

- (int16_t)primitiveSequence_numberValue;
- (void)setPrimitiveSequence_numberValue:(int16_t)value_;





- (Resumes*)primitiveResume;
- (void)setPrimitiveResume:(Resumes*)value;


@end
