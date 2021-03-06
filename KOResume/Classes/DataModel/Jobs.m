#import "Jobs.h"
#import "Resumes.h"
#import "Accomplishments.h"

@implementation Jobs

NSString *const kOCRJobsEntity = @"Jobs";

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
    result = [result stringByAppendingFormat: @"   uri               = %@\n", self.uri];
    result = [result stringByAppendingFormat: @"   city              = %@\n", self.city];
    result = [result stringByAppendingFormat: @"   state             = %@\n", self.state];
    result = [result stringByAppendingFormat: @"   title             = %@\n", self.title];
    result = [result stringByAppendingFormat: @"   start_date        = %@\n", [dateFormatter stringFromDate: self.start_date]];
    result = [result stringByAppendingFormat: @"   end_date          = %@\n", [dateFormatter stringFromDate: self.end_date]];
    result = [result stringByAppendingFormat: @"   summary           = %@\n", [self.summary first30]];
    result = [result stringByAppendingFormat: @"   has [%@] accomplishment entities:", @(self.accomplishment.count)];
    if (self.accomplishment.count > 0) {
        for (Accomplishments *acc in self.accomplishment) {
            result = [result stringByAppendingFormat: @"\n      accomplishment.name   = %@", acc.name];
        }
    }

    return result;
}

@end
