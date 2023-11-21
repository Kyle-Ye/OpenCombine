//
//  Publishers.Merge.swift
//
//
//  Created by Kyle on 2023/11/21.
//

#if canImport(COpenCombineHelpers)
import COpenCombineHelpers
#endif

extension Publisher {
    /// Combines elements from this publisher with those from another publisher, delivering an interleaved sequence of elements.
    ///
    /// Use ``Publisher/merge(with:)-7fk3a`` when you want to receive a new element whenever any of the upstream publishers emits an element. To receive tuples of the most-recent value from all the upstream publishers whenever any of them emit a value, use ``Publisher/combineLatest(_:)``. To combine elements from multiple upstream publishers, use ``Publisher/zip(_:)``.
    ///
    /// In this example, as ``Publisher/merge(with:)-7fk3a`` receives input from either upstream publisher, it republishes it to the downstream:
    ///
    ///     let publisher = PassthroughSubject<Int, Never>()
    ///     let pub2 = PassthroughSubject<Int, Never>()
    ///
    ///     cancellable = publisher
    ///         .merge(with: pub2)
    ///         .sink { print("\($0)", terminator: " " )}
    ///
    ///     publisher.send(2)
    ///     pub2.send(2)
    ///     publisher.send(3)
    ///     pub2.send(22)
    ///     publisher.send(45)
    ///     pub2.send(22)
    ///     publisher.send(17)
    ///
    ///     // Prints: "2 2 3 22 45 22 17"
    ///
    ///
    /// The merged publisher continues to emit elements until all upstream publishers finish.
    /// If an upstream publisher produces an error, the merged publisher fails with that error.
    ///
    /// - Parameter other: Another publisher.
    /// - Returns: A publisher that emits an event when either upstream publisher emits an event.
    public func merge<P>(with other: P) -> Publishers.Merge<Self, P> where P: Publisher, Self.Failure == P.Failure, Self.Output == P.Output {
        Publishers.Merge(self, other)
    }
    
    /// Combines elements from this publisher with those from two other publishers, delivering an interleaved sequence of elements.
    ///
    /// Use ``Publisher/merge(with:_:)`` when you want to receive a new element whenever any of the upstream publishers emits an element. To receive tuples of the most-recent value from all the upstream publishers whenever any of them emit a value, use ``Publisher/combineLatest(_:_:)-5crqg``.
    /// To combine elements from multiple upstream publishers, use ``Publisher/zip(_:_:)-8d7k7``.
    ///
    /// In this example, as ``Publisher/merge(with:_:)`` receives input from the upstream publishers, it republishes the interleaved elements to the downstream:
    ///
    ///     let pubA = PassthroughSubject<Int, Never>()
    ///     let pubB = PassthroughSubject<Int, Never>()
    ///     let pubC = PassthroughSubject<Int, Never>()
    ///
    ///     cancellable = pubA
    ///         .merge(with: pubB, pubC)
    ///         .sink { print("\($0)", terminator: " " )}
    ///
    ///     pubA.send(1)
    ///     pubB.send(40)
    ///     pubC.send(90)
    ///     pubA.send(2)
    ///     pubB.send(50)
    ///     pubC.send(100)
    ///
    ///     // Prints: "1 40 90 2 50 100"
    ///
    /// The merged publisher continues to emit elements until all upstream publishers finish.
    /// If an upstream publisher produces an error, the merged publisher fails with that error.
    ///
    /// - Parameters:
    ///   - b: A second publisher.
    ///   - c: A third publisher.
    /// - Returns: A publisher that emits an event when any upstream publisher emits an event.
    public func merge<B, C>(with b: B, _ c: C) -> Publishers.Merge3<Self, B, C> where B: Publisher, C: Publisher, Self.Failure == B.Failure, Self.Output == B.Output, B.Failure == C.Failure, B.Output == C.Output {
        Publishers.Merge3(self, b, c)
    }
}

