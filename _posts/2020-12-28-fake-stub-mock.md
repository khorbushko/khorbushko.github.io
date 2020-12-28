---
layout: post
comments: true
title: "Fake, Stub, Mock..."
categories: article
tags: [iOS, test]
excerpt_separator: <!--more-->
comments_id: 19

author:
- kyryl horbushko
- Lviv
---

Testing is an essential component of quality during any process. App development is not an exception. 

Often, during testing, we are faced with a situation, when real data is not available, or some part of real implementation logic is complex and currently not tested but required to be used, so some-how simulated. Such situations require additional efforts and increase the complexity of tests.
<!--more-->

## Intro

Complexity - is something that we would like to keep at a minimum in most systems. 

There are a lot of different concepts that can be applied to the process of creating a good test - [F.I.R.S.T.](https://www.amazon.com/Clean-Coder-Conduct-Professional-Programmers/dp/0137081073/ref=sr_1_1?s=books&ie=UTF8&qid=1326135682&sr=1-1), [Given-When-Then](https://martinfowler.com/bliki/GivenWhenThen.html), etc. All of them propagate simplicity as one of the core concepts. 

> if u find it hard to determine simplicity criteria - u can refer to results [provided by Kent Beck](https://www.agilealliance.org/glossary/rules-of-simplicity/)

Another reason for reducing complexity - is speed. The complex test is slow, but we always need speed in a test - this allows us to run tests every time we want and get an almost instant report about the current product quality state.

Returning to tests, we also can apply simplification to a testing subject in parallel to the tests themselves. This makes any test even more clear and concrete - everyone can easily understand what tested, understand why it fails (if any), and understand how some part of code should work.

How we can simplify testing code? To answer this question we should review the reason for this question. 

Many objects use dependencies - so every testing need's to create them. Imagine a situation when dependencies use another dependency and so on (not a very good coding practice, but it's life, the ideal situation is rare. Rare because of time cost, rate because of some other reason. We always can find some :], but truth is that because we can make an error because sometimes we are too lazy to do things right). 

Another case - we may use remote service in the real-time application or some async result, but how we can test such response or some other operation related to it? How to test some complex precondition for some situations? How to make it fast? How to get the same input for tests every time?

Yep, a lot of cases... 

For simplification, we can use something that simulates these complex operations, something that equivalent and not important for the testing system, something that represents data structure but not a real one. 

The common name for such objects - **Test Doubles**.

>  **Test Double** - object that can be used instead of real objects during a test.

We may require different objects for different test purposes. Indeed, this object has few types: **Mock**, **Stub**, **Fake**, other.

