#import "Resumes.h"
#import "Packages.h"
#import "Education.h"
#import "Jobs.h"


@implementation Resumes

NSString *const kOCRResumesEntity = @"Resumes";

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
    result = [result stringByAppendingFormat: @"   in package        = %@\n", self.package.name];
    result = [result stringByAppendingFormat: @"   street1           = %@\n", self.street1];
    result = [result stringByAppendingFormat: @"   street2           = %@\n", self.street2];
    result = [result stringByAppendingFormat: @"   city              = %@\n", self.city];
    result = [result stringByAppendingFormat: @"   state             = %@\n", self.state];
    result = [result stringByAppendingFormat: @"   postal_code       = %@\n", self.postal_code];
    result = [result stringByAppendingFormat: @"   home_phone        = %@\n", self.home_phone];
    result = [result stringByAppendingFormat: @"   mobile_phone      = %@\n", self.mobile_phone];
    result = [result stringByAppendingFormat: @"   email             = %@\n", self.email];
    result = [result stringByAppendingFormat: @"   summary           = %@\n", [self.summary first30]];
    result = [result stringByAppendingFormat: @"   has [%@] education entities:", @(self.education.count)];
    if (self.education.count > 0) {
        for (Education *edu in self.education) {
            result = [result stringByAppendingFormat: @"\n      education.name        = %@", edu.name];
        }
    }
    result = [result stringByAppendingFormat: @"\n   has [%@] job entities:", @(self.job.count)];
    if (self.job.count > 0) {
        for (Jobs *job in self.job) {
            result = [result stringByAppendingFormat: @"\n      job.name                  = %@", job.name];
        }
    }
    
    return result;
}

@end
