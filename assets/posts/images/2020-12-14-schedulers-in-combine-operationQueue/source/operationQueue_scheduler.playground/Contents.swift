import Foundation
import Combine

var subscription = Set<AnyCancellable>()
let publisher = [1,2,3,4,5].publisher
let operation = OperationQueue()

//// sample 1
//operation.maxConcurrentOperationCount = 1
//operation.underlyingQueue = .main
//
//publisher
//    .receive(on: operation)
//    .sink { (value) in
//        print("Recevied value \(value) on \(Thread.current)")
//    }
//    .store(in: &subscription)
//
//
//// sample 2
//publisher
//    .receive(on: OperationQueue.main)
//    .sink { (value) in
//        print("Recevied value \(value) on \(Thread.current)")
//    }
//    .store(in: &subscription)
//

//// sample 3
//
//import Foundation
//
//public class AsyncOperation: Operation {
//
//    // MARK: - AsyncOperation
//
//    public enum State: String {
//
//        case ready
//        case executing
//        case finished
//
//        fileprivate var keyPath: String {
//            return "is" + rawValue.capitalized
//        }
//    }
//
//    public var state = State.ready {
//        willSet {
//            willChangeValue(forKey: newValue.keyPath)
//            willChangeValue(forKey: state.keyPath)
//        }
//        didSet {
//            didChangeValue(forKey: oldValue.keyPath)
//            didChangeValue(forKey: state.keyPath)
//        }
//    }
//}
//
//public extension AsyncOperation {
//
//    // MARK: - AsyncOperation+Addition
//
//    override var isReady: Bool {
//        return super.isReady && state == .ready
//    }
//
//    override var isExecuting: Bool {
//        return state == .executing
//    }
//
//    override var isFinished: Bool {
//        return state == .finished
//    }
//
//    override var isAsynchronous: Bool {
//        return true
//    }
//
//    override func start() {
//        if isFinished {
//            return
//        }
//
//        if isCancelled {
//            state = .finished
//            return
//        }
//
//        main()
//        state = .executing
//    }
//
//    override func cancel() {
//        super.cancel()
//        state = .finished
//    }
//}
//
//final class AsyncLongAndHightPriorityOperation: AsyncOperation {
//
//    override func main() {
//        print("started heavy operation")
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
//            self.state = .finished
//            print("finished heavy operation")
//        }
//    }
//}
//
//final class MyOperationQueue: OperationQueue {
//
//    override func addOperation(_ op: Operation) {
//
//        print("Add operation - \(op)")
//
//        op.completionBlock  = {
//            print("Completed \(op)")
//        }
//
//        super.addOperation(op)
//    }
//}
//
//let heavyOperation = AsyncLongAndHightPriorityOperation()
//heavyOperation.queuePriority = .high
//
//let queue = OperationQueue()
////queue.maxConcurrentOperationCount = 1
//
//print("Started at date \(Date())")
//queue.addOperation(heavyOperation)
//
//publisher
//    .subscribe(on: queue)
//    .receive(on: OperationQueue.main)
//    .sink(receiveCompletion: { (completion) in
//        print("Recevied completion \(completion) on \(Thread.current), date \(Date())")
//    }, receiveValue: { (value) in
//        print("Recevied value \(value) on \(Thread.current), date \(Date())")
//    })
//    .store(in: &subscription)

// sample 4


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
    .store(in: &subscription)
    
operation
    .schedule(
        after: .init(Date(timeIntervalSinceNow: 4.5)),
        tolerance: .seconds(1),
        options: nil
    ) {
        print("cancelation")
        subscription.removeAll()
    }

