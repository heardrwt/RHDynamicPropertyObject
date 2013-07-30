## RHDynamicPropertyObject

RHDynamicPropertyObject makes it easy for subclasses to provide dynamic implementations of properties at runtime.


## Supported Property Types
* id
* BOOL
* int
* long
* unsigned long
* long long
* unsigned long long
* double
* float
* NSInteger
* NSUInteger


## Overview

By implementing the methods `valueForDynamicProperty:` and `setValue:forDynamicProperty:` your subclass can easily implement properties that are declared as @dynamic at runtime. This allows you back an object using an NSMutableDictionary or some other form of key / value store. For a real world example, take a look at [RHSQLiteKit](http://github.com/heardrwt/RHSQLiteKit/RHSQLiteObject.m), where RHSQLiteObject is a subclass of RHDynamicPropertyObject.

## Interface

```objectivec

@interface RHDynamicPropertyObject : NSObject

//subclassers should implement the below methods for supported property names
-(id)valueForDynamicProperty:(NSString*)propertyName;
-(void)setValue:(id)value forDynamicProperty:(NSString*)propertyName;

//you can override this method and return NO to prevent specific properties from being dynamically implemented. Default implementation just returns YES.
+(BOOL)shouldImplementDynamicProperty:(NSString*)propertyName;


//info
+(Class)classForProperty:(NSString*)propertyName; //assumes NSNumber for numeric types. structs etc return nil.

@end


```


## Licence
Released under the Modified BSD License. 
(Attribution Required)
<pre>
RHDynamicPropertyObject

Copyright (c) 2013 Richard Heard. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:
1. Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.
3. The name of the author may not be used to endorse or promote products
derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
</pre>

## Mac + iOS version support

This code has been tested on Mac OS 10.8+. It should also work fine on iOS 5+.

Feel free to file issues for anything that doesn't work correctly, or you feel could be improved. 

RHDynamicPropertyObject uses ARC.
## Appreciation 

If you find this project useful, buy me a beer the next time you see me, or grab me something from my [**wishlist**](http://www.amazon.com/gp/registry/wishlist/3FWPYC4SEU5QM ). 

