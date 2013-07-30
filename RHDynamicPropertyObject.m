//
//  RHDynamicPropertyObject.m
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

#import <objc/runtime.h>
#import "RHDynamicPropertyObject.h"

#define RHErrorLog(format, ...) do{ NSLog( @"%s:%i %@ ", __PRETTY_FUNCTION__, __LINE__, [NSString stringWithFormat: format, ##__VA_ARGS__]); } while (0)

@interface RHDynamicPropertyObject ()
//private

//selector tests
extern BOOL dp_selectorIsSetter(SEL sel);
extern BOOL dp_selectorIsGetter(SEL sel);

//generic property access methods
extern void dp_genericSetter_object(id self, SEL _cmd, id value);
extern id dp_genericGetter_object(id self, SEL _cmd);

//helper methods
extern NSString* dp_propertyNameFromSelector(SEL sel); // setBigString: => bigString; bigString =>bigString;
extern objc_property_t dp_propertyWithName(Class class, NSString* propertyName);
extern Class dp_classImplementingProperty(Class currentClass, objc_property_t property);

extern IMP dp_propertyGetterIMP(objc_property_t property);
extern IMP dp_propertySetterIMP(objc_property_t property);

extern const char* dp_typesForPropertyGetter(objc_property_t property);
extern const char* dp_typesForPropertySetter(objc_property_t property);

@end


@implementation RHDynamicPropertyObject

#pragma mark - subclass implementations
-(id)valueForDynamicProperty:(NSString*)propertyName{
    [NSException raise:NSInvalidArgumentException format:@"Error: Unknown dynamic property '%@'.", propertyName];
    return nil;
}

-(void)setValue:(id)value forDynamicProperty:(NSString*)propertyName{
    [NSException raise:NSInvalidArgumentException format:@"Error: Unknown dynamic property '%@'.", propertyName];
}

+(BOOL)shouldImplementDynamicProperty:(NSString*)propertyName{
    return YES;
}


#pragma mark - generic getters and setters
id dp_genericGetter_object(id self, SEL _cmd){
    NSString *propertyName = dp_propertyNameFromSelector(_cmd);
    return [self valueForDynamicProperty:propertyName];
}

void dp_genericSetter_object(id self, SEL _cmd, id value){
    NSString *propertyName = dp_propertyNameFromSelector(_cmd);
    [self setValue:value forDynamicProperty:propertyName];
}


#define GENERIC_GETTER(type, method) extern type dp_genericGetter_ ## method (id self, SEL _cmd);   \
type dp_genericGetter_ ## method (id self, SEL _cmd){                                               \
NSString *propertyName = dp_propertyNameFromSelector(_cmd);                                     \
return [[self valueForDynamicProperty:propertyName] method];                                    \
}

GENERIC_GETTER(BOOL, boolValue);
GENERIC_GETTER(int, intValue);
GENERIC_GETTER(long, longValue);
GENERIC_GETTER(unsigned long, unsignedLongValue);
GENERIC_GETTER(long long, longLongValue);
GENERIC_GETTER(unsigned long long, unsignedLongLongValue);
GENERIC_GETTER(double, doubleValue);
GENERIC_GETTER(float, floatValue);


#define GENERIC_SETTER(type, method) extern void dp_genericSetter_ ## method (id self, SEL _cmd, type value);   \
void dp_genericSetter_ ## method (id self, SEL _cmd, type value){                                               \
NSString *propertyName = dp_propertyNameFromSelector(_cmd);                                                     \
return [self setValue:[NSNumber method :value] forDynamicProperty:propertyName];                            \
}

GENERIC_SETTER(BOOL, numberWithBool);
GENERIC_SETTER(int, numberWithInt);
GENERIC_SETTER(long, numberWithLong);
GENERIC_SETTER(unsigned long, numberWithUnsignedLong);
GENERIC_SETTER(long long, numberWithLongLong);
GENERIC_SETTER(unsigned long long, numberWithUnsignedLongLong);
GENERIC_SETTER(double, numberWithDouble);
GENERIC_SETTER(float, numberWithFloat);


#pragma mark - internal instance method resolving logic
BOOL dp_selectorIsSetter(SEL sel){
    NSString *selector = NSStringFromSelector(sel);
    return [selector hasPrefix:@"set"] && [selector rangeOfString:@":" ].location == (selector.length - 1);
}

