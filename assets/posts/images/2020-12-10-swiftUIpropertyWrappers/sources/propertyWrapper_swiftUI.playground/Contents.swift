import UIKit

import SwiftUI
import Combine

import PlaygroundSupport

// @State
//
//struct StateTestView: View {
//
//    @State private var isOn = false
//
//    var body: some View {
//        VStack {
//            Button(action: {
//                withAnimation {
//                    isOn.toggle()
//                }
//            }, label: {
//                Text("Tap me")
//            })
//
//            VStack {
//                isOn ? Color.green : Color.red
//            }
//            .animation(.easeOut)
//            .frame(height: 100)
//            .padding()
//        }
//        .padding()
//    }
//}
//
//struct StateTestView_Values: View {
//    @State private var text = ""
//
//    var body: some View {
//        VStack {
//            TextField("name", text: $text)
//            Text(text)
//        }
//        .padding()
//    }
//}
//
//PlaygroundPage.current.liveView = UIHostingController(rootView: StateTestView())


// @Binding

//struct Content: View {
//
//    final class ContentViewModel {
//
//        @Published var counter: Int = 0
//        private var cancellable: AnyCancellable?
//
//        init() {
//            cancellable = Timer
//                .publish(every: 1, on: .main, in: .common)
//                .autoconnect()
//                .sink(receiveValue: { (_) in
//                    self.counter += 1
//                })
//        }
//    }
//
//    private struct TickObservable: View {
//
//        @Binding var tickCount: Int
//
//        var body: some View {
//            Text("Tick count - \(tickCount)")
//        }
//    }
//
//    @State private var tickCount: Int = 0
//    private var viewModel = ContentViewModel()
//
//    var body: some View {
//        VStack {
//            TickObservable(tickCount: $tickCount)
//        }
//        .onReceive(viewModel.$counter) { (value) in
//            self.tickCount = value
//        }
//    }
//}
//
//PlaygroundPage.current.liveView = UIHostingController(rootView: Content())

// @ObservedObject
//
//struct Content: View {
//
//    final class ContentViewModel: ObservableObject {
//
//        @Published var textValue: String = ""
//        private var subscription: AnyCancellable?
//
//        init() {
//            subscription = ["hello"]
//                .publisher
//                .delay(for: .seconds(3), scheduler: DispatchQueue.main)
//                .sink { (value) in
//                    self.textValue = value
//                }
//        }
//    }
//
//    @ObservedObject private var viewModel =  ContentViewModel()
//
//    var body: some View {
//        VStack {
//            Text(viewModel.textValue)
//                .frame(width: 100, height: 50)
//                .foregroundColor(Color.black)
//
//        }
//        .padding()
//    }
//}
//
//PlaygroundPage.current.liveView = UIHostingController(rootView: Content())

//@EnvironmentObject
//
//struct Content: View {
//
//    private final class MyObject: ObservableObject {
//        let value: String
//
//        init(value: String) {
//            self.value = value
//        }
//    }
//
//    private struct InnerContent: View {
//        @EnvironmentObject var object: MyObject
//
//        var body: some View {
//            Text(object.value)
//        }
//    }
//
//    private let object: MyObject
//
//    init() {
//        object = MyObject(value: "hello")
//    }
//
//    var body: some View {
//        InnerContent()
//            .environmentObject(object)
//    }
//}
//
//PlaygroundPage.current.liveView = UIHostingController(rootView: Content())

//@Environment
//
//private struct StoredValueKey: EnvironmentKey {
//    static var defaultValue: Int = 1
//}
//
//extension EnvironmentValues {
//    var myValueName: Int {
//        get { self[StoredValueKey.self] }
//        set { self[StoredValueKey.self] = newValue }
//    }
//}
//
//struct Content: View {
//
//    @Environment(\.myValueName) private var myValueName: Int
//
//    var body: some View {
//        VStack {
//            Text("Own Environment value - \(myValueName)")
//        }
//    }
//}
//
//PlaygroundPage.current.liveView = UIHostingController(rootView: Content())

