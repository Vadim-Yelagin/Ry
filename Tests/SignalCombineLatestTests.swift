import XCTest
import Ry

class SignalCombineLatestTests: XCTestCase {
    private let pool = DisposePool()

    func test_two() {
        let tracker = ClosureTracker<String>()
        let pipe0 = SignalPipe<String>()
        let pipe1 = SignalPipe<Int>()
        let signal = Signal.combineLatest(pipe0.signal, pipe1.signal)
            .map { "\($0)\($1)" }
        signal.addObserver(tracker.observer).dispose(in: pool)

        pipe0.send("A")
        pipe0.send("B")
        pipe1.send(0)
        pipe1.send(1)
        pipe0.send("C")
        pipe0.send("D")
        pipe1.send(2)
        pipe1.send(3)

        XCTAssertEqual(tracker.values, ["B0", "B1", "C1", "D1", "D2", "D3"])
    }

    func test_three() {
        let tracker = ClosureTracker<String>()
        let pipe0 = SignalPipe<String>()
        let pipe1 = SignalPipe<Int>()
        let pipe2 = SignalPipe<Character>()
        let signal = Signal.combineLatest(pipe0.signal, pipe1.signal, pipe2.signal)
            .map { "\($0)\($1)\($2)" }
        signal.addObserver(tracker.observer).dispose(in: pool)

        pipe0.send("A")
        pipe0.send("B")
        pipe1.send(0)
        pipe1.send(1)
        pipe2.send("a")
        pipe2.send("b")
        pipe0.send("C")
        pipe0.send("D")
        pipe1.send(2)
        pipe1.send(3)
        pipe2.send("c")
        pipe2.send("d")

        XCTAssertEqual(tracker.values, ["B1a", "B1b", "C1b", "D1b", "D2b", "D3b", "D3c", "D3d"])
    }

    func test_four() {
        let tracker = ClosureTracker<String>()
        let pipe0 = SignalPipe<String>()
        let pipe1 = SignalPipe<Int>()
        let pipe2 = SignalPipe<Character>()
        let pipe3 = SignalPipe<Decimal>()
        let signal = Signal.combineLatest(pipe0.signal, pipe1.signal, pipe2.signal, pipe3.signal)
            .map { "\($0)\($1)\($2)\($3)" }
        signal.addObserver(tracker.observer).dispose(in: pool)

        pipe0.send("A")
        pipe1.send(0)
        pipe2.send("b")
        pipe3.send(1)
        pipe0.send("C")
        pipe1.send(2)
        pipe2.send("d")
        pipe3.send(3)

        XCTAssertEqual(tracker.values, ["A0b1", "C0b1", "C2b1", "C2d1", "C2d3"])
    }

    func test_array() {
        let tracker = ClosureTracker<String>()
        let pipe0 = SignalPipe<String>()
        let pipe1 = SignalPipe<String>()
        let signal = Signal.combineLatest([pipe0.signal, pipe1.signal]).map { $0.joined() }
        signal.addObserver(tracker.observer).dispose(in: pool)

        pipe0.send("A")
        pipe0.send("B")
        pipe1.send("0")
        pipe1.send("1")
        pipe0.send("C")
        pipe0.send("D")
        pipe1.send("2")
        pipe1.send("3")

        XCTAssertEqual(tracker.values, ["B0", "B1", "C1", "D1", "D2", "D3"])
    }

    func test_twoOfTheSame() {
        let tracker = ClosureTracker<[Int]>()
        let pipe = SignalPipe<Int>()
        let signal = Signal.combineLatest(pipe.signal, pipe.signal)
            .map { [$0, $1].sorted() }
        signal.addObserver(tracker.observer).dispose(in: pool)

        pipe.send(1)
        pipe.send(2)
        pipe.send(3)
        pipe.send(4)

        XCTAssertEqual(tracker.values, [
            [1, 1],
            [1, 2],
            [2, 2],
            [2, 3],
            [3, 3],
            [3, 4],
            [4, 4],
        ])
    }
}