BOOL dp_selectorIsGetter(SEL sel){
    NSString *selectorString = NSStringFromSelector(sel);
    return [selectorString rangeOfString:@":"].location == NSNotFound;
}


#pragma mark - helper methods
NSString* dp_propertyNameFromSelector(SEL sel){
    if (dp_selectorIsGetter(sel)){
        return NSStringFromSelector(sel);
    }
    if (dp_selectorIsSetter(sel)){
        NSString *string = NSStringFromSelector(sel);
        string = [[string substringFromIndex:3] stringByReplacingOccurrencesOfString:@":" withString:@""];
        return [[[string substringToIndex:1] lowercaseString] stringByAppendingString:[string substringFromIndex:1]];
    }
    
    return nil;
}

objc_property_t dp_propertyWithName(Class class, NSString* propertyName){
    objc_property_t property = class_getProperty(class, [propertyName UTF8String]);
    if (!property){
        RHErrorLog(@"Error: Failed to get class_getProperty() for property with name %@.", propertyName);
        return NULL;
    }
    return property;
}

Class dp_classImplementingProperty(Class currentClass, objc_property_t property){
    if (!property) return NULL;
    const char *propertyName = property_getName(property);
    Class implementingClass = NULL;
    do {
        implementingClass = currentClass;
        currentClass = class_getSuperclass(currentClass);
    } while (class_getProperty(currentClass, propertyName) == property);
    
    return implementingClass;
}

IMP dp_propertyGetterIMP(objc_property_t property){
    const char *attributes = property_getAttributes(property);
    
    if (attributes == NULL){
        RHErrorLog(@"Failed to get property_getAttributes() for property.");
        return NULL;
    }
    
    //we only care about the first letter of the attributes string, after T aka [1]
    switch(attributes[1]) {
        case '@' : return (IMP)dp_genericGetter_object;
        case 'c' : return (IMP)dp_genericGetter_boolValue; //bool is a char internally
        case 'i' : return (IMP)dp_genericGetter_intValue;
        case 'l' : return (IMP)dp_genericGetter_longValue; // under LP64 long and unsigned long are actually ll and ull respectivly, hence these next 2 are only used on 32 bit systems
        case 'L' : return (IMP)dp_genericGetter_unsignedLongValue;
        case 'q' : return (IMP)dp_genericGetter_longLongValue;
        case 'Q' : return (IMP)dp_genericGetter_unsignedLongLongValue;
        case 'd' : return (IMP)dp_genericGetter_doubleValue;
        case 'f' : return (IMP)dp_genericGetter_floatValue;
    }
    
    //unknown
    RHErrorLog(@"Unknown Generic Getter IMP for attributes: %s.", attributes);
    return NULL;
}

IMP dp_propertySetterIMP(objc_property_t property){
    const char *attributes = property_getAttributes(property);
    
    if (attributes == NULL){
        RHErrorLog(@"Failed to get property_getAttributes() for property.");
        return NULL;
    }
    
    //we only care about the first letter of the attributes string, after T aka ()
    switch(attributes[1]) {
        case '@' : return (IMP)dp_genericSetter_object;
        case 'c' : return (IMP)dp_genericSetter_numberWithBool; //bool is a char internally
        case 'i' : return (IMP)dp_genericSetter_numberWithInt;
        case 'l' : return (IMP)dp_genericSetter_numberWithLong; // under LP64 long and unsigned long are actually ll and ull respectivly, hence these next 2 are only used on 32 bit systems
        case 'L' : return (IMP)dp_genericSetter_numberWithUnsignedLong;
        case 'q' : return (IMP)dp_genericSetter_numberWithLongLong;
        case 'Q' : return (IMP)dp_genericSetter_numberWithUnsignedLongLong;
        case 'd' : return (IMP)dp_genericSetter_numberWithDouble;
        case 'f' : return (IMP)dp_genericSetter_numberWithFloat;
    }
    
    //unknown
    RHErrorLog(@"Unknown Generic Setter IMP for attributes: %s.", attributes);
    return NULL;    return NULL;
}

