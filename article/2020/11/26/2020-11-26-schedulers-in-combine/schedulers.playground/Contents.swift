import Foundation
import Combine

let queue = DispatchQueue(label: "sample.queue")
var subscriptions = Set<AnyCancellable>()

// sample 1
queue.async {
    [1,2,3,4].publisher
        // equialent to operation with commented line 10 - default behavior
        .receive(on: ImmediateScheduler.shared)
        .sink { (value) in
            print("The value is \(value) in \(Thread.current) at \(Date())")
        }
        .store(in: &subscriptions)
}

// sample 2

queue.async {
    print("Create on \(Thread.current)")
    
    let source = Timer
        .publish(every: 1, on: .main, in: .common)
        .autoconnect()
        .scan(0, { counter, _  in counter + 1})
    
    source
        .receive(on: ImmediateScheduler.shared)
        .sink { (value) in
            print("The value is \(value) in \(Thread.current) at \(Date())")
        }
        .store(in: &subscriptions)
}

// sample 3
var subscription: AnyCancellable?

queue.async {
    print("Create on \(Thread.current)")
    
    let source = Timer
        .publish(every: 1, on: .main, in: .common)
        .autoconnect()
        .scan(0, { counter, _  in counter + 1})
    
    subscription = source
        .receive(on: ImmediateScheduler.shared)
        .sink { (value) in
            print("The value is \(value) in \(Thread.current) at \(Date())")
        }
    
    ImmediateScheduler.shared
        .schedule(
                  after: ImmediateScheduler.shared.now
                    .advanced(by: ImmediateScheduler.SchedulerTimeType.Stride(Int.max)
                    )
        ) {
        subscription?.cancel()
        print("Canceled at \(Date())")
    }
}
