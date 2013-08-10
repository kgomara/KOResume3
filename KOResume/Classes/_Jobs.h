// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Jobs.h instead.

#import <CoreData/CoreData.h>


@class Accomplishments;
@class Resumes;












@interface JobsID : NSManagedObjectID {}
@end

@interface _Jobs : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (JobsID*)objectID;




@property (nonatomic, retain) NSString *city;


//- (BOOL)validateCity:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSDate *created_date;


//- (BOOL)validateCreated_date:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSDate *end_date;


//- (BOOL)validateEnd_date:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSString *name;


//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSNumber *sequence_number;


@property short sequence_numberValue;
- (short)sequence_numberValue;
- (void)setSequence_numberValue:(short)value_;

//- (BOOL)validateSequence_number:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSDate *start_date;


//- (BOOL)validateStart_date:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSString *state;


//- (BOOL)validateState:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSString *summary;


//- (BOOL)validateSummary:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSString *title;


//- (BOOL)validateTitle:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSString *uri;


//- (BOOL)validateUri:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) NSSet* accomplishment;

- (NSMutableSet*)accomplishmentSet;




@property (nonatomic, retain) Resumes* resume;

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

- (short)primitiveSequence_numberValue;
- (void)setPrimitiveSequence_numberValue:(short)value_;




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
