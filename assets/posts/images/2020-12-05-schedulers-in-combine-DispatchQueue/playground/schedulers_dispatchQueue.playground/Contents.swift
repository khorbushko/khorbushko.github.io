import UIKit
import Combine

var subscriptions = Set<AnyCancellable>()

//sample 1
//let publisher = [1,2,3,4,5].publisher
//print("Current thread \(Thread.current)")
//
//publisher
//    .receive(on: DispatchQueue.main)
//
//    .sink { (value) in
//        print("Recevied in \(Thread.current) - \(value)")
//    }
//    .store(in: &subscriptions)


// sample 2
//let publisher = [1,2,3,4,5].publisher
//let backgroundQueue = DispatchQueue(label: "com.schedulers.dispatch.sample", qos: .background)
//print("Current thread \(Thread.current)")
//
//publisher
//    .subscribe(on: backgroundQueue)
//    .handleEvents(receiveSubscription: { (subscription) in
//        print("Receive thread \(Thread.current), \(subscriptions)")
//    })
//    .receive(on: DispatchQueue.main)
//    .sink { (value) in
//        print("Recevied in \(Thread.current) - \(value)")
//    }
//    .store(in: &subscriptions)

// options

//let publisher = [1,2,3,4,5].publisher
//let backgroundQueue = DispatchQueue(
//    label: String,
//    qos: DispatchQoS,
//    attributes: DispatchQueue.Attributes,
//    autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency,
//    target: DispatchQueue?
//)
//
//DispatchQueue.SchedulerOptions(
//    qos: DispatchQoS,
//    flags: DispatchWorkItemFlags,
//    group: DispatchGroup
//)
//
//let firstPublisher = PassthroughSubject<Int, Never>()
//let secondPublisher = PassthroughSubject<String, Never>()
//let thirdPublisher = PassthroughSubject<Int, Never>()
//
//let workQueue = DispatchQueue(label: "com.testQueue", qos: .background)
//
//let group = DispatchGroup()
//group.notify(queue: .main) {
//    print("Comple all work at thread \(Thread.current)")
//}
//
//firstPublisher
//    .receive(on: workQueue, options: .init(group: group))
//    .sink { (value) in
//        print("The thread is \(Thread.current), and value: \(value)")
//    }
//    .store(in: &subscriptions)
//
//secondPublisher
//    .receive(on: DispatchQueue.global(), options: .init(group: group))
//    .sink { (value) in
//        print("The thread is \(Thread.current), and value: \(value)")
//    }
//    .store(in: &subscriptions)
//
//firstPublisher.send(1)
//secondPublisher.send("hi there!")

// equilaent
//let dispatchGroup = DispatchGroup()
//workQueue.async(group: dispatchGroup, execute: {
//    // work 1
//})
//DispatchQueue.global().async(group: dispatchGroup, execute: {
//    // work 2
//})
//
//dispatchGroup.notify(queue: dispatchQueueGlobal) {
//    // done
//}

// scheduler in future

let queue = DispatchQueue(label: "sample.scheduler.dispatchQueue")
queue.async {
    print("Create on \(Thread.current)")
    let source = Timer
        .publish(every: 1, on: .main, in: .common)
        .autoconnect()
        .scan(0, { counter, _  in
            let value = counter + 1
            print("tick ", value)
            return value
        })
    
    source
        .receive(on: DispatchQueue.main)
        .sink { (value) in
            print("The value is \(value) in \(Thread.current) at \(Date())")
        }
        .store(in: &subscriptions)
    
    DispatchQueue.main
        .schedule(
            after: .init(.now() + 5),
            tolerance: .seconds(1),
            options: nil
        ) {
            print("cancelation")
            subscriptions.removeAll()
        }
}
