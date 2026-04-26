//
//  Drops
//
//  Copyright (c) 2021-Present Omar Albeik - https://github.com/omaralbeik
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#if os(iOS)
import XCTest
@testable import Drops

final class DropsTests: XCTestCase {
  func testShow() async {
    let drops = Drops()

    let drop1 = Drop(title: "Test 1", duration: .seconds(1))
    drops.show(drop1)
    await Task.sleep(seconds: 0.1)
    if drops.current == nil {
      XCTFail("First drop is not presented")
    }

    await Task.sleep(seconds: 2)
    if drops.current != nil {
      XCTFail("First drop is not hidden")
    }
  }

  func testStaticShow() async {
    Drops.shared = .init(delayBetweenDrops: 0)

    let drop1 = Drop(title: "Test 1", duration: .seconds(1))
    Drops.show(drop1)

    await Task.sleep(seconds: 0.1)
    if Drops.shared.current == nil {
      XCTFail("First drop is not presented")
    }

    await Task.sleep(seconds: 2)
    if Drops.shared.current != nil {
      XCTFail("First drop is not hidden")
    }
  }

  func testDropsAreQueued() async throws {
    let drops = Drops(delayBetweenDrops: 0)
    (0..<5)
      .map { Drop(title: "\($0)", duration: .seconds(0.1)) }
      .forEach(drops.show)

    await Task.sleep(seconds: 0.1)
    if drops.queue.count != 4 {
      XCTFail("First drop is not hidden")
    }

    await Task.sleep(seconds: 5)
    if drops.queue.isEmpty == false {
      XCTFail("All drops are not hidden")
    }
  }

  func testStaticDropsAreQueued() async {
    Drops.shared = .init(delayBetweenDrops: 0)

    (0..<5)
      .map { Drop(title: "\($0)", duration: .seconds(0.1)) }
      .forEach(Drops.show)

    await Task.sleep(seconds: 0.1)
    if Drops.shared.queue.count != 4 {
      XCTFail("First drop is not hidden")
    }

    await Task.sleep(seconds: 5)
    if Drops.shared.queue.isEmpty == false {
      XCTFail("All drops are not hidden")
    }
  }

  func testHideAll() {
    let drops = Drops(delayBetweenDrops: 0)

    (0..<10)
      .map { Drop(title: "\($0)", duration: .seconds(0.1)) }
      .forEach(drops.show)

    drops.hideAll()

    XCTAssert(drops.queue.isEmpty)
  }

  func testStaticHideAll() {
    Drops.shared = .init(delayBetweenDrops: 0)

    (0..<10)
      .map { Drop(title: "\($0)", duration: .seconds(0.1)) }
      .forEach(Drops.show)

    Drops.hideAll()

    XCTAssert(Drops.shared.queue.isEmpty)
  }

  func testHandlers() {
    let drops = Drops(delayBetweenDrops: 0)
    let expectedDrop = Drop(title: "Hello world!", duration: .seconds(0.1))

    let willShowDropExp = expectation(description: "willShowDrop is called")
    let didShowDropExp = expectation(description: "didShowDrop is called")
    let willDismissDropExp = expectation(description: "willDismissDrop is called")
    let didDismissDropExp = expectation(description: "didDismissDrop is called")

    drops.willShowDrop = { drop in
      XCTAssertEqual(drop, expectedDrop)
      willShowDropExp.fulfill()
    }

    drops.didShowDrop = { drop in
      XCTAssertEqual(drop, expectedDrop)
      didShowDropExp.fulfill()
    }

    drops.willDismissDrop = { drop in
      XCTAssertEqual(drop, expectedDrop)
      willDismissDropExp.fulfill()
    }

    drops.didDismissDrop = { drop in
      XCTAssertEqual(drop, expectedDrop)
      didDismissDropExp.fulfill()
    }

    drops.show(expectedDrop)

    waitForExpectations(timeout: 2)
  }

  func testStaticHandlers() {
    Drops.shared = .init(delayBetweenDrops: 0)

    let expectedDrop = Drop(title: "Hello world!", duration: .seconds(0.1))

    let willShowDropExp = expectation(description: "willShowDrop is called")
    let didShowDropExp = expectation(description: "didShowDrop is called")
    let willDismissDropExp = expectation(description: "willDismissDrop is called")
    let didDismissDropExp = expectation(description: "didDismissDrop is called")

    Drops.willShowDrop = { drop in
      XCTAssertEqual(drop, expectedDrop)
      willShowDropExp.fulfill()
    }

    Drops.didShowDrop = { drop in
      XCTAssertEqual(drop, expectedDrop)
      didShowDropExp.fulfill()
    }

    Drops.willDismissDrop = { drop in
      XCTAssertEqual(drop, expectedDrop)
      willDismissDropExp.fulfill()
    }

    Drops.didDismissDrop = { drop in
      XCTAssertEqual(drop, expectedDrop)
      didDismissDropExp.fulfill()
    }

    Drops.show(expectedDrop)

    waitForExpectations(timeout: 2)
  }

