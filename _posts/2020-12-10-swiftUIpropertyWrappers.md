---
layout: post
comments: true
title: "SwiftUI property wrappers"
categories: article
tags: [iOS, SwiftUI, propertyWrapper]
excerpt_separator: <!--more-->
comments_id: 12

author:
- kyryl horbushko
- Lviv
---


Within `SwiftUI` we may have a lot of options on how to handle data. To help us out with this, Apple has introduced a few `propertyWrappers` for us.

But to make everything clear may be a bit complicated at first. So I decided to check every wrapper and test the functionality behind it.
<!--more-->

The list contains 15 items (at the moment of writing). So let's review them all.

## @AppStorage

A property wrapper type that reflects a value from `UserDefaults` and **invalidates** a view on a change in value in that user default.

This means that this wrapper performs re-render `View` on every change and store value in `UserDefaults`.

{% highlight swift %}
struct Content: View {
    
    private enum Keys {
    
        static let numberOne = "myKey"
    }
    
    @AppStorage(Keys.numberOne) var keyValue2: String = "no value"

    var body: some View {
        VStack {
            Button {
                keyValue2 = "no value"
                print(
                    UserDefaults.standard.value(forKey: Keys.numberOne) as! String
                )
            } label: {
                Text("Update")
            }
            
            Text(keyValue2)
        }
        .padding()
        .frame(width: 100)
    }
}
{% endhighlight %}

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-12-10-swiftUIpropertyWrappers/@AppStorage_demo.gif" alt="@AppStorage" width="650"/>
</div>

> not secure and should not be used to store sensitive data.

## @Binding 

A property wrapper type that can read and write a value owned by a source of truth.
Use a binding to create a two-way connection between a property that stores data and a view that displays and changes the data. A binding connects a property to a source of truth stored elsewhere, instead of storing data directly. For example, a button that toggles between play and pause can create a binding to a property of its parent view using the `Binding` property wrapper.

Same as `@State`, but value stored non in the same View, and only observation is done and on any change, the view will re-render itself.

{% highlight swift %}
struct Content: View {
    
    final class ContentViewModel {

        @Published var counter: Int = 0
        private var cancellable: AnyCancellable?

        init() {
            cancellable = Timer
                .publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .sink(receiveValue: { (_) in
                    self.counter += 1
                })
        }
    }
    
    private struct TickObservable: View {
        
        @Binding var tickCount: Int
        
        var body: some View {
            Text("Tick count - \(tickCount)")
        }
    }
    
    @State private var tickCount: Int = 0
    private var viewModel = ContentViewModel()

    var body: some View {
        VStack {
            TickObservable(tickCount: $tickCount)
        }
        .onReceive(viewModel.$counter) { (value) in
            self.tickCount = value
        }
    }
}
{% endhighlight %}

Here we have a `TickObservable` view that has a `@Binding` value - a value that is stored outside of this `View` but should be displayed and updated in this view. 

`ContentViewModel` has some logic that generates updates (using a timer) - we may skip this as this point not important for a `@Binding` sample.

`Content` view - has declared `@State` property that changes every time as we receive an update from `ViewModel`.

Here, `@Binding` - an ideal solution for propagating changes down to hierarchy.

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-12-10-swiftUIpropertyWrappers/@Binding_demo.gif" alt="@Binding" width="650"/>
</div>

## @Environment

A property wrapper that reads a value from a view's environment. Use the `Environment` property wrapper to read a value stored in a view's environment. Indicate the value to read using an ``EnvironmentValues`` key path in the property declaration.

In most cases, this wrapper is used for accessing system-defined values, but it's also possible to define their own `Environment` property and access it from any `View`.

{% highlight swift %}
private struct StoredValueKey: EnvironmentKey {
    static var defaultValue: Int = 1
}

extension EnvironmentValues {
    var myValueName: Int {
        get { self[StoredValueKey.self] }
        set { self[StoredValueKey.self] = newValue }
    }
}

struct Content: View {
    
    @Environment(\.myValueName) private var myValueName: Int
    
    var body: some View {
        VStack {
            Text("Own Environment value - \(myValueName)")
        }
    }
}
{% endhighlight %}

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-12-10-swiftUIpropertyWrappers/@Environment_demo.gif" alt="@Environment" width="650"/>
</div>

## @EnvironmentObject

A property wrapper type for an observable object supplied by a parent or ancestor view.
An environment object invalidates the current view whenever the observable object changes. If you declare a property as an environment object, be sure to set a corresponding model object on an ancestor view by calling its `View/environmentObject(_:)` modifier.
A convenient way to pass data indirectly, instead of passing data from parent view to child to grandchild, especially if the child view doesn't need it.

{% highlight swift %}
struct Content: View {
    
    private final class MyObject: ObservableObject {
        let value: String
        
        init(value: String) {
            self.value = value
        }
    }
    
