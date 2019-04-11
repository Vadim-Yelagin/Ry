import XCTest
import Ry

class PropertyTests: XCTestCase {
	private let pool = DisposePool()

	func test_initialValue() {
		let property = Property(initialValue: 42)
		XCTAssertEqual(property.value, 42)
	}

	func test_initialValueSignal() {
		let tracker = ClosureTracker<Int>()
		let property = Property(initialValue: 42)

		property.values.addObserver(tracker.observer).dispose(in: pool)

		XCTAssertEqual(tracker.values, [42])
	}

	func test_currentValue() {
		let property = Property(initialValue: 42)
		property.value = 15
		property.value = 33
		XCTAssertEqual(property.value, 33)
	}

	func test_valuesSignal() {
		let tracker = ClosureTracker<Int>()
		let property = Property(initialValue: 42)
		property.value = 15
		property.value = 33

		property.values.addObserver(tracker.observer).dispose(in: pool)
		property.value = 67
		property.value = 4

		XCTAssertEqual(tracker.values, [33, 67, 4])
	}

	func test_newValuesSignal() {
		let tracker = ClosureTracker<Int>()
		let property = Property(initialValue: 42)
		property.value = 15
		property.value = 33

		property.newValues.addObserver(tracker.observer).dispose(in: pool)
		property.value = 67
		property.value = 4

		XCTAssertEqual(tracker.values, [67, 4])
	}

	func test_bimap_value() {
		let property0 = Property(initialValue: 42)
		let property1 = property0.bimap(to: { $0 + 100 }, from: { $0 - 100 })

		XCTAssertEqual(property0.value, 42)
		XCTAssertEqual(property1.value, 142)

		property0.value = 13

		XCTAssertEqual(property0.value, 13)
		XCTAssertEqual(property1.value, 113)

		property1.value = 192

		XCTAssertEqual(property0.value, 92)
		XCTAssertEqual(property1.value, 192)
	}

	func test_bimap_values() {
		let tracker0 = ClosureTracker<Int>()
		let tracker1 = ClosureTracker<Int>()
		let property0 = Property(initialValue: 42)
		let property1 = property0.bimap(to: { $0 + 100 }, from: { $0 - 100 })
		property0.values.addObserver(tracker0.observer).dispose(in: pool)
		property1.values.addObserver(tracker1.observer).dispose(in: pool)

		property0.value = 13
		property1.value = 192

		XCTAssertEqual(tracker0.values, [42, 13, 92])
		XCTAssertEqual(tracker1.values, [142, 113, 192])
	}

	func test_map_value() {
		let property0 = Property(initialValue: 42)
		let property1 = property0.readOnly.map { "\($0)?" }
		XCTAssertEqual(property1.value, "42?")
		property0.value = 13
		XCTAssertEqual(property1.value, "13?")
	}

	func test_map_values() {
		let tracker = ClosureTracker<String>()
		let property0 = Property(initialValue: 42)
		let property1 = property0.readOnly.map { "\($0)?" }
		property1.values.addObserver(tracker.observer).dispose(in: pool)

		property0.value = 13
		property0.value = 92

		XCTAssertEqual(tracker.values, ["42?", "13?", "92?"])
	}

	func test_switchMap_value() {
		let property0 = Property(initialValue: 0)
		let properties = [Property(initialValue: "A"), Property(initialValue: "b"), Property(initialValue: "c")]
		let property1 = property0.readOnly.switchMap { properties[$0].readOnly }

		XCTAssertEqual(property1.value, "A")

		properties[0].value = "D"

		XCTAssertEqual(property1.value, "D")

		property0.value = 1
		properties[2].value = "e"

		XCTAssertEqual(property1.value, "b")

		property0.value = 2

		XCTAssertEqual(property1.value, "e")
	}

	func test_switchMap_values() {
		let tracker = ClosureTracker<String>()
		let property0 = Property(initialValue: 0)
		let properties = [Property(initialValue: "A"), Property(initialValue: "b"), Property(initialValue: "c")]
		let property1 = property0.readOnly.switchMap { properties[$0].readOnly }
		property1.values.addObserver(tracker.observer).dispose(in: pool)

		properties[0].value = "D"
		property0.value = 1
		properties[2].value = "e"
		property0.value = 2
		properties[1].value = "f"
		properties[2].value = "g"

		XCTAssertEqual(tracker.values.joined(), "ADbeg")
	}
}