// @GestureState
//
//struct ContentView: View {
//
//    @GestureState var gestureOffset: CGFloat = 0
//
//    var body: some View {
//        VStack {
//            ZStack {
//                Rectangle()
//                    .fill(Color.blue)
//                    .frame(width: 150, height: 100)
//                    .cornerRadius(12)
//                VStack {
//                    Spacer()
//                    Text("Hello")
//                    Spacer()
//                }
//            }
//            .frame(width: 150, height: 100)
//            .animation(.spring())
//            .offset(x: gestureOffset)
//            .gesture(
//                DragGesture()
//                    .updating($gestureOffset, body: { (value, state, transaction) in
//                        state = value.translation.width
//                    })
//                    .onEnded({ (_) in
//                        print("End - ", gestureOffset)
//                    })
//            )
//            .animation(.spring())
//        }
//    }
//}
//
//PlaygroundPage.current.liveView = UIHostingController(rootView: ContentView())

// @AppStorage

//struct Content: View {
//
//    private enum Keys {
//
//        static let numberOne = "myKey"
//    }
//
//    @AppStorage(Keys.numberOne) var keyValue2: String = "no value"
//
//    var body: some View {
//        VStack {
//            Button {
//                keyValue2 = "Hello"
//                print(
//                    UserDefaults.standard.value(forKey: Keys.numberOne) as! String
//                )
//            } label: {
//                Text("Update")
//            }
//
//            Text(keyValue2)
//        }
//        .padding()
//        .frame(width: 100)
//    }
//}
//
//PlaygroundPage.current.liveView = UIHostingController(rootView: Content())

//@FetchRequest
//
//import CoreData
//
//// declare Entity
//@objc(TestEntity)
//public class TestEntity: NSManagedObject {
//    @NSManaged public var propertyA: String?
//    @NSManaged public var propertyB: Int64
//}
//extension TestEntity : Identifiable { }
//
//// setup in-memory container
//let container: NSPersistentContainer
//container = NSPersistentContainer(name: "Model")
//container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
//container.loadPersistentStores(completionHandler: { (storeDescription, error) in
//    if let error = error as NSError? {
//        fatalError("Unresolved error \(error), \(error.userInfo)")
//    }
//
//    let desc = NSEntityDescription.entity(forEntityName: "TestEntity", in: container.viewContext)!
//    let entity = NSManagedObject(entity: desc, insertInto: container.viewContext)
//    entity.setValue("Hello", forKey: "propertyA")
//    entity.setValue(1, forKey: "propertyB")
//    print(entity)
//    try! container.viewContext.save()
//    print("Stored")
//
//})
//
//struct Content: View {
//
//    @FetchRequest(
//        sortDescriptors: [],
//        animation: .default)
//    private var items: FetchedResults<TestEntity>
//
//    var body: some View {
//        let value = items.first?.value(forKey: "propertyA") as? String ?? "no value"
//        Text("Item propertyA is:  \(value)")
//            .lineLimit(5)
//            .frame(width: 250, height: 100)
//    }
//}
//
//let view = Content()
//    .environment(\.managedObjectContext, container.viewContext)
//
//PlaygroundPage.current.liveView = UIHostingController(rootView: view)

////@FocusedBinding
//
//struct ListenerTextKey : FocusedValueKey {
//    typealias Value = Binding<String>
//}
//
//extension FocusedValues {
//    var listener: ListenerTextKey.Value? {
//        get { self[ListenerTextKey.self] }
//        set { self[ListenerTextKey.self] = newValue }
//    }
//}
//
//struct ContentView: View {
//
//    @State var inputText: String = ""
//
//    var body: some View {
//        VStack {
//            InputView()
//            ListenerView()
//        }
//    }
//}
//
//struct InputView : View {
//
//    @State private var inputText = ""
//
//    var body: some View {
//        TextField("Input", text: $inputText)
//            .focusedValue(\.listener, $inputText)
//    }
//}
//
//struct ListenerView: View {
//
//    @FocusedBinding(\.listener) private var text: String?
//    @FocusedValue(\.listener) private var value
//
//    var body: some View {
//        Text(text ?? value?.wrappedValue ?? "no value")
//    }
//}
//
//PlaygroundPage.current.liveView = UIHostingController(rootView: ContentView())

// @Namespace