> Introduction of these names was done by Gerard Meszaros [here is an article about them](http://xunitpatterns.com/Test%20Double.html)

## Fake

**Fake object** - object that has the same functionality as a real object, but different implementation. Often this implementation is simplified. 

Fake objects usually used as *shortcut for required functionality* - this provide speed and expected result. It's often an object that adopts some requirements from the protocol.

Often, as a sample u found an in-memory database - such a database is *never will be used on production*, but for the test, the purpose is the perfect one.

One more property of such objects - they are *not affect the SUT* (system under test), instead, these objects *simplify the process of testing*, and so, *have some limited capabilities*.


{% highlight swift %}
final class SystemInfo {
    var foo: Int?
    var bar: Int?
}

protocol SystemInformationProvider {
    func fetchSystemInfo() -> SystemInfo
}

final class SystemInfoViewModel {

    let infoProvider: SystemInformationProvider
    
    // MARK: - Lifecycle
    
    init(infoProvider: SystemInformationProvider) {
        self.infoProvider = infoProvider
    }
    
    func fetchSystemInfo() -> SystemInfo {
        // simplified for sample logic
        infoProvider.fetchSystemInfo()
    }
}

final class SystemInfoViewModelTest: XCTestCase {
    
    // This is a fake object
    private final class FakeSystemInfoProvider: SystemInformationProvider {
        func fetchSystemInfo() -> SystemInfo {
            let info = SystemInfo()
            info.bar = 1
            info.foo = 2
            return info
        }
    }
    
    private var sut: SystemInfoViewModel!
    private var provider: FakeSystemInfoProvider!
    
    // MARK: - Lifecycle
    
    override func setUp() {
        super.setUp()
        
        configureSUT()
    }
    
    override func tearDown() {
        super.tearDown()
        
        sut = nil
        provider = nil
        
        XCTAssertNil(sut)
        XCTAssertNil(provider)
    }
    
    // MARK: - Tests
    
    func testGivenViewModelWhenCreatedShouldProvideSystemInfoWithCorrectBarValue() {
        let system = sut.fetchSystemInfo()
        XCTAssertEqual(system.bar, 1, "bar value should be ...")
    }
    
    // MARK: - Private
    
    private func configureSUT() {
        provider = FakeSystemInfoProvider()
        sut = SystemInfoViewModel(infoProvider: provider)
        
        XCTAssertNotNil(provider)
        XCTAssertNotNil(sut)
    }
}
{% endhighlight %}

## Stub

**Stub object** - object that has some *dummy data* for specific calls required by tests and some mechanism that allow return specific value required by tests - some *state*.

Every time we need to check if some call is executed, instead of introducing a complex solution using a real object, we can simplify it by using Stub one.

Sometimes u can hear **Spy object** - this is the same Stub object but with *ability to record received information* about how they are used.

Such objects are also *not used in production* and so may behave in a strange, not-real manner. This is ok, thus the purpose of such an object is to *simplify the process of testing*. 

A good example may be REST API response - u always know that some operation during the test will return the expected result - predefined answer.

{% highlight swift %}
final class SystemInfo {
    var foo: Int?
    var bar: Int?
}

protocol SystemInformationProvider {
    func fetchSystemInfo() -> SystemInfo
}

final class SystemInfoViewModel {

    let infoProvider: SystemInformationProvider

    // MARK: - Lifecycle

    init(infoProvider: SystemInformationProvider) {
        self.infoProvider = infoProvider
    }

    func fetchSystemInfo() -> SystemInfo {
        // simplified for sample logic
        infoProvider.fetchSystemInfo()
    }
}

final class SystemInfoViewModelTest: XCTestCase {

    // This is a stub object
    private final class StubSystemInfoProvider: SystemInformationProvider {
        // state that define return value
        var returnSystemInfoOptionA: Bool = true
        func fetchSystemInfo() -> SystemInfo {
            if returnSystemInfoOptionA {
                let info = SystemInfo()
                info.foo = 1
                return info
            } else {
                return SystemInfo()
            }
        }
    }

    private var sut: SystemInfoViewModel!
    private var provider: StubSystemInfoProvider!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()

        configureSUT()
    }

    override func tearDown() {
        super.tearDown()

        sut = nil
        provider = nil

        XCTAssertNil(sut)
        XCTAssertNil(provider)
    }

    // MARK: - Tests

    func testGivenViewModelWhenCreatedShouldCallSystemInfoProviderWhenFetchSystemInfoData() {
        // change existing stub state to retrive data we need
        provider.returnSystemInfoOptionA = true
        
        let info = sut.fetchSystemInfo()
        XCTAssertEqual(info.foo, 1)
    }

    // MARK: - Private

    private func configureSUT() {
        provider = StubSystemInfoProvider()
        sut = SystemInfoViewModel(infoProvider: provider)

        XCTAssertNotNil(provider)
        XCTAssertNotNil(sut)
    }
}
{% endhighlight %}

## Mock

**Mock objects** - objects that used to *register received calls from test object* and so we can *verify* it. This type of object is also *not used in production*. In other words, object contains some state, that can be cheked during test.

Sometimes Mock object is called a special type of Stub object with extra states inside. Additional states and some other parameters allow checking whenever execution is processed expectedly. So *verification* is an essential part of such objects - u always *can check your expectation*.

{% highlight swift %}
protocol SystemInformationProvider {
    var systemVersion: Int { get }
    
    func changeSystemVersionTo(_ version: Int)
}

final class SystemInfoViewModel {
    
    let infoProvider: SystemInformationProvider
    
    // MARK: - Lifecycle
    
    init(infoProvider: SystemInformationProvider) {
        self.infoProvider = infoProvider
    }
    
    func changeVersion(_ version: Int) {
        infoProvider.changeSystemVersionTo(version)
    }
}

final class SystemInfoViewModelTest: XCTestCase {
    
    // This is a mock object
    private final class MockSystemInfoProvider: SystemInformationProvider {
        private(set) var systemVersion: Int = 0 // value
        // state to check
        private(set) var changeSystemCallCount: Int = 0 
        
        func changeSystemVersionTo(_ version: Int) {
            // simplified logic for demo
            systemVersion = version
            changeSystemCallCount += 1
        }
        
