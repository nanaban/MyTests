//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2004-2010 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <OCMock/OCMock.h>
#import "OCMockObjectTests.h"

// --------------------------------------------------------------------------------------
//	Helper classes and protocols for testing
// --------------------------------------------------------------------------------------

@protocol TestProtocol
- (int)primitiveValue;
@optional
- (id)objectValue;
@end

@protocol ProtocolWithTypeQualifierMethod
- (void)aSpecialMethod:(byref in void *)someArg;
@end


@interface TestClassThatCallsSelf : NSObject
- (NSString *)method1;
- (NSString *)method2;
@end

@implementation TestClassThatCallsSelf

- (NSString *)method1
{
	id retVal = [self method2];
	return retVal;
}

- (NSString *)method2
{
	return @"Foo";
}

@end


@interface TestClassWithClassMethod : NSObject

+ (NSString *)method1;

@end

@implementation TestClassWithClassMethod

+ (NSString *)method1
{
    return @"Foo";
}

@end


@interface TestObserver	: NSObject
{
	@public
	NSNotification *notification;
}

@end

@implementation TestObserver

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[notification release];
	[super dealloc];
}

- (void)receiveNotification:(NSNotification *)aNotification
{
	notification = [aNotification retain];
}

@end

static NSString *TestNotification = @"TestNotification";


// --------------------------------------------------------------------------------------
//  setup
// --------------------------------------------------------------------------------------


@implementation OCMockObjectTests

- (void)setUp
{
	mock = [OCMockObject mockForClass:[NSString class]];
}


 --------------------------------------------------------------------------------------
	accepting stubbed methods / rejecting methods not stubbed
 --------------------------------------------------------------------------------------

- (void)testAcceptsStubbedMethod
{
	[[mock stub] lowercaseString];
	[mock lowercaseString];
}

- (void)testRaisesExceptionWhenUnknownMethodIsCalled
{
	[[mock stub] lowercaseString];
	GHAssertThrows([mock uppercaseString], @"Should have raised an exception.");
}


- (void)testAcceptsStubbedMethodWithSpecificArgument
{
	[[mock stub] hasSuffix:@"foo"];
	[mock hasSuffix:@"foo"];
}


- (void)testAcceptsStubbedMethodWithConstraint
{
	[[mock stub] hasSuffix:[OCMArg any]];
	[mock hasSuffix:@"foo"];
	[mock hasSuffix:@"bar"];
}

#if NS_BLOCKS_AVAILABLE

- (void)testAcceptsStubbedMethodWithBlockArgument
{
	mock = [OCMockObject mockForClass:[NSArray class]];
	[[mock stub] indexesOfObjectsPassingTest:[OCMArg any]];
	[mock indexesOfObjectsPassingTest:^(id obj, NSUInteger idx, BOOL *stop) { return YES; }];
}


- (void)testAcceptsStubbedMethodWithBlockConstraint
{
	[[mock stub] hasSuffix:[OCMArg checkWithBlock:^(id value) { return [value isEqualToString:@"foo"]; }]];

	GHAssertNoThrow([mock hasSuffix:@"foo"], @"Should not have thrown a exception");   
	GHAssertThrows([mock hasSuffix:@"bar"], @"Should have thrown a exception");   
}
	
#endif

- (void)testAcceptsStubbedMethodWithNilArgument
{
	[[mock stub] hasSuffix:nil];
	
	[mock hasSuffix:nil];
}

- (void)testRaisesExceptionWhenMethodWithWrongArgumentIsCalled
{
	[[mock stub] hasSuffix:@"foo"];
	GHAssertThrows([mock hasSuffix:@"xyz"], @"Should have raised an exception.");
}


- (void)testAcceptsStubbedMethodWithScalarArgument
{
	[[mock stub] stringByPaddingToLength:20 withString:@"foo" startingAtIndex:5];
	[mock stringByPaddingToLength:20 withString:@"foo" startingAtIndex:5];
}


- (void)testRaisesExceptionWhenMethodWithOneWrongScalarArgumentIsCalled
{
	[[mock stub] stringByPaddingToLength:20 withString:@"foo" startingAtIndex:5];
	GHAssertThrows([mock stringByPaddingToLength:20 withString:@"foo" startingAtIndex:3], @"Should have raised an exception.");	
}

