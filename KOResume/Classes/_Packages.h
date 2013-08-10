// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Packages.h instead.

#import <CoreData/CoreData.h>


@class Resumes;






@interface PackagesID : NSManagedObjectID {}
@end

@interface _Packages : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (PackagesID*)objectID;




@property (nonatomic, retain) NSString *cover_ltr;


//- (BOOL)validateCover_ltr:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSDate *created_date;


//- (BOOL)validateCreated_date:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSString *name;


//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSNumber *sequence_number;


@property short sequence_numberValue;
- (short)sequence_numberValue;
- (void)setSequence_numberValue:(short)value_;

//- (BOOL)validateSequence_number:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) Resumes* resume;

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

- (short)primitiveSequence_numberValue;
- (void)setPrimitiveSequence_numberValue:(short)value_;





- (Resumes*)primitiveResume;
- (void)setPrimitiveResume:(Resumes*)value;


@end
