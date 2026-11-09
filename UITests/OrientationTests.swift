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
                let shot=XCUIScreen.main.screenshot()
                XCTAssertGreaterThan(accentPixels(shot,frame:button.frame),accentPixels(shot,frame:other.frame)+3)

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
                    let enable=app.buttons["harmonium.enable"]
                    if enable.label.contains("Enable") { enable.tap() }

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
    private func accentPixels(_ screenshot: XCUIScreenshot, frame: CGRect) -> Int {
        let image=screenshot.image
        guard let cg=image.cgImage else { return 0 }
        let width=cg.width, height=cg.height
        var bytes=[UInt8](repeating:0,count:width*height*4)
        let scale=CGFloat(width)/XCUIApplication().windows.firstMatch.frame.width
        let count=bytes.withUnsafeMutableBytes { raw -> Int in
            guard let context=CGContext(data:raw.baseAddress,width:width,height:height,
                bitsPerComponent:8,bytesPerRow:width*4,space:CGColorSpaceCreateDeviceRGB(),
                bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue) else { return 0 }
            context.draw(cg,in:CGRect(x:0,y:0,width:CGFloat(width),height:CGFloat(height)))
            var total=0
            for y in max(0,Int(frame.minY*scale))..<min(height,Int(frame.maxY*scale)) {
                for x in max(0,Int(frame.minX*scale))..<min(width,Int(frame.maxX*scale)) {
                    let i=(y*width+x)*4
                    if Int(raw[i+2]) > Int(raw[i])+45 && Int(raw[i+2]) > Int(raw[i+1])+15 { total += 1 }
                }
            }
            return total
        }
        return count
    }

}