- (void)testAcceptsStubbedMethodWithPointerArgument
{
	NSError *error;
	[[[mock stub] andReturnValue:OCMOCK_VALUE((BOOL){YES})] writeToFile:OCMOCK_ANY atomically:YES encoding:NSMacOSRomanStringEncoding error:&error];
	
	GHAssertTrue([mock writeToFile:@"foo" atomically:YES encoding:NSMacOSRomanStringEncoding error:&error], nil);
}

- (void)testAcceptsStubbedMethodWithAnyPointerArgument
{
	NSError *error;
	[[[mock stub] andReturnValue:OCMOCK_VALUE((BOOL){YES})] writeToFile:OCMOCK_ANY atomically:YES encoding:NSMacOSRomanStringEncoding error:[OCMArg anyPointer]];
	
	GHAssertTrue([mock writeToFile:@"foo" atomically:YES encoding:NSMacOSRomanStringEncoding error:&error], nil);
}

- (void)testRaisesExceptionWhenMethodWithWrongPointerArgumentIsCalled
{
	NSString *string;
	NSString *anotherString;
	NSArray *array;
	
	[[mock stub] completePathIntoString:&string caseSensitive:YES matchesIntoArray:&array filterTypes:OCMOCK_ANY];
	
	GHAssertThrows([mock completePathIntoString:&anotherString caseSensitive:YES matchesIntoArray:&array filterTypes:OCMOCK_ANY], nil);
}

- (void)testAcceptsStubbedMethodWithVoidPointerArgument
{
	mock = [OCMockObject mockForClass:[NSMutableData class]];
	[[mock stub] appendBytes:NULL length:0];
	[mock appendBytes:NULL length:0];
}


- (void)testRaisesExceptionWhenMethodWithWrongVoidPointerArgumentIsCalled
{
	mock = [OCMockObject mockForClass:[NSMutableData class]];
	[[mock stub] appendBytes:"foo" length:3];
	GHAssertThrows([mock appendBytes:"bar" length:3], @"Should have raised an exception.");
}


- (void)testAcceptsStubbedMethodWithPointerPointerArgument
{
	NSError *error = nil;
	[[mock stub] initWithContentsOfFile:@"foo.txt" encoding:NSASCIIStringEncoding error:&error];	
	[mock initWithContentsOfFile:@"foo.txt" encoding:NSASCIIStringEncoding error:&error];
}


- (void)testRaisesExceptionWhenMethodWithWrongPointerPointerArgumentIsCalled
{
	NSError *error = nil, *error2;
	[[mock stub] initWithContentsOfFile:@"foo.txt" encoding:NSASCIIStringEncoding error:&error];	
	GHAssertThrows([mock initWithContentsOfFile:@"foo.txt" encoding:NSASCIIStringEncoding error:&error2], @"Should have raised.");
}


- (void)testAcceptsStubbedMethodWithStructArgument
{
    NSRange range = NSMakeRange(0,20);
	[[mock stub] substringWithRange:range];
	[mock substringWithRange:range];
}


- (void)testRaisesExceptionWhenMethodWithWrongStructArgumentIsCalled
{
    NSRange range = NSMakeRange(0,20);
    NSRange otherRange = NSMakeRange(0,10);
	[[mock stub] substringWithRange:range];
	GHAssertThrows([mock substringWithRange:otherRange], @"Should have raised an exception.");	
}


- (void)testCanPassMocksAsArguments
{
	id mockArg = [OCMockObject mockForClass:[NSString class]];
	[[mock stub] stringByAppendingString:[OCMArg any]];
	[mock stringByAppendingString:mockArg];
}

- (void)testCanStubWithMockArguments
{
	id mockArg = [OCMockObject mockForClass:[NSString class]];
	[[mock stub] stringByAppendingString:mockArg];
	[mock stringByAppendingString:mockArg];
}

- (void)testRaisesExceptionWhenStubbedMockArgIsNotUsed
{
	id mockArg = [OCMockObject mockForClass:[NSString class]];
	[[mock stub] stringByAppendingString:mockArg];
	GHAssertThrows([mock stringByAppendingString:@"foo"], @"Should have raised an exception.");
}

- (void)testRaisesExceptionWhenDifferentMockArgumentIsPassed
{
	id expectedArg = [OCMockObject mockForClass:[NSString class]];
	id otherArg = [OCMockObject mockForClass:[NSString class]];
	[[mock stub] stringByAppendingString:otherArg];
	GHAssertThrows([mock stringByAppendingString:expectedArg], @"Should have raised an exception.");	
}


