import Foundation
import Combine

// sample 1
//print("The start thread is \(Thread.current)")
//[1, 2, 3, 4].publisher
//    .print()
//    // current mode - default
//    .subscribe(on: RunLoop.current)
//    .handleEvents(receiveRequest:  { (_) in
//        print("Event handle at thread is \(Thread.current)")
//    })
//    // current mode - default for main runLoop
//    .receive(on: RunLoop.main)
//    .sink { (_) in
//        print("Event recevide at thread is \(Thread.current)")
//    }
//    .store(in: &subscription)


// sample 2
//let queue = DispatchQueue(label: "sample.scheduler.runLoop")
//var subscription = Set<AnyCancellable>()
//
//queue.async {
//    print("The start thread is \(Thread.current)")
//
//    // <CFRunLoop 0x600001810400 [0x7fff8002e7f0]>{wakeup port = 0xa003, stopped = false, ignoreWakeUps = true,
//    RunLoop.current
//
//    [1, 2, 3, 4].publisher
//        .print()
//        // current mode - default
//        .subscribe(on: RunLoop.current)
//        .handleEvents(receiveRequest:  { (_) in
//            print("Event handle at thread is \(Thread.current)")
//        })
//        // current mode - default for main runLoop
//        .receive(on: RunLoop.current)
//        .sink { (_) in
//            print("Event recevide at thread is \(Thread.current)")
//        }
//        .store(in: &subscription)
//
//    RunLoop.current.run(mode: .default, before: Date.distantFuture)
//}

// sample 3

let queue = DispatchQueue(label: "sample.scheduler.runLoop")
var subscriptions = Set<AnyCancellable>()

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
        .receive(on: RunLoop.current)
        .sink { (value) in
            print("The value is \(value) in \(Thread.current) at \(Date())")
        }
        .store(in: &subscriptions)
    
    RunLoop.current
        .schedule(
            after: .init(Date(timeIntervalSinceNow: 4.5)),
            tolerance: .seconds(1),
            options: nil
        ) {
            print("cancelation")
            subscriptions.removeAll()
    }
    
    RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 5))
}