extension Publishers {
    /// A publisher created by applying the merge function to two upstream publishers.
    public struct Merge<A, B>: Publisher where A: Publisher, B: Publisher, A.Failure == B.Failure, A.Output == B.Output {
        /// The kind of values published by this publisher.
        ///
        /// This publisher uses its upstream publishers' common output type.
        public typealias Output = A.Output
        
        /// The kind of errors this publisher might publish.
        ///
        /// This publisher uses its upstream publishers' common failure type.
        public typealias Failure = A.Failure
        
        /// A publisher to merge.
        public let a: A
        
        /// A second publisher to merge.
        public let b: B
        
        /// Creates a publisher created by applying the merge function to two upstream publishers.
        /// - Parameters:
        ///   - a: A publisher to merge
        ///   - b: A second publisher to merge.
        public init(_ a: A, _ b: B) {
            self.a = a
            self.b = b
        }
        
        /// Attaches the specified subscriber to this publisher.
        ///
        /// Implementations of ``Publisher`` must implement this method.
        ///
        /// The provided implementation of ``Publisher/subscribe(_:)-4u8kn``calls this method.
        ///
        /// - Parameter subscriber: The subscriber to attach to this ``Publisher``, after which it can receive values.
        public func receive<S>(subscriber: S) where S: Subscriber, B.Failure == S.Failure, B.Output == S.Input {
            typealias Inner = _Merged<A.Output, Failure, S>
            let merger = Inner(downstream: subscriber, count: 2)
            a.subscribe(Inner.Side(index: 0, merger: merger))
            b.subscribe(Inner.Side(index: 1, merger: merger))
        }
        
        public func merge<P>(with p: P) -> Publishers.Merge3<A, B, P> where P: Publisher, B.Failure == P.Failure, B.Output == P.Output {
            Merge3(a, b, p)
        }
    }
    
    /// A publisher created by applying the merge function to three upstream publishers.
    public struct Merge3<A, B, C>: Publisher where A: Publisher, B: Publisher, C: Publisher, A.Failure == B.Failure, A.Output == B.Output, B.Failure == C.Failure, B.Output == C.Output {
        /// The kind of values published by this publisher.
        ///
        /// This publisher uses its upstream publishers' common output type.
        public typealias Output = A.Output
        
        /// The kind of errors this publisher might publish.
        ///
        /// This publisher uses its upstream publishers' common failure type.
        public typealias Failure = A.Failure
        
        /// A publisher to merge.
        public let a: A
        
        /// A second publisher to merge.
        public let b: B
        
        /// A third publisher to merge.
        public let c: C
        
        /// Creates a publisher created by applying the merge function to three upstream publishers.
        /// - Parameters:
        ///   - a: A publisher to merge
        ///   - b: A second publisher to merge.
        ///   - c: A third publisher to merge.
        public init(_ a: A, _ b: B, _ c: C) {
            self.a = a
            self.b = b
            self.c = c
        }
        
        /// Attaches the specified subscriber to this publisher.
        ///
        /// Implementations of ``Publisher`` must implement this method.
        ///
        /// The provided implementation of ``Publisher/subscribe(_:)-4u8kn``calls this method.
        ///
        /// - Parameter subscriber: The subscriber to attach to this ``Publisher``, after which it can receive values.
        public func receive<S>(subscriber: S) where S: Subscriber, C.Failure == S.Failure, C.Output == S.Input {
            typealias Inner = _Merged<A.Output, Failure, S>
            let merger = Inner(downstream: subscriber, count: 3)
            a.subscribe(Inner.Side(index: 0, merger: merger))
            b.subscribe(Inner.Side(index: 1, merger: merger))
            c.subscribe(Inner.Side(index: 2, merger: merger))
        }
    }
}

