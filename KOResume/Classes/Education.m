#import "Education.h"
#import "Resumes.h"

@implementation Education

NSString *const OCREducationEntity        = @"Education";

-(void)logAllFields
{
    DLog();
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle: NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle: NSDateFormatterNoStyle];
    
    NSLog(@"======================= Education =======================");
    NSLog(@"   name              = %@", self.name);
    NSLog(@"   created_date      = %@", [dateFormatter stringFromDate: self.created_date]);
    NSLog(@"   sequence_number   = %@", [self.sequence_number stringValue]);
    NSLog(@"   in resume         = %@", self.resume.name);
    NSLog(@"   title             = %@", self.title);
    NSLog(@"   earned_date       = %@", [dateFormatter stringFromDate: self.earned_date]);
    NSLog(@"   city              = %@", self.city);
    NSLog(@"   state             = %@", self.state);
    NSLog(@"===================== end Education =====================");
    
}

@end