//struct ContentView: View {
//    @Namespace private var namespace
//    @State private var isPrimaryViewVisible = true
//
//    var body: some View {
//        ZStack {
//            if isPrimaryViewVisible {
//                PrimaryView(namespace: namespace)
//            } else {
//                SecondaryView(namespace: namespace)
//            }
//        }
//        .frame(width: 100, height: 400)
//        .onTapGesture {
//            withAnimation {
//                self.isPrimaryViewVisible.toggle()
//            }
//        }
//    }
//}
//
//struct PrimaryView: View {
//
//    let namespace: Namespace.ID
//
//    var body: some View {
//        VStack {
//            Circle()
//                .fill(Color.red)
//                .frame(width: 30, height: 30)
//                .matchedGeometryEffect(id: "shape", in: namespace)
//            Image(uiImage: UIImage(named: "test.jpg")!)
//                .resizable()
//                .frame(width: 50, height: 100)
//                .matchedGeometryEffect(id: "image", in: namespace)
//            Spacer()
//        }
//    }
//}
//
//struct SecondaryView: View {
//
//    let namespace: Namespace.ID
//
//    var body: some View {
//        VStack {
//            Spacer()
//            Image(uiImage: UIImage(named: "test.jpg")!)
//                .resizable()
//                .frame(width: 100, height: 200)
//                .matchedGeometryEffect(id: "image", in: namespace)
//            Circle()
//                .fill(Color.blue)
//                .frame(width: 60, height: 60)
//                .matchedGeometryEffect(id: "shape", in: namespace)
//        }
//    }
//}
//
//PlaygroundPage.current.liveView = UIHostingController(rootView: ContentView())

////@ScaledMetric
//
//struct ContentView: View {
//
//    @ScaledMetric(relativeTo: .caption) var textSize: CGFloat = 8
//    @ScaledMetric(relativeTo: .body) var padding: CGFloat = 10
//
//    var body: some View {
//        VStack {
//            Text("Hello")
//                .font(.system(size: textSize))
//                .padding(padding)
//                .border(Color.black)
//        }
//        .background(Color.white)
//    }
//}
//
//struct ComparisonView: View {
//
//    var body: some View {
//        VStack {
//            Text("default")
//            ContentView()
//            Text("accessibilityXXXL")
//            ContentView()
//                .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
//        }
//        .frame(width: 200, height: 400)
//    }
//}
//
//PlaygroundPage.current.liveView = UIHostingController(rootView: ComparisonView())

////@SceneStorage
////Test on simulator or device
//struct ContentView: View {
//
//    @SceneStorage("pressCount") private var pressCount: Int = 1
//
//    var body: some View {
//        VStack {
//            Button(action: {
//                pressCount += 1
//            }, label: {
//                Text("Tap me")
//            })
//        }
//        Text("Hello tapped \(pressCount)")
//    }
//}

//@StateObject

//struct ContentView: View {
//    final class MyClassObj: ObservableObject {
//        @Published var counter: Int = 0
//    }
//
//    struct NestedView: View {
//        @StateObject // <- new approach
////        @ObservedObject // <- old approach
//        var classObject: MyClassObj = MyClassObj()
//
//        var body: some View {
//            VStack {
//                Text("Count = \(classObject.counter)")
//                    .frame(width: 300)
//                Button("Tap to +subView counter") {
//                    classObject.counter += 1
//                }
//            }
//        }
//    }
//
//    @State private var parentCounter: Int = 0
//
//    var body: some View {
//        VStack {
//            VStack {
//                Text("Parent counter \(parentCounter)")
//                    .frame(width: 300)
//                Button(action: {
//                    parentCounter += 1
//                }, label: {
//                    Text("Tap to +parentCounter")
//                })
//            }
//            .padding()
//            NestedView()
//        }
//        .frame(width: 300, height: 400)
//    }
//}
//
//PlaygroundPage.current.liveView = UIHostingController(rootView: ContentView())

////@UIApplicationDelegateAdaptor
//class HelloAppDelegate: NSObject, UIApplicationDelegate {
//
//    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
//
//        // use any callback
//        return true
//    }
//}
//
//// in the app
//
//@main
//struct HelloApp: App {
//    @UIApplicationDelegateAdaptor(HelloAppDelegate.self) var appDelegate
//}
//

//@ViewBuilder

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

PlaygroundPage.current.liveView = UIHostingController(rootView: ContentView())
