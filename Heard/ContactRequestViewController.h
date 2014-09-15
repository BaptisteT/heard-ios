//
//  ContactRequestViewController.h
//  Heard
//
//  Created by Baptiste Truchot on 9/13/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>

@protocol ContactRequestVCDelegate;

@interface ContactRequestViewController : UIViewController

@property (weak, nonatomic) id<ContactRequestVCDelegate> delegate;

@end

@protocol ContactRequestVCDelegate

- (ABAddressBookRef)addressBook;

@end
