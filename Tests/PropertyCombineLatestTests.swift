import XCTest
import Ry

class PropertyCombineLatestTests: XCTestCase {
	private let pool = DisposePool()

	func test_two() {
		let tracker = ClosureTracker<String>()
		let property0 = Property(initialValue: "A")
		let property1 = Property(initialValue: 0)
		let combined = ReadOnlyProperty.combineLatest(property0.readOnly, property1.readOnly)
			.map { "\($0)\($1)" }
		combined.values.addObserver(tracker.observer).dispose(in: pool)

		property0.value = "B"
		property1.value = 1
		property0.value = "C"
		property0.value = "D"
		property1.value = 2
		property1.value = 3

		XCTAssertEqual(tracker.values.joined(separator: ", "), "A0, B0, B1, C1, D1, D2, D3")
	}

	func test_three() {
		let tracker = ClosureTracker<String>()
		let property0 = Property(initialValue: "A")
		let property1 = Property(initialValue: 0)
		let property2 = Property<Character>(initialValue: "a")
		let combined = ReadOnlyProperty.combineLatest(property0.readOnly, property1.readOnly, property2.readOnly)
			.map { "\($0)\($1)\($2)" }
		combined.values.addObserver(tracker.observer).dispose(in: pool)

		property0.value = "B"
		property1.value = 1
		property2.value = "b"
		property0.value = "C"
		property0.value = "D"
		property1.value = 2
		property1.value = 3
		property2.value = "c"
		property2.value = "d"

		XCTAssertEqual(tracker.values, ["A0a", "B0a", "B1a", "B1b", "C1b", "D1b", "D2b", "D3b", "D3c", "D3d"])
	}

	func test_four() {
		let tracker = ClosureTracker<String>()
		let property0 = Property(initialValue: "A")
		let property1 = Property(initialValue: 0)
		let property2 = Property<Character>(initialValue: "b")
		let property3 = Property<Decimal>(initialValue: 0)
		let combined = ReadOnlyProperty.combineLatest(
			property0.readOnly,
			property1.readOnly,
			property2.readOnly,
			property3.readOnly
		).map { "\($0)\($1)\($2)\($3)" }
		combined.values.addObserver(tracker.observer).dispose(in: pool)

		property2.value = "b"
		property3.value = 1
		property0.value = "C"
		property1.value = 2
		property2.value = "d"
		property3.value = 3

		XCTAssertEqual(tracker.values, ["A0b0", "A0b0", "A0b1", "C0b1", "C2b1", "C2d1", "C2d3"])
	}

	func test_array() {
		let tracker = ClosureTracker<String>()
		let property0 = Property(initialValue: "A")
		let property1 = Property(initialValue: "0")
		let combined = ReadOnlyProperty
			.combineLatest([property0.readOnly, property1.readOnly])
			.map { $0.joined() }
		combined.values.addObserver(tracker.observer).dispose(in: pool)

		property0.value = "B"
		property1.value = "1"
		property0.value = "C"
		property0.value = "D"
		property1.value = "2"
		property1.value = "3"

		XCTAssertEqual(tracker.values, ["A0", "B0", "B1", "C1", "D1", "D2", "D3"])
	}

	func test_twoOfTheSame() {
		let tracker = ClosureTracker<Int>()
		let property = Property(initialValue: 1)
		let combined = ReadOnlyProperty
			.combineLatest(property.readOnly, property.readOnly)
			.map { $0 * 10 + $1 }
		combined.values.addObserver(tracker.observer).dispose(in: pool)

		property.value = 2
		property.value = 3
		property.value = 4

		XCTAssertEqual(tracker.values, [11, 22, 22, 33, 33, 44, 44])
	}
}
