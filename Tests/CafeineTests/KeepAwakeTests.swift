import IOKit.pwr_mgt
import XCTest
@testable import Cafeine

@MainActor
final class KeepAwakeTests: XCTestCase {
    /// Les types d'assertion que ce processus tient sous le nom de Cafeine, d'après le système.
    private func heldTypes() -> [String] {
        var byProcess: Unmanaged<CFDictionary>?
        guard IOPMCopyAssertionsByProcess(&byProcess) == kIOReturnSuccess,
              let all = byProcess?.takeRetainedValue() as? [Int: [[String: Any]]] else { return [] }
        return (all[Int(getpid())] ?? [])
            .filter { $0[kIOPMAssertionNameKey] as? String == KeepAwake.assertionName }
            .compactMap { $0[kIOPMAssertionTypeKey] as? String }
    }

    func testActivateHoldsAnAssertionTheSystemSees() {
        let keepAwake = KeepAwake()
        XCTAssertTrue(keepAwake.activate(for: nil, allowDisplaySleep: false))
        XCTAssertTrue(keepAwake.isActive)
        XCTAssertNil(keepAwake.expiry)
        XCTAssertEqual(heldTypes(), [kIOPMAssertPreventUserIdleDisplaySleep])

        keepAwake.deactivate()
        XCTAssertFalse(keepAwake.isActive)
        XCTAssertEqual(heldTypes(), [])
    }

    func testDisplaySleepUsesTheSystemAssertion() {
        let keepAwake = KeepAwake()
        keepAwake.activate(for: nil, allowDisplaySleep: true)
        XCTAssertEqual(heldTypes(), [kIOPMAssertPreventUserIdleSystemSleep])
        keepAwake.deactivate()
    }

    func testReactivatingReplacesTheAssertion() {
        let keepAwake = KeepAwake()
        keepAwake.activate(for: nil, allowDisplaySleep: false)
        keepAwake.activate(for: 3600, allowDisplaySleep: true)
        XCTAssertEqual(heldTypes(), [kIOPMAssertPreventUserIdleSystemSleep])
        XCTAssertNotNil(keepAwake.expiry)
        keepAwake.deactivate()
        XCTAssertNil(keepAwake.expiry)
    }

    func testExpiryReleasesTheAssertionAndNotifies() async throws {
        let keepAwake = KeepAwake()
        let expired = expectation(description: "expired")
        keepAwake.activate(for: 0.2, allowDisplaySleep: false)
        keepAwake.onChange = { if !keepAwake.isActive { expired.fulfill() } }
        await fulfillment(of: [expired], timeout: 2)
        XCTAssertEqual(heldTypes(), [])
    }

    func testDeactivateCancelsThePendingExpiry() async throws {
        let keepAwake = KeepAwake()
        keepAwake.activate(for: 0.2, allowDisplaySleep: false)
        keepAwake.deactivate()
        keepAwake.activate(for: nil, allowDisplaySleep: false)
        try await Task.sleep(for: .milliseconds(400))
        XCTAssertTrue(keepAwake.isActive, "the cancelled timer must not end the new activation")
        keepAwake.deactivate()
    }
}
