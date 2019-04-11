import XCTest
import Ry

class SignalTests: XCTestCase {
    private let pool = DisposePool()

    func test_never() {
        let tracker = ClosureTracker<Int>()
        let signal = Signal<Int>.never

        signal.addObserver(tracker.observer).add(to: pool)

        XCTAssertEqual(tracker.values, [])
    }

    func test_value() {
        let tracker = ClosureTracker<Int>()
        let signal = Signal.value(42)

        signal.addObserver(tracker.observer).add(to: pool)

        XCTAssertEqual(tracker.values, [42])
    }

    func test_values() {
        let tracker = ClosureTracker<Int>()
        let signal = Signal.values([2, 12, 85])

        signal.addObserver(tracker.observer).add(to: pool)

        XCTAssertEqual(tracker.values, [2, 12, 85])
    }

    func test_map() {
        let tracker = ClosureTracker<String>()
        let signal = Signal.values([2, 12, 85]).map { "\($0)!" }

        signal.addObserver(tracker.observer).add(to: pool)

        XCTAssertEqual(tracker.values, ["2!", "12!", "85!"])
    }

    func test_filter() {
        let tracker = ClosureTracker<Int>()
        let signal = Signal.values([2, 12, 85, 0, 7]).filter { $0 % 2 == 0 }

        signal.addObserver(tracker.observer).add(to: pool)

        XCTAssertEqual(tracker.values, [2, 12, 0])
    }

    func test_compactMap() {
        let tracker = ClosureTracker<Int>()
        let signal = Signal.values(["2", "12", "hi", "85", "bye"]).compactMap(Int.init)

        signal.addObserver(tracker.observer).add(to: pool)

        XCTAssertEqual(tracker.values, [2, 12, 85])
    }

    func test_compacted() {
        let tracker = ClosureTracker<Int>()
        let signal = Signal.values([2, nil, 12, nil, 85]).compacted()

        signal.addObserver(tracker.observer).add(to: pool)

        XCTAssertEqual(tracker.values, [2, 12, 85])
    }

    func test_switchMap() {
        let tracker = ClosureTracker<String>()
        let outerPipe = SignalPipe<Int>()
        let innerPipes = [SignalPipe<String>(), SignalPipe<String>()]
        let signal = outerPipe.signal.switchMap { innerPipes[$0].signal }
        signal.addObserver(tracker.observer).add(to: pool)

        innerPipes[0].send("0a")
        innerPipes[1].send("1a")

        outerPipe.send(0)

        innerPipes[0].send("0b")
        innerPipes[1].send("1b")

        outerPipe.send(1)

        innerPipes[0].send("0c")
        innerPipes[1].send("1c")
        innerPipes[0].send("0d")
        innerPipes[1].send("1d")

        outerPipe.send(0)

        innerPipes[0].send("0e")
        innerPipes[1].send("1e")

        XCTAssertEqual(tracker.values, ["0b", "1c", "1d", "0e"])
    }

    func test_switchAll() {
        let tracker = ClosureTracker<Int>()
        let outerPipe = SignalPipe<Signal<Int>>()
        let signal = outerPipe.signal.switchAll()
        signal.addObserver(tracker.observer).add(to: pool)

        outerPipe.send(.values([1, 2, 3]))
        outerPipe.send(.never)
        outerPipe.send(.values([4, 5]))
        outerPipe.send(.value(6))
        outerPipe.send(.values([7, 8, 9]))

        XCTAssertEqual(tracker.values, Array(1...9))
    }

    func test_mergeMap() {
        let tracker = ClosureTracker<String>()
        let outerPipe = SignalPipe<Int>()
        let innerPipes = [SignalPipe<String>(), SignalPipe<String>()]
        let signal = outerPipe.signal.mergeMap { innerPipes[$0].signal }
        signal.addObserver(tracker.observer).add(to: pool)

        innerPipes[0].send("0a")
        innerPipes[1].send("1a")

        outerPipe.send(0)

        innerPipes[0].send("0b")
        innerPipes[1].send("1b")

        outerPipe.send(1)

        innerPipes[0].send("0c")
        innerPipes[1].send("1c")
        innerPipes[0].send("0d")
        innerPipes[1].send("1d")

        outerPipe.send(0)

        innerPipes[0].send("0e")
        innerPipes[1].send("1e")

        XCTAssertEqual(tracker.values, ["0b", "0c", "1c", "0d", "1d", "0e", "0e", "1e"])
    }

    func test_merge() {
        let tracker = ClosureTracker<Int>()
        let signal = Signal.merge(
            .values([1, 2, 3]),
            .never,
            .values([4, 5]),
            .value(6),
            .values([7, 8, 9])
        )
        signal.addObserver(tracker.observer).add(to: pool)

        XCTAssertEqual(tracker.values, Array(1...9))
    }

    func test_startWithValue() {
        let tracker = ClosureTracker<Int>()
        let signal = Signal.values([2, 12, 85]).startWith(8)
        signal.addObserver(tracker.observer).add(to: pool)

        XCTAssertEqual(tracker.values, [8, 2, 12, 85])
    }

    func test_startWithLazy() {
        let tracker = ClosureTracker<Int>()
        var value = 0
        let signal = Signal.values([2, 12, 85]).startWith { value }
        value = 8
        signal.addObserver(tracker.observer).add(to: pool)

        XCTAssertEqual(tracker.values, [8, 2, 12, 85])
    }

    func test_testWhile_instant() {
        let tracker = ClosureTracker<Int>()
        let signal = Signal.values([2, 12, 85, 0, 6]).takeWhile { $0 != 0 }
        signal.addObserver(tracker.observer).add(to: pool)

        XCTAssertEqual(tracker.values, [2, 12, 85])
    }

    func test_testWhile_pipe() {
        let tracker = ClosureTracker<Int>()
        let pipe = SignalPipe<Int>()
        let signal = pipe.signal.takeWhile { $0 != 0 }
        signal.addObserver(tracker.observer).add(to: pool)

        pipe.send(2)
        pipe.send(12)
        pipe.send(85)
        pipe.send(0)
        pipe.send(6)

        XCTAssertEqual(tracker.values, [2, 12, 85])
    }

    func test_testUntil() {
        let tracker = ClosureTracker<Int>()
        let pipe = SignalPipe<Int>()
        let terminator = SignalPipe<String>()
        let signal = pipe.signal.takeUntil(terminator.signal)
        signal.addObserver(tracker.observer).add(to: pool)

        pipe.send(2)
        pipe.send(12)
        pipe.send(85)
        terminator.send("Stop!")
        pipe.send(0)
        terminator.send("Argh!")
        pipe.send(6)

        XCTAssertEqual(tracker.values, [2, 12, 85])
    }

    func test_skipRepeats() {
        let tracker = ClosureTracker<Int>()
        let signal = Signal.values([2, 2, 2, 12, 85, 85, 0, 7, 7, 7]).skipRepeats()

        signal.addObserver(tracker.observer).add(to: pool)

        XCTAssertEqual(tracker.values, [2, 12, 85, 0, 7])
    }

    func test_withPrevious() {
        let tracker = ClosureTracker<(Int, Int)>()
        let signal = Signal.values([2, 12, 85, 0, 7]).withPrevious()

        signal.addObserver(tracker.observer).add(to: pool)

        XCTAssertEqual(tracker.values.map { [$0, $1] }, [[2, 12], [12, 85], [85, 0], [0, 7]])
    }
}