const char* dp_typesForPropertySetter(objc_property_t property){
    const char *attributes = property_getAttributes(property);
    
    if (attributes == NULL){
        RHErrorLog(@"Failed to get property_getAttributes() for property.");
        return NULL;
    }
    
    //we only care about the first letter of the attributes string, after T aka ()
    switch(attributes[1]) {
        case '@' : return "v@:@";
        case 'c' : return "v@:c";
        case 'i' : return "v@:i";
        case 'l' : return "v@:l";
        case 'L' : return "v@:L";
        case 'q' : return "v@:q";
        case 'Q' : return "v@:Q";
        case 'd' : return "v@:d";
        case 'f' : return "v@:f";
    }
    
    //unknown
    return "v@:";
}

const char* dp_typesForPropertyGetter(objc_property_t property){
    const char *attributes = property_getAttributes(property);
    
    if (attributes == NULL){
        RHErrorLog(@"Failed to get property_getAttributes() for property.");
        return NULL;
    }
    
    //we only care about the first letter of the attributes string, after T aka ()
    switch(attributes[1]) {
        case '@' : return "v@:@";
        case 'c' : return "v@:c";
        case 'i' : return "v@:i";
        case 'l' : return "v@:l";
        case 'L' : return "v@:L";
        case 'q' : return "v@:q";
        case 'Q' : return "v@:Q";
        case 'd' : return "v@:d";
        case 'f' : return "v@:f";
    }
    
    //unknown
    return "v@:";
}


#pragma mark - override the instance method resolver method

+(BOOL)resolveInstanceMethod:(SEL)sel{
    NSString *propertyName = dp_propertyNameFromSelector(sel);
    objc_property_t property = dp_propertyWithName(self.class , propertyName);
    Class implementingClass = self;
    if (property){
        implementingClass = dp_classImplementingProperty(self.class, property);
        //re-lookup the property using the actual implementing class
        property = dp_propertyWithName(implementingClass , dp_propertyNameFromSelector(sel));
    }
    
    //getter
    if (dp_selectorIsGetter(sel) && property && [self shouldImplementDynamicProperty:propertyName]){
        //add method of the correct type
        IMP implementation = dp_propertyGetterIMP(property);
        const char *types = dp_typesForPropertyGetter(property);
        if (implementation && types) class_addMethod(implementingClass, sel, implementation, types);
        return YES;
    }
    
    //setter
    if (dp_selectorIsSetter(sel) && property && [self shouldImplementDynamicProperty:propertyName]){
        //add method of the correct type
        IMP implementation = dp_propertySetterIMP(property);
        const char *types = dp_typesForPropertySetter(property);
        if (implementation && types) class_addMethod(implementingClass, sel, implementation, types);
        return YES;
    }
    
    //other
    return [super resolveInstanceMethod:sel];
}

#pragma mark - info
+(Class)classForProperty:(NSString*)propertyName{
    if (!propertyName){
        [NSException raise:NSInvalidArgumentException format:@"Error: Property name must not be nil."];
        return NULL;
    }
    objc_property_t property = class_getProperty(self, [propertyName UTF8String]);
    if (!property){
        RHErrorLog(@"Error: Failed to get class_getProperty() for property with name %@.", propertyName);
        return NULL;
    }

    const char *attributes = property_getAttributes(property);
    if (attributes == NULL){
        RHErrorLog(@"Error: Failed to get property_getAttributes() for property.");
        return NULL;
    }
    
    //we only care about the first letter of the attributes string, after T aka ()
    switch(attributes[1]) {
        case '@' : {
            //objects are what we really care about
            NSMutableString *className = [NSMutableString string];
            const char *next = &attributes[3];
            while (*next != ',' && *next != '\0' && *next != '"') {
                [className appendFormat:@"%c", *next];
                next++;
            }
            //NSLog(@"Property %@ is of class %@.", propertyName, className);
            return NSClassFromString([NSString stringWithString:className]);
        }
        //all these can be represented as NSNumber, so return [NSNumber class]
        case 'c' :
        case 'i' :
        case 'l' :
        case 'L' :
        case 'q' :
        case 'Q' :
        case 'd' :
        case 'f' : return [NSNumber class];
        default  : return NULL;
    }
    
    return NULL;
}


@end