// --------------------------------------------------------------------------------------
//	returning values from stubbed methods
// --------------------------------------------------------------------------------------

- (void)testReturnsStubbedReturnValue
{
	id returnValue;  

	[[[mock stub] andReturn:@"megamock"] lowercaseString];
	returnValue = [mock lowercaseString];
	
	GHAssertEqualObjects(@"megamock", returnValue, @"Should have returned stubbed value.");
	
}

- (void)testReturnsStubbedIntReturnValue
{
    int expectedValue = 42;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(expectedValue)] intValue];
	int returnValue = [mock intValue];
    
	GHAssertEquals(expectedValue, returnValue, @"Should have returned stubbed value.");
}

- (void)testRaisesWhenBoxedValueTypesDoNotMatch
{
    double expectedValue = 42;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(expectedValue)] intValue];
    
	GHAssertThrows([mock intValue], @"Should have raised an exception.");
}

- (void)testReturnsStubbedNilReturnValue
{
	[[[mock stub] andReturn:nil] uppercaseString];
	
	id returnValue = [mock uppercaseString];
	
	GHAssertNil(returnValue, @"Should have returned stubbed value, which is nil.");
}


// --------------------------------------------------------------------------------------
//	raising exceptions, posting notifications, etc.
// --------------------------------------------------------------------------------------

- (void)testRaisesExceptionWhenAskedTo
{
	NSException *exception = [NSException exceptionWithName:@"TestException" reason:@"test" userInfo:nil];
	[[[mock expect] andThrow:exception] lowercaseString];
	
	GHAssertThrows([mock lowercaseString], @"Should have raised an exception.");
}

