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
                let window=app.windows.firstMatch.frame
                let frame=button.frame
                if deviceOrientation == .portrait {
                    XCTAssertGreaterThan(frame.midY,window.maxY-window.height/3)
                } else if deviceOrientation == .landscapeLeft {
                    XCTAssertLessThan(app.buttons["switch.tanpura"].frame.midY,app.buttons["switch.harmonium"].frame.midY)
                    XCTAssertLessThanOrEqual(frame.width,52)
                    // Device and interface landscape orientation names are opposite.
                    XCTAssertGreaterThan(frame.midX,window.maxX-window.width/3)
                } else {
                    XCTAssertLessThan(app.buttons["switch.harmonium"].frame.midY,app.buttons["switch.tanpura"].frame.midY)
                    XCTAssertLessThanOrEqual(frame.width,52)
                    XCTAssertLessThan(frame.midX,window.minX+window.width/3)
                }
                if instrument == "tanpura" { XCTAssertTrue(app.buttons["tanpura.playPause"].exists) }
                else {
                    XCTAssertTrue(app.otherElements["harmonium.keyboard"].exists)
                    let slider=app.sliders["harmonium.navigation"]
                    XCTAssertTrue(slider.exists)
                    slider.adjust(toNormalizedSliderPosition:0.3)
                }
                let attachment=XCTAttachment(screenshot:XCUIScreen.main.screenshot())
                attachment.name="\(instrument)-\(deviceOrientation.rawValue)"
                attachment.lifetime = .keepAlways
                add(attachment)
            }
        }
        XCUIDevice.shared.orientation = .portrait
    }
}
