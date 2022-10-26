//
//  Utility.swift
//  Caffeinate
//
//  Created by Lennard on 26.10.22.
//

import SwiftUI

extension View {
    
    private func findWindowWithTag(identifier: String) -> NSWindow? {
        return NSApplication.shared.windows.filter({ $0.identifier?.rawValue == identifier }).first
    }
        
    func openNewWindowWithToolbar(title: String, rect: NSRect, style: NSWindow.StyleMask,identifier :String = "", toolbar: some View) -> NSWindow {
        if !identifier.isEmpty {
            if let window = findWindowWithTag(identifier: identifier) {
                window.orderFrontRegardless()
                return window
            }
        }
        
        let titlebarAccessoryView = toolbar.padding(.top, -5).padding(.leading, -8)
        
        let accessoryHostingView = NSHostingView(rootView: titlebarAccessoryView)
        accessoryHostingView.frame.size = accessoryHostingView.fittingSize

        let titlebarAccessory = NSTitlebarAccessoryViewController()
        titlebarAccessory.view = accessoryHostingView

        let window = NSWindow(
            contentRect: rect,
            styleMask: style,
            backing: .buffered,
            defer: false)
        window.center()
        window.title = title
        window.isReleasedWhenClosed = false
        window.identifier = NSUserInterfaceItemIdentifier(identifier)
        
        window.addTitlebarAccessoryViewController(titlebarAccessory)
        window.toolbarStyle = .preference

        window.contentView = NSHostingView(rootView: self)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()

        return window
    }
}

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

extension NSImage {
    func resizeImage(tamanho: NSSize) -> NSImage {

        var ratio: Float = 0.0
        let imageWidth = Float(self.size.width)
        let imageHeight = Float(self.size.height)
        let maxWidth = Float(tamanho.width)
        let maxHeight = Float(tamanho.height)

        // Get ratio (landscape or portrait)
        if (imageWidth > imageHeight) {
            // Landscape
            ratio = maxWidth / imageWidth;
        }
        else {
            // Portrait
            ratio = maxHeight / imageHeight;
        }

        // Calculate new size based on the ratio
        let newWidth = imageWidth * ratio
        let newHeight = imageHeight * ratio

        let imageSo = CGImageSourceCreateWithData(self.tiffRepresentation! as CFData, nil)
        let options: [NSString: NSObject] = [
            kCGImageSourceThumbnailMaxPixelSize: max(imageWidth, imageHeight) * ratio as NSObject,
            kCGImageSourceCreateThumbnailFromImageAlways: true as NSObject
        ]
        let size1 = NSSize(width: Int(newWidth), height: Int(newHeight))
        let scaledImage = CGImageSourceCreateThumbnailAtIndex(imageSo!, 0, options as CFDictionary).flatMap {
            NSImage(cgImage: $0, size: size1)
        }

        return scaledImage!
    }

}
