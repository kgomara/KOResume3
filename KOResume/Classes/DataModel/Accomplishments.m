#import "Accomplishments.h"
#import "Jobs.h"

@implementation Accomplishments

NSString *const kOCRAccomplishmentsEntity = @"Accomplishments";

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
    result = [result stringByAppendingFormat: @"   in job            = %@\n", self.job.name];
    result = [result stringByAppendingFormat: @"   summary           = %@",   [self.summary first30]];
    
    return result;
}

@end
