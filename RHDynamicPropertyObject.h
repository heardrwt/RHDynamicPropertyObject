//
//  RHDynamicPropertyObject.h
//
//  Created by Richard Heard on 16/07/13.
//  Copyright (c) 2013 Richard Heard. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions
//  are met:
//  1. Redistributions of source code must retain the above copyright
//  notice, this list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright
//  notice, this list of conditions and the following disclaimer in the
//  documentation and/or other materials provided with the distribution.
//  3. The name of the author may not be used to endorse or promote products
//  derived from this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
//  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
//  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
//  NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
//  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
//  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// RHDynamicPropertyObject makes it easy for subclasses to provide dynamic implementations of properties at runtime.
// Supported property types include: id, bool, int, long, unsigned long, long long, unsigned long long, double, float, NSInteger and NSUInteger


#import <Foundation/Foundation.h>

@interface RHDynamicPropertyObject : NSObject

//subclassers should implement the below methods for supported property names
-(id)valueForDynamicProperty:(NSString*)propertyName;
-(void)setValue:(id)value forDynamicProperty:(NSString*)propertyName;

//you can override this method and return NO to prevent specific properties from being dynamically implemented. Default implementation just returns YES.
+(BOOL)shouldImplementDynamicProperty:(NSString*)propertyName;


//info
+(Class)classForProperty:(NSString*)propertyName; //assumes NSNumber for numeric types. structs etc return nil.

@end