        func verifyVersionChange(_ expectedVersion: Int, callCount: Int) {
            XCTAssertEqual(expectedVersion, systemVersion)
            XCTAssertEqual(callCount, changeSystemCallCount)
        }
    }
    
    private var sut: SystemInfoViewModel!
    private var provider: MockSystemInfoProvider!
    
    // MARK: - Lifecycle
    
    override func setUp() {
        super.setUp()
        
        configureSUT()
    }
    
    override func tearDown() {
        super.tearDown()
        
        sut = nil
        provider = nil
        
        XCTAssertNil(sut)
        XCTAssertNil(provider)
    }
    
    // MARK: - Tests
    
    func testGivenViewModelWhenCreatedShouldBeAbleToChangeVersion() {
        let newVersion = 1111
        sut.changeVersion(newVersion)
        provider.verifyVersionChange(newVersion, callCount: 1)
    }
    
    // MARK: - Private
    
    private func configureSUT() {
        provider = MockSystemInfoProvider()
        sut = SystemInfoViewModel(infoProvider: provider)
        
        XCTAssertNotNil(provider)
        XCTAssertNotNil(sut)
    }
}
{% endhighlight %}

<br>
> Stub and Mock a bit similar, but "There is a difference in that the stub uses state verification while the mock uses behavior verification." [M.Fowler](https://martinfowler.com/articles/mocksArentStubs.html)

## Dummy

**Dummy objects** - objects that are *not use during tests* and used only to *allow compilation to be successful*.

{% highlight swift %}
protocol SystemInformationProvider {
    func performOperation()
}

final class SystemInfoViewModel {
    
    let infoProvider: SystemInformationProvider
    
    private(set) var someValue: Int = 0
    
    // MARK: - Lifecycle
    
    init(infoProvider: SystemInformationProvider) {
        self.infoProvider = infoProvider
    }
    
    func doSometingNotRelatedToInfoProvider() {
        someValue += 1
    }
}

final class SystemInfoViewModelTest: XCTestCase {
    
    // This is a dummy object
    private final class DummySystemInfoProvider: SystemInformationProvider {
        func performOperation() {
            /*do nothing*/
        }
    }
    
    private var sut: SystemInfoViewModel!
    private var provider: DummySystemInfoProvider!
    
    // MARK: - Lifecycle
    
    override func setUp() {
        super.setUp()
        
        configureSUT()
    }
    
    override func tearDown() {
        super.tearDown()
        
        sut = nil
        provider = nil
        
        XCTAssertNil(sut)
        XCTAssertNil(provider)
    }
    
    // MARK: - Tests
    
    func testGivenViewModelWhenCreatedShouldBeAbleToDoSomething() {
        XCTAssertEqual(sut.someValue, 0)
        sut.doSometingNotRelatedToInfoProvider()
        XCTAssertEqual(sut.someValue, 1)
    }
    
    // MARK: - Private
    
    private func configureSUT() {
        provider = DummySystemInfoProvider()
        sut = SystemInfoViewModel(infoProvider: provider)
        
        XCTAssertNotNil(provider)
        XCTAssertNotNil(sut)
    }
}
{% endhighlight %}

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-12-28-fake-stub-mock/test_doubles.svg" alt="test_doubles" width="550"/>
</div>

So, to summarize:

1. **Fake** -	same functionality, but different implementation
2. **Stub** - provide predefined data

	a. ***Spy*** - provide predefined data and logs of actions
3. **Mock** - register calls and can check your expectation
4. **Dummy** - allow tests to meet compiler requirements, not used in tests

## Resources

* [Martin Fowler defienition](https://martinfowler.com/bliki/TestDouble.html)
* [Mocks Aren't Stubs by Martin Fowler](https://martinfowler.com/articles/mocksArentStubs.html)
* [Given-When-Then](https://martinfowler.com/bliki/GivenWhenThen.html)
* [Test Doubles](https://blog.pragmatists.com/test-doubles-fakes-mocks-and-stubs-1a7491dfa3da)
* [SO discussion](https://stackoverflow.com/questions/346372/whats-the-difference-between-faking-mocking-and-stubbing)
* [F.I.R.S.T. - chapter from Clean-Coder](https://www.amazon.com/Clean-Coder-Conduct-Professional-Programmers/dp/0137081073/ref=sr_1_1?s=books&ie=UTF8&qid=1326135682&sr=1-1)

[download source]({% link assets/posts/images/2020-12-28-fake-stub-mock/source/test_doubles.playground.zip %})
