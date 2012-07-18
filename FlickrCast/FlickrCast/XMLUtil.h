//
//  XMLUtil.h
//  FlickrCast
//
//  Created by BIBHAS BHATTACHARYA on 5/24/12.
//  Copyright (c) 2012 Self. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TBXML.h"

@interface XMLUtil : NSObject 
+ (TBXML*) loadXML: (NSString*) url;
+ (NSString*) getChildValue: (NSString*) childTag parent: (TBXMLElement*) parent;
@end
