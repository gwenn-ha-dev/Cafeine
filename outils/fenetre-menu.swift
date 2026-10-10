// Le numéro de la fenêtre du menu ouvert de Cafeine, pour `screencapture -l`.
//
//     swift outils/fenetre-menu.swift
//
// `Charte/outils/capturer.sh` ne retient que les fenêtres de niveau 0 : un menu
// vit au-dessus (niveau 101), et Cafeine n'a pas d'autre fenêtre à montrer.
import AppKit

let pids = Set(NSWorkspace.shared.runningApplications
    .filter { $0.executableURL?.lastPathComponent == "Cafeine" }
    .map { Int($0.processIdentifier) })
let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []
let menu = windows.first {
    pids.contains($0[kCGWindowOwnerPID as String] as? Int ?? -1)
        && ($0[kCGWindowLayer as String] as? Int ?? 0) == Int(CGWindowLevelForKey(.popUpMenuWindow))
}
guard let id = menu?[kCGWindowNumber as String] as? Int else {
    FileHandle.standardError.write(Data("fenetre-menu: no open Cafeine menu\n".utf8))
    exit(1)
}
print(id)