  func testStaticHandlersSettersAndGetters() {
    Drops.willShowDrop = { _ in }
    XCTAssertNotNil(Drops.shared.willShowDrop)
    Drops.willShowDrop = nil
    XCTAssertNil(Drops.shared.willShowDrop)

    Drops.didShowDrop = { _ in }
    XCTAssertNotNil(Drops.shared.didShowDrop)
    Drops.didShowDrop = nil
    XCTAssertNil(Drops.shared.didShowDrop)

    Drops.willDismissDrop = { _ in }
    XCTAssertNotNil(Drops.shared.willDismissDrop)
    Drops.willDismissDrop = nil
    XCTAssertNil(Drops.shared.willDismissDrop)

    Drops.didDismissDrop = { _ in }
    XCTAssertNotNil(Drops.shared.didDismissDrop)
    Drops.didDismissDrop = nil
    XCTAssertNil(Drops.shared.didDismissDrop)

    Drops.shared.willShowDrop = { _ in }
    XCTAssertNotNil(Drops.willShowDrop)
    Drops.shared.willShowDrop = nil
    XCTAssertNil(Drops.willShowDrop)

    Drops.shared.didShowDrop = { _ in }
    XCTAssertNotNil(Drops.didShowDrop)
    Drops.shared.didShowDrop = nil
    XCTAssertNil(Drops.didShowDrop)

    Drops.shared.willDismissDrop = { _ in }
    XCTAssertNotNil(Drops.willDismissDrop)
    Drops.shared.willDismissDrop = nil
    XCTAssertNil(Drops.willDismissDrop)

    Drops.shared.didDismissDrop = { _ in }
    XCTAssertNotNil(Drops.didDismissDrop)
    Drops.shared.didDismissDrop = nil
    XCTAssertNil(Drops.didDismissDrop)
  }

  func testShowWithMatchingIDUpdatesCurrentPresenter() async throws {
    let drops = Drops(delayBetweenDrops: 0)
    let initial = Drop(
      title: "Downloading",
      subtitle: "25%",
      duration: .untilHidden,
      id: "mlx-job",
      progress: .determinate(0.25)
    )
    drops.show(initial)

    await Task.sleep(seconds: 0.1)
    let currentPresenter = try XCTUnwrap(drops.current)

    let updated = Drop(
      title: "Downloading",
      subtitle: "60%",
      duration: .untilHidden,
      id: "mlx-job",
      progress: .determinate(0.6)
    )
    drops.show(updated)

    await Task.sleep(seconds: 0.1)
    XCTAssertTrue(drops.current === currentPresenter)
    XCTAssertEqual(drops.queue.count, 0)
    XCTAssertEqual(drops.current?.drop.subtitle, "60%")
    XCTAssertEqual(drops.current?.drop.progress?.fractionCompleted, 0.6)
  }

  func testShowWithMatchingIDReplacesQueuedPresenter() async {
    let drops = Drops(delayBetweenDrops: 0)

    drops.show(Drop(title: "Current", duration: .untilHidden))
    drops.show(Drop(title: "Queued 1", duration: .seconds(1), id: "mlx-job"))
    drops.show(Drop(title: "Queued 2", duration: .seconds(1), id: "other"))

    await Task.sleep(seconds: 0.1)
    XCTAssertEqual(drops.queue.count, 2)

    drops.show(Drop(title: "Queued Replacement", duration: .seconds(1), id: "mlx-job"))

    await Task.sleep(seconds: 0.1)
    XCTAssertEqual(drops.queue.count, 2)
    XCTAssertEqual(drops.queue.first?.drop.title, "Queued Replacement")
  }

  func testPersistentDropDoesNotAutoHide() async {
    let drops = Drops(delayBetweenDrops: 0)
    drops.show(Drop(title: "Downloading", duration: .untilHidden, id: "mlx-job"))

    await Task.sleep(seconds: 0.1)
    XCTAssertNotNil(drops.current)

    await Task.sleep(seconds: 2.5)
    XCTAssertNotNil(drops.current)
  }

  func testUpdatingPersistentDropToTimedDurationRestartsAutoHide() async {
    let drops = Drops(delayBetweenDrops: 0)
    drops.show(Drop(title: "Downloading", duration: .untilHidden, id: "mlx-job"))

    await Task.sleep(seconds: 0.1)
    XCTAssertNotNil(drops.current)

    drops.show(Drop(title: "Completed", duration: .seconds(0.2), id: "mlx-job"))

    await Task.sleep(seconds: 0.1)
    XCTAssertEqual(drops.current?.drop.title, "Completed")

    await Task.sleep(seconds: 0.8)
    XCTAssertNil(drops.current)
  }

  func testUnmatchedIDStillQueuesNormally() async {
    let drops = Drops(delayBetweenDrops: 0)
    drops.show(Drop(title: "Current", duration: .untilHidden, id: "current"))

    await Task.sleep(seconds: 0.1)
    drops.show(Drop(title: "Different", duration: .seconds(1), id: "other"))

    await Task.sleep(seconds: 0.1)
    XCTAssertEqual(drops.queue.count, 1)
    XCTAssertEqual(drops.queue.first?.drop.id, "other")
  }
}

private extension Task where Success == Never, Failure == Never {
  static func sleep(seconds: Double) async {
    let duration = UInt64(seconds * 1_000_000_000)
    do {
      try await Task.sleep(nanoseconds: duration)
    } catch {
      XCTFail(error.localizedDescription)
    }
  }
}
#endif
