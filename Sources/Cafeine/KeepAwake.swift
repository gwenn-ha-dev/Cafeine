import Foundation
import IOKit.pwr_mgt

/// Une assertion de gestion d'énergie, tenue ou non.
///
/// C'est l'API que `caffeinate` utilise lui-même : on la prend directement, sans
/// sous-processus à relancer. Le noyau libère l'assertion si le processus meurt,
/// donc rien ne peut rester coincé après un plantage.
@MainActor
final class KeepAwake {
    static let assertionName = "Cafeine"

    private var assertionID: IOPMAssertionID = 0
    private var expiryTask: Task<Void, Never>?

    /// Fin prévue, ou `nil` si l'assertion est tenue sans limite (ou pas tenue).
    private(set) var expiry: Date?
    /// Vrai si l'écran a le droit de s'éteindre pendant que le système reste éveillé.
    private(set) var allowsDisplaySleep = false

    /// Appelé à chaque changement d'état, y compris à l'expiration.
    var onChange: (() -> Void)?

    var isActive: Bool { assertionID != 0 }

    /// Prend l'assertion, pour `duration` secondes ou sans limite. Remplace celle
    /// déjà tenue. Rend `false` si le système la refuse.
    @discardableResult
    func activate(for duration: TimeInterval?, allowDisplaySleep: Bool) -> Bool {
        release()
        let type = allowDisplaySleep ? kIOPMAssertPreventUserIdleSystemSleep : kIOPMAssertPreventUserIdleDisplaySleep
        let result = IOPMAssertionCreateWithName(type as CFString,
                                                 IOPMAssertionLevel(kIOPMAssertionLevelOn),
                                                 Self.assertionName as CFString,
                                                 &assertionID)
        guard result == kIOReturnSuccess else {
            assertionID = 0
            onChange?()
            return false
        }
        allowsDisplaySleep = allowDisplaySleep
        if let duration {
            expiry = Date().addingTimeInterval(duration)
            expiryTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(duration))
                guard !Task.isCancelled else { return }
                self?.deactivate()
            }
        }
        onChange?()
        return true
    }

    func deactivate() {
        release()
        onChange?()
    }

    private func release() {
        expiryTask?.cancel()
        expiryTask = nil
        expiry = nil
        if assertionID != 0 {
            IOPMAssertionRelease(assertionID)
            assertionID = 0
        }
    }
}
