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
            for instrument in ["harmonium","tanpura","tabla"] {
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
                    XCTAssertLessThan(app.buttons["switch.tabla"].frame.midY,app.buttons["switch.tanpura"].frame.midY)
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
                else if instrument == "tabla" {
                    XCTAssertTrue(app.buttons["tabla.playPause"].isHittable)
                    XCTAssertTrue(app.sliders["tabla.volume"].isHittable)
                } else {
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
                        if deviceOrientation == .landscapeLeft {
                            XCTAssertLessThan(keyboard.minX-window.minX,40,"Notch-side keyboard margin must be reclaimed")
                            XCTAssertLessThanOrEqual(keyboard.maxX,frame.minX,"Keyboard must not extend behind the switcher")
                            XCTAssertLessThan(app.buttons["harmonium.settings"].frame.maxX,frame.minX)
                        } else {
                            XCTAssertLessThan(window.maxX-keyboard.maxX,40,"Notch-side keyboard margin must be reclaimed")
                            XCTAssertGreaterThanOrEqual(keyboard.minX,frame.maxX,"Keyboard must not extend behind the switcher")
                            XCTAssertGreaterThan(app.buttons["harmonium.enable"].frame.minX,frame.maxX)
                        }
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
        app.buttons["switch.tabla"].tap()
        XCTAssertTrue(app.buttons["tabla.exitFullscreen"].isHittable)
        XCTAssertTrue(landscape.evaluate(with:nil))
        app.buttons["switch.tanpura"].tap()
        XCUIDevice.shared.orientation = .landscapeLeft;sleep(2)
        XCUIDevice.shared.orientation = .portrait
        let portrait=NSPredicate { _,_ in app.windows.firstMatch.frame.height>app.windows.firstMatch.frame.width }
        XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:portrait,object:nil)],timeout:10),.completed)
        app.buttons["switch.harmonium"].tap()
        XCTAssertTrue(app.buttons["harmonium.fullscreen"].exists)
        // Reproduce the same-session path missing from the old fresh-launch test:
        // normal rotation must still work after programmatic portrait restoration.
        sleep(1)
        for deviceOrientation in [UIDeviceOrientation.landscapeRight,.portrait,.landscapeLeft,.portrait] {
            XCUIDevice.shared.orientation=deviceOrientation
            let expected=deviceOrientation == .portrait ? portrait:landscape
            XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:expected,object:nil)],timeout:10),.completed)
            XCTAssertFalse(app.buttons["harmonium.exitFullscreen"].exists,"Normal rotation must not leave forced mode active")
        }

    }
    func testPortraitKeyboardStaysVisibleWhileSettingsScrollToSpeed() {
        let app=XCUIApplication();continueAfterFailure=false
        XCUIDevice.shared.orientation = .portrait;app.launch()
        let keyboard=app.otherElements["harmonium.keyboard"]
        XCTAssertTrue(keyboard.waitForExistence(timeout:10));XCTAssertTrue(keyboard.isHittable)
        let original=keyboard.frame
        XCTAssertLessThan(original.maxY,app.buttons["switch.harmonium"].frame.minY+1)
        let enable=app.buttons["harmonium.enable"]
        if enable.label.contains("Enable") { enable.tap() }
        let settings=app.scrollViews["harmonium.settingsScroll"]
        XCTAssertTrue(settings.exists)
        let speed=app.sliders["harmonium.speed"]
        for _ in 0..<5 where !speed.isHittable { settings.swipeUp() }
        XCTAssertTrue(speed.isHittable,"Tanpura speed must be reachable by scrolling")
        let oldValue=speed.value as? String;speed.adjust(toNormalizedSliderPosition:0.8)
        XCTAssertNotEqual(speed.value as? String,oldValue)
        XCTAssertTrue(keyboard.isHittable)
        XCTAssertEqual(keyboard.frame.minY,original.minY,accuracy:1,"Keyboard must remain pinned while controls scroll")
        let shot=XCTAttachment(screenshot:XCUIScreen.main.screenshot())
        shot.name="portrait-speed-and-pinned-keyboard";shot.lifetime = .keepAlways;add(shot)
        app.buttons["harmonium.settings"].tap()
        let sheetSpeed=app.sliders["harmonium.speed.sheet"]
        XCTAssertTrue(sheetSpeed.waitForExistence(timeout:10))
        for _ in 0..<3 where !sheetSpeed.isHittable { app.swipeUp() }
        XCTAssertTrue(sheetSpeed.isHittable);sheetSpeed.adjust(toNormalizedSliderPosition:0.4)
        app.buttons["Done"].tap();XCTAssertTrue(keyboard.isHittable)
    }
    func testTablaTransportPersistenceAndBackground() {
        let app=XCUIApplication();continueAfterFailure=false
        XCUIDevice.shared.orientation = .portrait;app.launch()
        app.buttons["switch.tabla"].tap()
        let play=app.buttons["tabla.playPause"]
        XCTAssertTrue(play.waitForExistence(timeout:10));play.tap()
        XCTAssertTrue(play.label.contains("Pause"))
        sleep(1)
        let before=app.staticTexts["tabla.matra"].label
        sleep(1)
        XCTAssertNotEqual(app.staticTexts["tabla.matra"].label,before)
        play.tap();XCTAssertTrue(play.label.contains("Resume"))
        let paused=app.staticTexts["tabla.matra"].label;sleep(1)
        XCTAssertEqual(app.staticTexts["tabla.matra"].label,paused)
        play.tap();XCTAssertTrue(play.label.contains("Pause"))
        app.sliders["tabla.tempo"].adjust(toNormalizedSliderPosition:0.5)
        app.sliders["tabla.volume"].adjust(toNormalizedSliderPosition:0.35)
        let tempo=app.staticTexts["tabla.bpmLabel"].label
        let volume=app.sliders["tabla.volume"].value as? String
        app.buttons["tabla.taal"].tap();app.buttons["Jhaptal · 10"].tap()
        app.buttons["switch.tanpura"].tap();app.buttons["tanpura.playPause"].tap()
        XCUIDevice.shared.press(.home);sleep(2);app.activate()
        app.buttons["switch.tabla"].tap();XCTAssertTrue(play.label.contains("Pause"))
        app.buttons["tabla.stop"].tap();XCTAssertTrue(play.label.contains("Start"))
        app.terminate();app.launch();app.buttons["switch.tabla"].tap()
        XCTAssertEqual(app.staticTexts["tabla.bpmLabel"].label,tempo)
        XCTAssertEqual(app.sliders["tabla.volume"].value as? String,volume)
        XCTAssertTrue(app.buttons["tabla.taal"].label.contains("Jhaptal"))
        XCTAssertTrue(play.label.contains("Start"))
    }
    func testSharedAccompanimentInterruptionAndEngineRecovery() {
        let app=XCUIApplication();continueAfterFailure=false
        app.launchArguments=["--phase5-audio-regression"]
        XCUIDevice.shared.orientation = .portrait;app.launch()
        app.buttons["switch.tanpura"].tap();app.buttons["tanpura.playPause"].tap()
        app.buttons["switch.tabla"].tap();app.buttons["tabla.playPause"].tap()
        for _ in 0..<4 where !app.buttons["tabla.testBegin"].isHittable { app.swipeUp() }
        app.buttons["tabla.testBegin"].tap();sleep(1)
        XCTAssertTrue(app.buttons["tabla.playPause"].label.contains("Start"))
        app.buttons["tabla.testEnd"].tap();sleep(1)
        XCTAssertTrue(app.buttons["tabla.playPause"].label.contains("Pause"))
        app.buttons["tabla.testRecover"].tap();sleep(1)
        XCTAssertTrue(app.buttons["tabla.playPause"].label.contains("Pause"))
        app.buttons["switch.tanpura"].tap()
        XCTAssertTrue(app.buttons["tanpura.playPause"].label.contains("Pause"))
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
