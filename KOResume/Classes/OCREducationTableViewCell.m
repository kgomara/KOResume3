//
//  OCREducationTableViewCell.m
//  KOResume
//
//  Created by Kevin O'Mara on 6/14/14.
//  Copyright (c) 2014 O'Mara Consulting Associates. All rights reserved.
//

#import "OCREducationTableViewCell.h"

@implementation OCREducationTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    
}

//----------------------------------------------------------------------------------------------------------
/**
 Asks the delegate if the text field should proc
 
 The text field calls this method whenever the user taps the return button. You can use this method to implement
 any custom behavior when the button is tapped.
 
 In our Storyboard scene, we set the textfield tag values incrementally, and then use the tag of the current
 textField responder to determine what to do next. We also set the other keyboard atttributes appropriately for]
 the data type we expect to see, and in particular set the return key to "Next" if hitting return will advance
 the user to the next field.
 
 Note the specific check for the date fields, in which case we bring up the data picker.
 
 @param textField       The text field whose return button was pressed.
 @return                YES if the text field should implement its default behavior for the return button; otherwise, NO.
 */
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    DLog();
    
	int nextTag = [textField tag] + 1;
	UIResponder *nextResponder = [textField.superview viewWithTag: nextTag];
	
	if (nextResponder) {
        [nextResponder becomeFirstResponder];
	} else {
		[textField resignFirstResponder];       // Dismisses the keyboard
	}
	
	return NO;
}


//----------------------------------------------------------------------------------------------------------
/**
 Tells the delegate that editing of the specified text view has ended.
 
 Implementation of this method is optional. A text view sends this message to its delegate after it closes out
 any pending edits and resigns its first responder status. You can use this method to tear down any data structures
 or change any state information that you set when editing began.
 
 @param textView The text view in which editing ended.
 */
- (void)textFieldDidEndEditing: (UITextField *)textField
{
    DLog();
    
    [self.delegate doUpdateTextField:textField
                        forTableCell:self];
}



@end