- (void)testPostsNotificationWhenAskedTo
{
	TestObserver *observer = [[[TestObserver alloc] init] autorelease];
	[[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(receiveNotification:) name:TestNotification object:nil];
	
	NSNotification *notification = [NSNotification notificationWithName:TestNotification object:self];
	[[[mock stub] andPost:notification] lowercaseString];
	
	[mock lowercaseString];
	
	GHAssertNotNil(observer->notification, @"Should have sent a notification.");
	GHAssertEqualObjects(TestNotification, [observer->notification name], @"Name should match posted one.");
	GHAssertEqualObjects(self, [observer->notification object], @"Object should match posted one.");
}

- (void)testPostsNotificationInAddtionToReturningValue
{
	TestObserver *observer = [[[TestObserver alloc] init] autorelease];
	[[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(receiveNotification:) name:TestNotification object:nil];
	
	NSNotification *notification = [NSNotification notificationWithName:TestNotification object:self];
	[[[[mock stub] andReturn:@"foo"] andPost:notification] lowercaseString];
	
	GHAssertEqualObjects(@"foo", [mock lowercaseString], @"Should have returned stubbed value.");
	GHAssertNotNil(observer->notification, @"Should have sent a notification.");
}


- (NSString *)valueForString:(NSString *)aString andMask:(NSStringCompareOptions)mask
{
	return [NSString stringWithFormat:@"[%@, %d]", aString, mask];
}

- (void)testCallsAlternativeMethodAndPassesOriginalArgumentsAndReturnsValue
{
	[[[mock stub] andCall:@selector(valueForString:andMask:) onObject:self] commonPrefixWithString:@"FOO" options:NSCaseInsensitiveSearch];
	
	NSString *returnValue = [mock commonPrefixWithString:@"FOO" options:NSCaseInsensitiveSearch];
	
	GHAssertEqualObjects(@"[FOO, 1]", returnValue, @"Should have passed and returned invocation.");
}

#if NS_BLOCKS_AVAILABLE

- (void)testCallsBlockWhichCanSetUpReturnValue
{
	void (^theBlock)(NSInvocation *) = ^(NSInvocation *invocation) 
		{
			NSString *value;
			[invocation getArgument:&value atIndex:2];
			value = [NSString stringWithFormat:@"MOCK %@", value];
			[invocation setReturnValue:&value];
		};
		
	[[[mock stub] andDo:theBlock] stringByAppendingString:[OCMArg any]];
		
	GHAssertEqualObjects(@"MOCK foo", [mock stringByAppendingString:@"foo"], @"Should have called block.");
	GHAssertEqualObjects(@"MOCK bar", [mock stringByAppendingString:@"bar"], @"Should have called block.");
}

#endif

- (void)testThrowsWhenTryingToUseForwardToRealObjectOnNonPartialMock
{
	GHAssertThrows([[[mock expect] andForwardToRealObject] method2], @"Should have raised and exception.");
}

- (void)testForwardsToRealObjectWhenSetUpAndCalledOnMock
{
	TestClassThatCallsSelf *realObject = [[[TestClassThatCallsSelf alloc] init] autorelease];
	mock = [OCMockObject partialMockForObject:realObject];

	[[[mock expect] andForwardToRealObject] method2];
	GHAssertEquals(@"Foo", [mock method2], @"Should have called method on real object.");

	[mock verify];
}

- (void)testForwardsToRealObjectWhenSetUpAndCalledOnRealObject
{
	TestClassThatCallsSelf *realObject = [[[TestClassThatCallsSelf alloc] init] autorelease];
	mock = [OCMockObject partialMockForObject:realObject];
	
	[[[mock expect] andForwardToRealObject] method2];
	GHAssertEquals(@"Foo", [realObject method2], @"Should have called method on real object.");
	
	[mock verify];
}


// --------------------------------------------------------------------------------------
//	returning values in pass-by-reference arguments
// --------------------------------------------------------------------------------------

- (void)testReturnsValuesInPassByReferenceArguments
{
	NSString *expectedName = @"Test";
	NSArray *expectedArray = [NSArray array];
	
	[[mock expect] completePathIntoString:[OCMArg setTo:expectedName] caseSensitive:YES 
						 matchesIntoArray:[OCMArg setTo:expectedArray] filterTypes:OCMOCK_ANY];
	
	NSString *actualName = nil;
	NSArray *actualArray = nil;
	[mock completePathIntoString:&actualName caseSensitive:YES matchesIntoArray:&actualArray filterTypes:nil];

	GHAssertNoThrow([mock verify], @"An unexpected exception was thrown");
	GHAssertEqualObjects(expectedName, actualName, @"The two string objects should be equal");
	GHAssertEqualObjects(expectedArray, actualArray, @"The two array objects should be equal");
}


// --------------------------------------------------------------------------------------
//	accepting expected methods
// --------------------------------------------------------------------------------------

- (void)testAcceptsExpectedMethod
{
	[[mock expect] lowercaseString];
	[mock lowercaseString];
}


- (void)testAcceptsExpectedMethodAndReturnsValue
{
	id returnValue;

	[[[mock expect] andReturn:@"Objective-C"] lowercaseString];
	returnValue = [mock lowercaseString];

	GHAssertEqualObjects(@"Objective-C", returnValue, @"Should have returned stubbed value.");
}


- (void)testAcceptsExpectedMethodsInRecordedSequence
{
	[[mock expect] lowercaseString];
	[[mock expect] uppercaseString];
	
	[mock lowercaseString];
	[mock uppercaseString];
}


- (void)testAcceptsExpectedMethodsInDifferentSequence
{
	[[mock expect] lowercaseString];
	[[mock expect] uppercaseString];
	
	[mock uppercaseString];
	[mock lowercaseString];
}


// --------------------------------------------------------------------------------------
//	verifying expected methods
// --------------------------------------------------------------------------------------

- (void)testAcceptsAndVerifiesExpectedMethods
{
	[[mock expect] lowercaseString];
	[[mock expect] uppercaseString];
	
	[mock lowercaseString];
	[mock uppercaseString];
	
	[mock verify];
}


- (void)testRaisesExceptionOnVerifyWhenNotAllExpectedMethodsWereCalled
{
	[[mock expect] lowercaseString];
	[[mock expect] uppercaseString];
	
	[mock lowercaseString];
	
	GHAssertThrows([mock verify], @"Should have raised an exception.");
}

- (void)testAcceptsAndVerifiesTwoExpectedInvocationsOfSameMethod
{
	[[mock expect] lowercaseString];
	[[mock expect] lowercaseString];
	
	[mock lowercaseString];
	[mock lowercaseString];
	
	[mock verify];
}


- (void)testAcceptsAndVerifiesTwoExpectedInvocationsOfSameMethodAndReturnsCorrespondingValues
{
	[[[mock expect] andReturn:@"foo"] lowercaseString];
	[[[mock expect] andReturn:@"bar"] lowercaseString];
	
	GHAssertEqualObjects(@"foo", [mock lowercaseString], @"Should have returned first stubbed value");
	GHAssertEqualObjects(@"bar", [mock lowercaseString], @"Should have returned seconds stubbed value");
	
	[mock verify];
}

- (void)testReturnsStubbedValuesIndependentOfExpectations
{
	[[mock stub] hasSuffix:@"foo"];
	[[mock expect] hasSuffix:@"bar"];
	
	[mock hasSuffix:@"foo"];
	[mock hasSuffix:@"bar"];
	[mock hasSuffix:@"foo"]; // Since it's a stub, shouldn't matter how many times we call this
	
	[mock verify];
}

-(void)testAcceptsAndVerifiesMethodsWithSelectorArgument
{
	[[mock expect] performSelector:@selector(lowercaseString)];
	[mock performSelector:@selector(lowercaseString)];
	[mock verify];
}


// --------------------------------------------------------------------------------------
//	ordered expectations
// --------------------------------------------------------------------------------------

- (void)testAcceptsExpectedMethodsInRecordedSequenceWhenOrderMatters
{
	[mock setExpectationOrderMatters:YES];
	
	[[mock expect] lowercaseString];
	[[mock expect] uppercaseString];
	
	GHAssertNoThrow([mock lowercaseString], @"Should have accepted expected method in sequence.");
	GHAssertNoThrow([mock uppercaseString], @"Should have accepted expected method in sequence.");
}

- (void)testRaisesExceptionWhenSequenceIsWrongAndOrderMatters
{
	[mock setExpectationOrderMatters:YES];
	
	[[mock expect] lowercaseString];
	[[mock expect] uppercaseString];
	
	GHAssertThrows([mock uppercaseString], @"Should have complained about wrong sequence.");
}


// --------------------------------------------------------------------------------------
//	explicitly rejecting methods (mostly for nice mocks, see below)
// --------------------------------------------------------------------------------------

- (void)testThrowsWhenRejectedMethodIsCalledOnNiceMock
{
	mock = [OCMockObject niceMockForClass:[NSString class]];
	
	[[mock reject] uppercaseString];
	GHAssertThrows([mock uppercaseString], @"Should have complained about rejected method being called.");
}


// --------------------------------------------------------------------------------------
//	protocol mocks
// --------------------------------------------------------------------------------------

- (void)testCanMockFormalProtocol
{
	mock = [OCMockObject mockForProtocol:@protocol(NSLocking)];
	[[mock expect] lock];
	
	[mock lock];
	
	[mock verify];
}

- (void)testSetsCorrectNameForProtocolMockObjects
{
	mock = [OCMockObject mockForProtocol:@protocol(NSLocking)];
	GHAssertEqualObjects(@"OCMockObject[NSLocking]", [mock description], @"Should have returned correct description.");
}

- (void)testRaisesWhenUnknownMethodIsCalledOnProtocol
{
	mock = [OCMockObject mockForProtocol:@protocol(NSLocking)];
	GHAssertThrows([mock lowercaseString], @"Should have raised an exception.");
}

- (void)testConformsToMockedProtocol
{
	mock = [OCMockObject mockForProtocol:@protocol(NSLocking)];
	GHAssertTrue([mock conformsToProtocol:@protocol(NSLocking)], nil);
}

- (void)testRespondsToValidProtocolRequiredSelector
{
	mock = [OCMockObject mockForProtocol:@protocol(TestProtocol)];	
    GHAssertTrue([mock respondsToSelector:@selector(primitiveValue)], nil);
}

- (void)testRespondsToValidProtocolOptionalSelector
{
	mock = [OCMockObject mockForProtocol:@protocol(TestProtocol)];	
    GHAssertTrue([mock respondsToSelector:@selector(objectValue)], nil);
}

- (void)testDoesNotRespondToInvalidProtocolSelector
{
	mock = [OCMockObject mockForProtocol:@protocol(TestProtocol)];	
    GHAssertFalse([mock respondsToSelector:@selector(fooBar)], nil);
}


// --------------------------------------------------------------------------------------
//	nice mocks don't complain about unknown methods
// --------------------------------------------------------------------------------------

- (void)testReturnsDefaultValueWhenUnknownMethodIsCalledOnNiceClassMock
{
	mock = [OCMockObject niceMockForClass:[NSString class]];
	GHAssertNil([mock lowercaseString], @"Should return nil on unexpected method call (for nice mock).");	
	[mock verify];
}

- (void)testRaisesAnExceptionWhenAnExpectedMethodIsNotCalledOnNiceClassMock
{
	mock = [OCMockObject niceMockForClass:[NSString class]];	
	[[[mock expect] andReturn:@"HELLO!"] uppercaseString];
	GHAssertThrows([mock verify], @"Should have raised an exception because method was not called.");
}

- (void)testReturnDefaultValueWhenUnknownMethodIsCalledOnProtocolMock
{
	mock = [OCMockObject niceMockForProtocol:@protocol(TestProtocol)];
	GHAssertTrue(0 == [mock primitiveValue], @"Should return 0 on unexpected method call (for nice mock).");
	[mock verify];
}

- (void)testRaisesAnExceptionWenAnExpectedMethodIsNotCalledOnNiceProtocolMock
{
	mock = [OCMockObject niceMockForProtocol:@protocol(TestProtocol)];	
	[[mock expect] primitiveValue];
	GHAssertThrows([mock verify], @"Should have raised an exception because method was not called.");
}


// --------------------------------------------------------------------------------------
//	partial mocks forward unknown methods to a real instance
// --------------------------------------------------------------------------------------

- (void)testStubsMethodsOnPartialMock
{
	TestClassThatCallsSelf *foo = [[[TestClassThatCallsSelf alloc] init] autorelease];
	mock = [OCMockObject partialMockForObject:foo];
	[[[mock stub] andReturn:@"hi"] method1];
	GHAssertEqualObjects(@"hi", [mock method1], @"Should have returned stubbed value");
}


//- (void)testStubsMethodsOnPartialMockForTollFreeBridgedClasses
//{
//	mock = [OCMockObject partialMockForObject:[NSString stringWithString:@"hello"]];
//	[[[mock stub] andReturn:@"hi"] uppercaseString];
//	GHAssertEqualObjects(@"hi", [mock uppercaseString], @"Should have returned stubbed value");
//}

- (void)testForwardsUnstubbedMethodsCallsToRealObjectOnPartialMock
{
	TestClassThatCallsSelf *foo = [[[TestClassThatCallsSelf alloc] init] autorelease];
	mock = [OCMockObject partialMockForObject:foo];
	GHAssertEqualObjects(@"Foo", [mock method2], @"Should have returned value from real object.");
}

//- (void)testForwardsUnstubbedMethodsCallsToRealObjectOnPartialMockForTollFreeBridgedClasses
//{
//	mock = [OCMockObject partialMockForObject:[NSString stringWithString:@"hello2"]];
//	GHAssertEqualObjects(@"HELLO2", [mock uppercaseString], @"Should have returned value from real object.");
//}

- (void)testStubsMethodOnRealObjectReference
{
	TestClassThatCallsSelf *realObject = [[[TestClassThatCallsSelf alloc] init] autorelease];
	mock = [OCMockObject partialMockForObject:realObject];
	[[[mock stub] andReturn:@"TestFoo"] method1];
	GHAssertEqualObjects(@"TestFoo", [realObject method1], @"Should have stubbed method.");
}

- (void)testReturnsToRealImplementationWhenExpectedCallOccurred
{
    TestClassThatCallsSelf *realObject = [[[TestClassThatCallsSelf alloc] init] autorelease];
   	mock = [OCMockObject partialMockForObject:realObject];
   	[[[mock expect] andReturn:@"TestFoo"] method2];
   	GHAssertEqualObjects(@"TestFoo", [realObject method2], @"Should have stubbed method.");
   	GHAssertEqualObjects(@"Foo", [realObject method2], @"Should have 'unstubbed' method.");
}

- (void)testRestoresObjectWhenStopped
{
	TestClassThatCallsSelf *realObject = [[[TestClassThatCallsSelf alloc] init] autorelease];
	mock = [OCMockObject partialMockForObject:realObject];
	[[[mock stub] andReturn:@"TestFoo"] method2];
	GHAssertEqualObjects(@"TestFoo", [realObject method2], @"Should have stubbed method.");
	[mock stopMocking];
	GHAssertEqualObjects(@"Foo", [realObject method2], @"Should have 'unstubbed' method.");
}

- (void)testCallsToSelfInRealObjectAreShadowedByPartialMock
{
	TestClassThatCallsSelf *foo = [[[TestClassThatCallsSelf alloc] init] autorelease];
	mock = [OCMockObject partialMockForObject:foo];
	[[[mock stub] andReturn:@"FooFoo"] method2];
	GHAssertEqualObjects(@"FooFoo", [mock method1], @"Should have called through to stubbed method.");
}

- (NSString *)differentMethodInDifferentClass
{
	return @"swizzled!";
}

- (void)testImplementsMethodSwizzling
{
	// using partial mocks and the indirect return value provider
	TestClassThatCallsSelf *foo = [[[TestClassThatCallsSelf alloc] init] autorelease];
	mock = [OCMockObject partialMockForObject:foo];
	[[[mock stub] andCall:@selector(differentMethodInDifferentClass) onObject:self] method1];
	GHAssertEqualObjects(@"swizzled!", [foo method1], @"Should have returned value from different method");
}


- (void)aMethodWithVoidReturn
{
}

- (void)testMethodSwizzlingWorksForVoidReturns
{
	TestClassThatCallsSelf *foo = [[[TestClassThatCallsSelf alloc] init] autorelease];
	mock = [OCMockObject partialMockForObject:foo];
	[[[mock stub] andCall:@selector(aMethodWithVoidReturn) onObject:self] method1];
	GHAssertNoThrow([foo method1], @"Should have worked.");
}


// --------------------------------------------------------------------------------------
//	class object mocks allow stubbing/expecting on class objects
// --------------------------------------------------------------------------------------

- (void)testStubsMethodOnClassObject
{
    mock = [OCMockObject mockForClassObject:[TestClassWithClassMethod class]];
    
	[[[mock stub] andReturn:@"TestFoo"] method1];
	GHAssertEqualObjects(@"TestFoo", [TestClassWithClassMethod method1], @"Should have stubbed method.");
}

//- (void)testForwardsUnstubbedMethodsToRealClassObjectAfterStopIsCalled
//{
//    mock = [OCMockObject mockForClassObject:[TestClassWithClassMethod class]];
//	[[[mock stub] andReturn:@"TestFoo"] method1];
//    [mock stopMocking];
//	GHAssertEqualObjects(@"Foo", [TestClassWithClassMethod method1], @"Should not have stubbed method.");
//}


// --------------------------------------------------------------------------------------
//	mocks should honour the NSObject contract, etc.
// --------------------------------------------------------------------------------------

- (void)testRespondsToValidSelector
{
	GHAssertTrue([mock respondsToSelector:@selector(lowercaseString)], nil);
}

- (void)testDoesNotRespondToInvalidSelector
{
	GHAssertFalse([mock respondsToSelector:@selector(fooBar)], nil);
}

- (void)testCanStubValueForKeyMethod
{
	id returnValue;
	
	mock = [OCMockObject mockForClass:[NSObject class]];
	[[[mock stub] andReturn:@"SomeValue"] valueForKey:@"SomeKey"];
	
	returnValue = [mock valueForKey:@"SomeKey"];
	
	GHAssertEqualObjects(@"SomeValue", returnValue, @"Should have returned value that was set up.");
}

- (void)testWorksWithTypeQualifiers
{
	id myMock = [OCMockObject mockForProtocol:@protocol(ProtocolWithTypeQualifierMethod)];
	
	GHAssertNoThrow([[myMock expect] aSpecialMethod:"foo"], @"Should not complain about method with type qualifiers.");
	GHAssertNoThrow([myMock aSpecialMethod:"foo"], @"Should not complain about method with type qualifiers.");
}


// --------------------------------------------------------------------------------------
//  some internal tests
// --------------------------------------------------------------------------------------

- (void)testReRaisesFailFastExceptionsOnVerify
{
	@try
	{
		[mock lowercaseString];
	}
	@catch(NSException *exception)
	{
		// expected
	}
	GHAssertThrows([mock verify], @"Should have reraised the exception.");
}

- (void)testReRaisesRejectExceptionsOnVerify
{
	mock = [OCMockObject niceMockForClass:[NSString class]];
	[[mock reject] uppercaseString];
	@try
	{
		[mock uppercaseString];
	}
	@catch(NSException *exception)
	{
		// expected
	}
	GHAssertThrows([mock verify], @"Should have reraised the exception.");
}


- (void)testCanCreateExpectationsAfterInvocations
{
	[[mock expect] lowercaseString];
	[mock lowercaseString];
	[mock expect];
}

@end