extension Publishers.Merge: Equatable where A: Equatable, B: Equatable {
    /// Returns a Boolean value that indicates whether two publishers are equivalent.
    ///
    /// - Parameters:
    ///   - lhs: A merging publisher to compare for equality.
    ///   - rhs: Another merging publisher to compare for equality..
    /// - Returns: `true` if the two merging - rhs: Another merging publisher to compare for equality.
    public static func == (lhs: Publishers.Merge<A, B>, rhs: Publishers.Merge<A, B>) -> Bool {
        lhs.a == rhs.a && lhs.b == rhs.b
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.Merge3: Equatable where A: Equatable, B: Equatable, C: Equatable {
    /// Returns a Boolean value that indicates whether two publishers are equivalent.
    ///
    /// - Parameters:
    ///   - lhs: A merging publisher to compare for equality.
    ///   - rhs: Another merging publisher to compare for equality.
    /// - Returns: `true` if the two merging publishers have equal source publishers; otherwise `false`.
    public static func == (lhs: Publishers.Merge3<A, B, C>, rhs: Publishers.Merge3<A, B, C>) -> Bool {
        lhs.a == rhs.a && lhs.b == rhs.b && lhs.c == rhs.c
    }
}

// MARK: _Merge

extension Publishers {
    fileprivate class _Merged<Input, Failure, Downstream> where Downstream: Subscriber, Input == Downstream.Input, Failure == Downstream.Failure {
        let downstream: Downstream
        var demand = Subscribers.Demand.none
        var terminated = false
        let count: Int
        var upstreamFinished = 0
        var finished = false
        var subscriptions: [Subscription?]
        var buffers: [Input?]
        let lock = UnfairLock.allocate()
        let downstreamLock = UnfairRecursiveLock.allocate()
        var recursive = false
        var pending = Subscribers.Demand.none
        
        init(downstream: Downstream, count: Int) {
            self.downstream = downstream
            self.count = count
            subscriptions = .init(repeating: nil, count: count)
            buffers = .init(repeating: nil, count: count)
        }
        
        deinit {
            lock.deallocate()
            downstreamLock.deallocate()
        }
    }
}

extension Publishers._Merged: Subscription {
    func request(_ demand: Subscribers.Demand) {
        lock.lock()
        guard !terminated,
              !finished,
              demand != .none,
              self.demand != .unlimited else {
            lock.unlock()
            return
        }
        guard !recursive else {
            pending = pending + demand
            lock.unlock()
            return
        }
        if demand == .unlimited {
            self.demand = .unlimited
            let buffers = buffers
            self.buffers = Array(repeating: nil, count: buffers.count)
            let subscriptions = subscriptions
            let upstreamFinished = upstreamFinished
            let count = count
            lock.unlock()
            buffers.forEach { input in
                guard let input else {
                    return
                }
                guardedApplyDownstream { downstream in
                    _ = downstream.receive(input)
                }
            }
            if upstreamFinished == count {
                guardedBecomeTerminal()
                guardedApplyDownstream { downstream in
                    downstream.receive(completion: .finished)
                }
            } else {
                for subscription in subscriptions {
                    subscription?.request(.unlimited)
                }
            }
        } else {
            self.demand = self.demand + demand
            var newBuffers: [Input] = []
            var newSubscrptions: [Subscription?] = []
            for (index, buffer) in buffers.enumerated() {
                guard self.demand != .zero else {
                    break
                }
                guard let buffer else {
                    continue
                }
                buffers[index] = nil
                if self.demand != .unlimited {
                    self.demand -= 1
                }
                newBuffers.append(buffer)
                newSubscrptions.append(subscriptions[index])
            }
            let newFinished: Bool
            if upstreamFinished == count {
                if buffers.allSatisfy({ $0 == nil }) {
                    newFinished = true
                    finished = true
                } else {
                    newFinished = false
                }
            } else {
                newFinished = false
            }
            lock.unlock()
            var newDemand = Subscribers.Demand.none
            for buffer in newBuffers {
                let demandResult = guardedApplyDownstream { downstream in
                    downstream.receive(buffer)
                }
                newDemand += demandResult
            }
            lock.lock()
            newDemand = newDemand + pending
            pending = .none
            lock.unlock()
            if newFinished {
                guardedBecomeTerminal()
                guardedApplyDownstream { downstream in
                    downstream.receive(completion: .finished)
                }
            } else {
                if newDemand != .none {
                    lock.lock()
                    self.demand += newDemand
                    lock.unlock()
                }
                for subscrption in newSubscrptions {
                    subscrption?.request(.max(1))
                }
            }
        }
    }
    
    func cancel() {
        guardedBecomeTerminal()
    }
}

extension Publishers._Merged {
    func receive(subscription: Subscription, index: Int) {
        lock.lock()
        guard !terminated, subscriptions[index] == nil else {
            lock.unlock()
            subscription.cancel()
            return
        }
        subscriptions[index] = subscription
        let demand = demand == .unlimited ? demand : .max(1)
        lock.unlock()
        subscription.request(demand)
    }
    
    func receive(_ input: Input, index: Int) -> Subscribers.Demand {
        lock.lock()
        guard demand != .unlimited else {
            lock.unlock()
            return guardedApplyDownstream { downstream in
                downstream.receive(input)
            }
        }
        if demand == .none {
            buffers[index] = input
            lock.unlock()
            return .none
        } else {
            lock.unlock()
            let result = guardedApplyDownstream { downstream in
                downstream.receive(input)
            }
            lock.lock()
            demand = result + pending + demand - 1
            pending = .none
            lock.unlock()
            return .max(1)
        }
    }
    
    func receive(completion: Subscribers.Completion<Failure>, index: Int) {
        switch completion {
        case .finished:
            lock.lock()
            upstreamFinished += 1
            subscriptions[index] = nil
            if upstreamFinished == count, buffers.allSatisfy({ $0 != nil }) {
                finished = true
                lock.unlock()
                guardedBecomeTerminal()
                guardedApplyDownstream { downstream in
                    downstream.receive(completion: .finished)
                }
            } else {
                lock.unlock()
            }
        case .failure:
            lock.lock()
            let terminated = terminated
            lock.unlock()
            if !terminated {
                guardedBecomeTerminal()
                guardedApplyDownstream { downstream in
                    downstream.receive(completion: completion)
                }
            }
        }
    }
    
    private func guardedApplyDownstream<Result>(_ block: (Downstream) -> Result) -> Result {
        lock.lock()
        recursive = true
        lock.unlock()
        downstreamLock.lock()
        let result = block(downstream)
        downstreamLock.unlock()
        lock.lock()
        recursive = false
        lock.unlock()
        return result
    }
    
    private func guardedBecomeTerminal() {
        lock.lock()
        terminated = true
        let subscriptions = subscriptions
        self.subscriptions = Array(repeating: nil, count: subscriptions.count)
        buffers = Array(repeating: nil, count: buffers.count)
        lock.unlock()
        for subscription in subscriptions {
            subscription?.cancel()
        }
    }
}

extension Publishers._Merged {
    struct Side {
        let index: Int
        let merger: Publishers._Merged<Input, Failure, Downstream>
        let combineIdentifier: CombineIdentifier
        
        init(index: Int, merger: Publishers._Merged<Input, Failure, Downstream>) {
            self.index = index
            self.merger = merger
            combineIdentifier = CombineIdentifier()
        }
    }
}

extension Publishers._Merged.Side: Subscriber {
    func receive(subscription: Subscription) {
        merger.receive(subscription: subscription, index: index)
    }
    
    func receive(_ input: Input) -> Subscribers.Demand {
        merger.receive(input, index: index)
    }
    
    func receive(completion: Subscribers.Completion<Failure>) {
        merger.receive(completion: completion, index: index)
    }
}

extension Publishers._Merged: CustomStringConvertible {
    var description: String { "Merge" }
}

extension Publishers._Merged.Side: CustomStringConvertible {
    var description: String { "Merge" }
}

extension Publishers._Merged: CustomPlaygroundDisplayConvertible {
    var playgroundDescription: Any { description }
}

extension Publishers._Merged.Side: CustomPlaygroundDisplayConvertible {
    var playgroundDescription: Any { description }
}

extension Publishers._Merged: CustomReflectable {
    var customMirror: Mirror { Mirror(self, children: [:]) }
}

extension Publishers._Merged.Side: CustomReflectable {
    var customMirror: Mirror {
        Mirror(self, children: ["parentSubscription": merger.combineIdentifier])
    }
}
