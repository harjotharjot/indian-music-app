import XCTest
import UIKit

final class OrientationTests: XCTestCase {
    func testSwitcherTracksChargingPortInBothScreens() {
        let app=XCUIApplication()
        continueAfterFailure=false
        XCUIDevice.shared.orientation = .portrait
        app.launch()
        for deviceOrientation in [UIDeviceOrientation.portrait,.landscapeLeft,.landscapeRight] {
            XCUIDevice.shared.orientation=deviceOrientation
            sleep(2)
            for instrument in ["harmonium","tanpura"] {
                let button=app.buttons["switch.\(instrument)"]
                XCTAssertTrue(button.waitForExistence(timeout:10))
                XCTAssertTrue(button.isHittable)
                button.tap()
                sleep(1)
                XCTAssertEqual(button.value as? String,"Selected")
                let other=app.buttons["switch.\(instrument == "harmonium" ? "tanpura":"harmonium")"]
                XCTAssertNotEqual(other.value as? String, "Selected")
                let selectedShot=button.screenshot(), otherShot=other.screenshot()
                let selectedAttachment=XCTAttachment(screenshot:selectedShot)
                selectedAttachment.name="selected-\(instrument)-\(deviceOrientation.rawValue)"
                selectedAttachment.lifetime = .keepAlways; add(selectedAttachment)
                XCTAssertGreaterThan(accentPixels(selectedShot),accentPixels(otherShot)+3)

                let window=app.windows.firstMatch.frame
                let frame=button.frame
                if deviceOrientation == .portrait {
                    XCTAssertGreaterThan(frame.midY,window.maxY-window.height/3)
                } else if deviceOrientation == .landscapeLeft {
                    XCTAssertLessThan(app.buttons["switch.tanpura"].frame.midY,app.buttons["switch.harmonium"].frame.midY)
                    XCTAssertLessThanOrEqual(frame.width,52)
                    // Device and interface landscape orientation names are opposite.
                    XCTAssertGreaterThan(frame.midX,window.maxX-window.width/3)
                    XCTAssertLessThan(window.maxX-frame.maxX,4)
                } else {
                    XCTAssertLessThan(app.buttons["switch.harmonium"].frame.midY,app.buttons["switch.tanpura"].frame.midY)
                    XCTAssertLessThanOrEqual(frame.width,52)
                    XCTAssertLessThan(frame.midX,window.minX+window.width/3)
                    XCTAssertLessThan(frame.minX-window.minX,4)
                }
                if instrument == "tanpura" { XCTAssertTrue(app.buttons["tanpura.playPause"].exists) }
                else {
                    XCTAssertTrue(app.otherElements["harmonium.keyboard"].exists)
                    let enable=app.buttons["harmonium.enable"]
                    if enable.label.contains("Enable") { enable.tap() }

                    let slider=app.sliders["harmonium.navigation"]
                    XCTAssertTrue(slider.exists)
                    if deviceOrientation == .portrait {
                        for _ in 0..<3 where !slider.isHittable { app.swipeUp() }
                    }
                    slider.adjust(toNormalizedSliderPosition:0.3)
                    if deviceOrientation != .portrait {
                        let keyboard=app.otherElements["harmonium.keyboard"].frame
                        XCTAssertLessThan(app.buttons["harmonium.enable"].frame.maxY,keyboard.minY)
                        XCTAssertLessThan(slider.frame.maxY,keyboard.minY+1)
                    }
                }
                let attachment=XCTAttachment(screenshot:XCUIScreen.main.screenshot())
                attachment.name="\(instrument)-\(deviceOrientation.rawValue)"
                attachment.lifetime = .keepAlways
                add(attachment)
            }
        }
        XCUIDevice.shared.orientation = .portrait
    }
    func testManualFullscreenAcrossTabsAndPhysicalPortraitReturn() {
        let app=XCUIApplication();continueAfterFailure=false
        XCUIDevice.shared.orientation = .portrait;app.launch()
        let full=app.buttons["harmonium.fullscreen"]
        XCTAssertTrue(full.waitForExistence(timeout:10));full.tap()
        let landscape=NSPredicate { _,_ in app.windows.firstMatch.frame.width>app.windows.firstMatch.frame.height }
        XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:landscape,object:nil)],timeout:10),.completed)
        sleep(1)
        app.buttons["switch.tanpura"].tap();sleep(1)
        XCTAssertTrue(app.buttons["tanpura.exitFullscreen"].isHittable)
        XCTAssertTrue(landscape.evaluate(with:nil),"Full-screen mode persists across tabs while phone is upright")
        XCUIDevice.shared.orientation = .landscapeLeft;sleep(2)
        XCUIDevice.shared.orientation = .portrait
        let portrait=NSPredicate { _,_ in app.windows.firstMatch.frame.height>app.windows.firstMatch.frame.width }
        XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:portrait,object:nil)],timeout:10),.completed)
        app.buttons["switch.harmonium"].tap()
        XCTAssertTrue(app.buttons["harmonium.fullscreen"].exists)
    }
    private func accentPixels(_ screenshot: XCUIScreenshot) -> Int {
        guard let cg=screenshot.image.cgImage else { return 0 }
        let width=cg.width, height=cg.height
        var bytes=[UInt8](repeating:0,count:width*height*4)
        return bytes.withUnsafeMutableBytes { raw -> Int in
            guard let context=CGContext(data:raw.baseAddress,width:width,height:height,
                bitsPerComponent:8,bytesPerRow:width*4,space:CGColorSpaceCreateDeviceRGB(),
                bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue) else { return 0 }
            context.draw(cg,in:CGRect(x:0,y:0,width:CGFloat(width),height:CGFloat(height)))
            var total=0
            for i in stride(from:0,to:raw.count,by:4) {
                if Int(raw[i+2]) > Int(raw[i])+45 && Int(raw[i+2]) > Int(raw[i+1])+15 { total += 1 }
            }
            return total
        }
    }
}
