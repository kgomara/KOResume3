#import "Education.h"
#import "Resumes.h"

@implementation Education

NSString *const OCREducationEntity        = @"Education";

//----------------------------------------------------------------------------------------------------------
- (NSString *)debugDescription
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle: NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle: NSDateFormatterNoStyle];
    
    NSString *result = [NSString stringWithFormat:@"%@\n", self];
    
    result = [result stringByAppendingFormat: @"   name              = %@\n", self.name];
    result = [result stringByAppendingFormat: @"   created_date      = %@\n", [dateFormatter stringFromDate: self.created_date]];
    result = [result stringByAppendingFormat: @"   sequence_number   = %@\n", [self.sequence_number stringValue]];
    result = [result stringByAppendingFormat: @"   in resume         = %@\n", self.resume.name];
    result = [result stringByAppendingFormat: @"   title             = %@\n", self.title];
    result = [result stringByAppendingFormat: @"   earned_date       = %@\n", [dateFormatter stringFromDate: self.earned_date]];
    result = [result stringByAppendingFormat: @"   city              = %@\n", self.city];
    result = [result stringByAppendingFormat: @"   state             = %@",   self.state];
    
    return result;
}

@end