    private struct InnerContent: View {
        @EnvironmentObject var object: MyObject
        
        var body: some View {
            Text(object.value)
        }
    }
    
    private let object: MyObject
    
    init() {
        object = MyObject(value: "hello")
    }
    
    var body: some View {
        InnerContent()
            .environmentObject(object)
    }
}
{% endhighlight %}

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-12-10-swiftUIpropertyWrappers/@EnvironmentObject_demo.gif" alt="@EnvironmentObject" width="650"/>
</div>

## @FetchRequest

A property wrapper type that makes fetch requests and retrieves the results from a Core Data store.

This change is related to `CoreData`. Thankfully to this `propertyWrapper`, we may remove the boiler part of work related to `CoreData` `FetchRequest` preparation for `SwiftUI`. To do so, we simply set environment value with keypath `managedObjectContext` to current context and we are ready to go.

{% highlight swift %}
// declare Entity
@objc(TestEntity)
public class TestEntity: NSManagedObject {
    @NSManaged public var propertyA: String?
    @NSManaged public var propertyB: Int64
}
extension TestEntity : Identifiable { }

// setup in-memory container
let container: NSPersistentContainer
container = NSPersistentContainer(name: "Model")
container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
container.loadPersistentStores(completionHandler: { (storeDescription, error) in
    if let error = error as NSError? {
        fatalError("Unresolved error \(error), \(error.userInfo)")
    }
    
    let desc = NSEntityDescription.entity(forEntityName: "TestEntity", in: container.viewContext)!
    let entity = NSManagedObject(entity: desc, insertInto: container.viewContext)
    entity.setValue("Hello", forKey: "propertyA")
    entity.setValue(1, forKey: "propertyB")
    print(entity)
    try! container.viewContext.save()
    print("Stored")
    
})

struct Content: View {
        
    @FetchRequest(
        sortDescriptors: [],
        animation: .default)
    private var items: FetchedResults<TestEntity>
    
    var body: some View {
        let value = items.first?.value(forKey: "propertyA") as? String ?? "no value"
        Text("Item propertyA is:  \(value)")
            .lineLimit(5)
            .frame(width: 250, height: 100)
    }
}

let view = Content()
    .environment(\.managedObjectContext, container.viewContext)
{% endhighlight %}

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-12-10-swiftUIpropertyWrappers/@FetchRequest_demo.gif" alt="@FetchRequest" width="650"/>
</div>

## @FocusedBinding

A convenience property wrapper for observing and automatically unwrapping state bindings from the focused view or one of its ancestors.

Can be used as part of the mechanism of an alternative way to pass data between `View` (like `ObservableObject`)

{% highlight swift %}
struct ListenerTextKey : FocusedValueKey {
    typealias Value = Binding<String>
}

extension FocusedValues {
    var listener: ListenerTextKey.Value? {
        get { self[ListenerTextKey.self] }
        set { self[ListenerTextKey.self] = newValue }
    }
}

struct ContentView: View {
    
    @State var inputText: String = ""
    
    var body: some View {
        VStack {
            InputView()
            ListenerView()
        }
    }
}

struct InputView : View {
    
    @State private var inputText = ""
    
    var body: some View {
        TextField("Input", text: $inputText)
            .focusedValue(\.listener, $inputText)
    }
}

struct ListenerView: View {
    
    @FocusedBinding(\.listener) private var text: String?
    
    var body: some View {
        Text(text ?? "no value")
    }
}
{% endhighlight %}

