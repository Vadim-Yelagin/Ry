import XCTest
import Ry

class ObserverTests: XCTestCase {
    func test_whenObserves_callsClosure() {
        let tracker = ClosureTracker<Int>()
        let observer = tracker.observer
        observer.observe(2)
        observer.observe(12)
        observer.observe(85)
        XCTAssertEqual(tracker.values, [2, 12, 85])
    }

    func test_contramap() {
        let tracker = ClosureTracker<String>()
        let observer: Observer<Int> = tracker.observer.contramap { "\($0)?" }
        observer.observe(2)
        observer.observe(12)
        observer.observe(85)
        XCTAssertEqual(tracker.values, ["2?", "12?", "85?"])
    }

    func test_filter() {
        let tracker = ClosureTracker<Int>()
        let observer = tracker.observer.filter { $0 % 2 == 0 }
        observer.observe(2)
        observer.observe(12)
        observer.observe(85)
        observer.observe(0)
        observer.observe(7)
        XCTAssertEqual(tracker.values, [2, 12, 0])
    }

    func test_compactContramap() {
        let tracker = ClosureTracker<Int>()
        let observer: Observer<String> = tracker.observer.compactContramap(Int.init)
        observer.observe("2")
        observer.observe("12")
        observer.observe("hi")
        observer.observe("85")
        observer.observe("bye")
        XCTAssertEqual(tracker.values, [2, 12, 85])
    }

    func test_compacted() {
        let tracker = ClosureTracker<Int>()
        let observer = tracker.observer.compacted()
        observer.observe(2)
        observer.observe(nil)
        observer.observe(12)
        observer.observe(nil)
        observer.observe(85)
        XCTAssertEqual(tracker.values, [2, 12, 85])
    }

    func test_mergeContramap() {
        let tracker = ClosureTracker<String>()
        let pool = DisposePool()
        let observer: Observer<Int> = tracker.observer.mergeContramap({
            .values(["\($0).", "\($0)?", "\($0)!"])
        }, addDisposable: pool.add)
        observer.observe(2)
        observer.observe(12)
        observer.observe(85)
        XCTAssertEqual(tracker.values.joined(separator: " "), "2. 2? 2! 12. 12? 12! 85. 85? 85!")
        pool.drain()
    }

    func test_mergeAll() {
        let tracker = ClosureTracker<Int>()
        let pool = DisposePool()
        let pipe1 = SignalPipe<Int>()
        let pipe2 = SignalPipe<Int>()
        let observer = tracker.observer.mergeAll(addDisposable: pool.add)

        pipe1.send(100)
        pipe2.send(200)

        observer.observe(pipe1.signal)

        pipe1.send(101)
        pipe2.send(201)

        observer.observe(pipe2.signal)

        pipe1.send(102)
        pipe2.send(202)

        pool.drain()

        pipe1.send(103)
        pipe2.send(203)

        observer.observe(pipe2.signal)

        pipe1.send(104)
        pipe2.send(204)

        XCTAssertEqual(tracker.values, [101, 102, 202, 204])

        pool.drain()
    }

    func test_skipRepeats() {
        let tracker = ClosureTracker<Int>()
        let observer = tracker.observer.skipRepeats()
        observer.observe(2)
        observer.observe(2)
        observer.observe(2)
        observer.observe(12)
        observer.observe(85)
        observer.observe(85)
        observer.observe(0)
        observer.observe(7)
        observer.observe(7)
        observer.observe(7)
        XCTAssertEqual(tracker.values, [2, 12, 85, 0, 7])
    }
}