> at the moment of writing is not working - [*"unfortunately some bugs in the seed prevent it from behaving as expected"*](https://developer.apple.com/forums/thread/651748)

## @FocusedValue

A property wrapper for observing values from the focused view or one of its ancestors.

Same as `@FocusedBinding` but doesn't unwrap the value, instead, u should use the `wrappedValue` prop.

{% highlight swift %}
@FocusedValue(\.listener) private var value

value?.wrappedValue
{% endhighlight %}

> at the moment of writing is not working - [*"unfortunately some bugs in the seed prevent it from behaving as expected"*](https://developer.apple.com/forums/thread/651748)

## @GestureState 

A property wrapper type that updates a property while the user performs a gesture and resets the property back to its initial state when the gesture ends.

U can't change this property directly - is a get-only property.

{% highlight swift %}
struct ContentView: View {
    
    @GestureState var gestureOffset: CGFloat = 0
    
    var body: some View {
        VStack {
            ZStack {
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: 150, height: 100)
                    .cornerRadius(12)
                VStack {
                    Spacer()
                    Text("Hello")
                    Spacer()
                }
            }
            .frame(width: 150, height: 100)
            .animation(.spring())
            .offset(x: gestureOffset)
            .gesture(
                DragGesture()
                    .updating($gestureOffset, body: { (value, state, transaction) in
                        state = value.translation.width
                    })
                    .onEnded({ (_) in
                        print("End - ", gestureOffset)
                    })
            )
            .animation(.spring())
        }
    }
}
{% endhighlight %}

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-12-10-swiftUIpropertyWrappers/@GestureState_demo.gif" alt="@GestureState" width="650"/>
</div>

## @Namespace 

A dynamic property type that allows access to a namespace defined by the persistent identity of the object containing the property (e.g. a view).

In other words - this is an identifier for view with the same ID in a different hierarchy. Can be used for creating an animation of geometry transition from one view to another. Good use-case scenario - "Hero"-animation.

{% highlight swift %}
struct ContentView: View {
    @Namespace private var namespace
    @State private var isPrimaryViewVisible = true
    
    var body: some View {
        ZStack {
            if isPrimaryViewVisible {
                PrimaryView(namespace: namespace)
            } else {
                SecondaryView(namespace: namespace)
            }
        }
        .frame(width: 100, height: 400)
        .onTapGesture {
            withAnimation {
                self.isPrimaryViewVisible.toggle()
            }
        }
    }
}

struct PrimaryView: View {
    
    let namespace: Namespace.ID
    
    var body: some View {
        VStack {
            Circle()
                .fill(Color.red)
                .frame(width: 30, height: 30)
                .matchedGeometryEffect(id: "shape", in: namespace)
            Image(uiImage: UIImage(named: "test.jpg")!)
                .resizable()
                .frame(width: 50, height: 100)
                .matchedGeometryEffect(id: "image", in: namespace)
            Spacer()
        }
    }
}

struct SecondaryView: View {
    
    let namespace: Namespace.ID

    var body: some View {
        VStack {
            Spacer()
            Image(uiImage: UIImage(named: "test.jpg")!)
                .resizable()
                .frame(width: 100, height: 200)
                .matchedGeometryEffect(id: "image", in: namespace)
            Circle()
                .fill(Color.blue)
                .frame(width: 60, height: 60)
                .matchedGeometryEffect(id: "shape", in: namespace)
        }
    }
}
{% endhighlight %}

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-12-10-swiftUIpropertyWrappers/@Namespace_demo.gif" alt="@Namespace" width="650"/>
</div>

> Default animation - fadeIn and fadeOut.


## @ObservedObject 

A property wrapper type that subscribes to an observable object and invalidates a view whenever the observable object changes. 

Should be a reference type. A class should define at least one `@Published` property and if u want to observe that value, mark that object as `@ObservedObject`. Class should conform to `ObservableObject`. So this can be compared to `@State` property, but in a separate class - result from the same.

{% highlight swift %}
struct Content: View {
    
    final class ContentViewModel: ObservableObject {
        
        @Published var textValue: String = ""
        private var subscription: AnyCancellable?
        
        init() {
            subscription = ["hello"]
                .publisher
                .delay(for: .seconds(3), scheduler: DispatchQueue.main)
                .sink { (value) in
                    self.textValue = value
                }
        }
    }
    
    @ObservedObject private var viewModel =  ContentViewModel()

    var body: some View {
        VStack {
            Text(viewModel.textValue)
                .frame(width: 100, height: 50)
                .foregroundColor(Color.black)
            
        }
        .padding()
    }
}
{% endhighlight %}

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-12-10-swiftUIpropertyWrappers/@ObservedObject_demo.gif" alt="@ObservedObject" width="650"/>
</div>

## @ScaledMetric 

A dynamic property that scales a numeric value.

{% highlight swift %}
struct ContentView: View {

    @ScaledMetric(relativeTo: .caption) var textSize: CGFloat = 8
    @ScaledMetric(relativeTo: .body) var padding: CGFloat = 10
    
    var body: some View {
        VStack {
            Text("Hello")
                .font(.system(size: textSize))
                .padding(padding)
                .border(Color.black)
        }
        .background(Color.white)
    }
}

struct ComparisonView: View {

    var body: some View {
        VStack {
            Text("default")
            ContentView()
            Text("accessibilityXXXL")
            ContentView()
                .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
        }
        .frame(width: 200, height: 400)
    }
}
{% endhighlight %}

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-12-10-swiftUIpropertyWrappers/@ScaledMetric_demo.gif" alt="@ScaledMetric" width="650"/>
</div>

> `relativeTo` - define whats font size to match

## @SceneStorage 

A property wrapper type that reads and writes to persisted, per-scene storage.

This property acts like a `@State` but unlike `@State` it's persistent. Also, this persistence applied only to selected `Scene` only.

{% highlight swift %}
@SceneStorage("key") 
private var propertyName: propertyType = propertyValue
{% endhighlight %}

Thus, `@SceneStorage` is like `@State`, we can move it as binding to another view using the `$` symbol.

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-12-10-swiftUIpropertyWrappers/@SceneStorage_demo.gif" alt="@SceneStorage" width="650"/>
</div>

> not secure and should not be used to store sensitive data.

## @State 

A property wrapper type that can read and write a value managed by `SwiftUI`.

Use this wrapper on values that are owned by View and can be changed by View. Apple recommends that this property always be a private one, in other cases View may not be rebuilt.

> You should only access a state property from inside the view’s body, or from methods called by it. For this reason, declare your state properties as private, to prevent clients of your view from accessing them. It is safe to mutate state properties from any thread. [source](https://developer.apple.com/documentation/swiftui/state)

{% highlight swift %}
struct StateTestView: View {
    
    @State private var isOn = false
    
    var body: some View {
        VStack {
            Button(action: {
                withAnimation {
                    isOn.toggle()
                }
            }, label: {
                Text("Tap me")
            })
            
            VStack {
                isOn ? Color.green : Color.red
            }
            .animation(.easeOut)
            .frame(height: 100)
            .padding()
        }
        .padding()
    }
}
{% endhighlight %}

Put a breakpoint in the body and press the button - as soon as u do, u will observe, that body is rebuilt (re-rendered) and a new value applied.

> Use the state as the single source of truth for a given view.

`@State` property also can be used as `dataValue` via [`wrappedValue`](https://developer.apple.com/documentation/swiftui/state/wrappedvalue) or as `bindingValue` via `$` followed by propertyName - a [`projected value`](https://developer.apple.com/documentation/swiftui/state/projectedvalue) (`Binding<Value>`). Usually, this is used for passing a value down to a view hierarchy.

{% highlight swift %}
struct StateTestView: View {
    @State private var text = ""
    
    var body: some View {
        VStack {
            TextField("name", text: $text) // <- binding
            Text(text)					   // <- value
        }
        .padding()
    }
}
{% endhighlight %}

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-12-10-swiftUIpropertyWrappers/@State_demo.gif" alt="@State" width="650"/>
</div>


## @StateObject

A property wrapper type that instantiates an observable object.
In other words - this is @ObservedObject that does not recreate whenever and works like @State. 

{% highlight swift %}
struct ContentView: View {
    
    final class MyClassObj: ObservableObject {
        
        @Published var counter: Int = 0
    }
    
    struct NestedView: View {
        @StateObject
//        @ObservedObject // <- old approach
        var classObject: MyClassObj = MyClassObj()
        
        var body: some View {
            VStack {
                Text("Count = \(classObject.counter)")
                Button("Tap me") {
                    classObject.counter += 1
                }
            }
        }
    }
    
    @State private var parentCounter: Int = 0
    
    var body: some View {
        VStack {
            HStack {
                Text("Parent counter \(parentCounter)")
                Button(action: {
                    parentCounter += 1
                }, label: {
                    Text("Tap to increase paretnCounter")
                })
            }
            .padding()
            NestedView()
        }
        .frame(width: 200, height: 400)
    }
}
{% endhighlight %}

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-12-10-swiftUIpropertyWrappers/@StateObject_demo.gif" alt="@StateObject" width="650"/>
</div>


## @UIApplicationDelegateAdaptor 

A property wrapper that is used in `App` to provide a delegate from UIKit.

{% highlight swift %}
class HelloAppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        // use any callback
        return true
    }
}

// in the app

@main
struct HelloApp: App {
    @UIApplicationDelegateAdaptor(HelloAppDelegate.self) var appDelegate
}
{% endhighlight %}

> You also can conform `HelloAppDelegate` to `ObservableObject` and later share this delegate and use callbacks.
{% highlight swift %}
@EnvironmentObject var appDelegate: HelloAppDelegate
{% endhighlight %}

> For macOS there is `@NSApplicationDelegateAdaptor`

## @ViewBuilder

A custom parameter attribute that constructs views from closures.

This can be widely used during building `View`.

{% highlight swift %}
struct ContentView: View {
    
    @ViewBuilder private var fewViews: some View {
        Text("Hello")
        Text("Everyone!")
    }

    var body: some View {
        VStack {
            fewViews
            Container {
                Text("Hello from container")
                Text("to everyone")
            }
        }
        .frame(width: 300, height: 400)
    }
}

struct Container<C>: View where C: View {
    
    let content: C
    
    init(@ViewBuilder content: @escaping () -> C) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(Color.red)
    }
}
{% endhighlight %}

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-12-10-swiftUIpropertyWrappers/@ViewBuilder_demo.png" alt="@ViewBuilder" width="650"/>
</div>


## Source of TRUTH

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-12-10-swiftUIpropertyWrappers/source_of_thuth.pdf" alt="source_of_thuth" width="450"/>
</div>

[Download source here]({% link assets/posts/images/2020-12-10-swiftUIpropertyWrappers/sources/propertyWrapper_swiftUI.playground.zip %})