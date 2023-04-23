//
//  ChuckPositionsIndivTests.swift
//
// Copyright 2021, 2022 OpenAlloc LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

@testable import FINporterChuck
import XCTest

import AllocData
import FINporter

final class ChuckPositionsIndivTests: XCTestCase {
    var imp: ChuckPositionsIndiv!
    let df = ISO8601DateFormatter()

    let goodHeader1 = """
    "Positions for account Individual ...234 as of 12:52 PM ET, 2023/04/23","","","","","","","","","","","","","","","",""
    "","","","","","","","","","","","","","","","",""
    "Symbol","Description","Quantity","Price","Price Change %","Price Change $","Market Value","Day Change %","Day Change $","Cost Basis","Gain/Loss %","Gain/Loss $","Ratings","Reinvest Dividends?","Capital Gains?","% Of Account","Security Type"
    """

    let goodHeader2 = "\"Positions for account Individual ...234 as of 12:52 PM ET, 2023/04/23\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\"\r\n\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\"\r\n\"Symbol\",\"Description\",\"Quantity\",\"Price\",\"Price Change %\",\"Price Change $\",\"Market Value\",\"Day Change %\",\"Day Change $\",\"Cost Basis\",\"Gain/Loss %\",\"Gain/Loss $\",\"Ratings\",\"Reinvest Dividends?\",\"Capital Gains?\",\"% Of Account\",\"Security Type\"\r\n"

    let goodBody = """
    "Positions for account Individual ...234 as of 12:52 PM ET, 2023/04/23","","","","","","","","","","","","","","","",""
    "","","","","","","","","","","","","","","","",""
    "Symbol","Description","Quantity","Price","Price Change %","Price Change $","Market Value","Day Change %","Day Change $","Cost Basis","Gain/Loss %","Gain/Loss $","Ratings","Reinvest Dividends?","Capital Gains?","% Of Account","Security Type"
    "SCHB","SCHWAB US BROAD MARKET ETF","500","$48.08","0.1%","$0.05","$24,040.00","0.1%","$25.00","$22,951.97","4.74%","$1,088.03","--","No","--","28.06%","ETFs & Closed End Funds"
    "Cash & Cash Investments","--","--","--","--","--","$650.37","0%","$0.00","--","--","--","--","--","--","0.76%","Cash and Money Market"
    "Account Total","--","--","--","--","--","$85,661.87","0.09%","$75.40","$79,275.80","7.24%","$5,735.70","--","--","--","--","--"


    """

    override func setUpWithError() throws {
        imp = ChuckPositionsIndiv()
    }

    func testSourceFormats() {
        let expected = Set([AllocFormat.CSV])
        let actual = Set(imp.sourceFormats)
        XCTAssertEqual(expected, actual)
    }

    func testTargetSchema() {
        let expected: [AllocSchema] = [.allocMetaSource, .allocAccount, .allocHolding, .allocSecurity]
        let actual = imp.outputSchemas
        XCTAssertEqual(expected, actual)
    }

    func testDetectFailsDueToHeaderMismatch() throws {
        let badHeader = goodHeader1.replacingOccurrences(of: "Symbol", with: "Symbal")
        let expected: FINporter.DetectResult = [:]
        let actual = try imp.detect(dataPrefix: badHeader.data(using: .utf8)!)
        XCTAssertEqual(expected, actual)
    }

    func testDetectSucceeds1() throws {
        let expected: FINporter.DetectResult = [.allocMetaSource: [.CSV], .allocAccount: [.CSV], .allocHolding: [.CSV], .allocSecurity: [.CSV]]
        let actual = try imp.detect(dataPrefix: goodHeader1.data(using: .utf8)!)
        XCTAssertEqual(expected, actual)
    }

    func testDetectSucceeds2() throws {
        let expected: FINporter.DetectResult = [.allocMetaSource: [.CSV], .allocAccount: [.CSV], .allocHolding: [.CSV], .allocSecurity: [.CSV]]
        let actual = try imp.detect(dataPrefix: goodHeader2.data(using: .utf8)!)
        XCTAssertEqual(expected, actual)
    }

    func testDetectViaMain() throws {
        let expected: FINporter.DetectResult = [.allocMetaSource: [.CSV], .allocAccount: [.CSV], .allocHolding: [.CSV], .allocSecurity: [.CSV]]
        let main = FINprospector([ChuckPositionsIndiv()])
        let data = goodHeader1.data(using: .utf8)!
        let actual = try main.prospect(sourceFormats: [.CSV], dataPrefix: data)
        XCTAssertEqual(1, actual.count)
        _ = actual.map { key, value in
            XCTAssertNotNil(key as? ChuckPositionsIndiv)
            XCTAssertEqual(expected, value)
        }
    }

    func testMetaOutput() throws {
        let dataStr = goodBody.data(using: .utf8)!
        let ts = Date()
        var rr = [AllocRowed.RawRow]()

        let actual: [MSourceMeta.DecodedRow] = try imp.decode(MSourceMeta.self,
                                                              dataStr,
                                                              rejectedRows: &rr,
                                                              outputSchema: .allocMetaSource,
                                                              url: URL(string: "http://blah.com"),
                                                              timestamp: ts)
        XCTAssertNotNil(actual[0]["sourceMetaID"]!)
        XCTAssertEqual(URL(string: "http://blah.com"), actual[0]["url"])
        XCTAssertEqual("chuck_positions_indiv", actual[0]["importerID"])
        let exportedAt: Date? = actual[0]["exportedAt"] as? Date
        let expectedExportedAt = df.date(from: "2023-04-23T12:52:00-0400")!
        XCTAssertEqual(expectedExportedAt, exportedAt)
        XCTAssertEqual(0, rr.count)
    }

    func testAccountOutput() throws {
        let dataStr = goodBody.data(using: .utf8)!
        var rr = [AllocRowed.RawRow]()

        let actual: [AllocRowed.DecodedRow] = try imp.decode(MAccount.self, dataStr, rejectedRows: &rr, outputSchema: .allocAccount)
        let expected: [AllocRowed.DecodedRow] = [
            ["accountID": "...234", "title": "Individual"],
        ]
        XCTAssertEqual(expected, actual)
        XCTAssertEqual(0, rr.count)
    }

    func testHoldingOutput() throws {
        let dataStr = goodBody.data(using: .utf8)!
        var rr = [AllocRowed.RawRow]()

        let actual: [AllocRowed.DecodedRow] = try imp.decode(MHolding.self, dataStr, rejectedRows: &rr, outputSchema: .allocHolding)
        let expected: [AllocRowed.DecodedRow] = [
            ["holdingAccountID": "...234", "holdingSecurityID": "SCHB", "shareBasis": 45.903940000000006, "shareCount": 500],
            ["holdingAccountID": "...234", "holdingSecurityID": "CORE", "shareBasis": 1.0, "shareCount": 650.37],
        ]
        XCTAssertEqual(expected, actual)
        XCTAssertEqual(0, rr.count)
    }

    func testSecurityOutput() throws {
        let dataStr = goodBody.data(using: .utf8)!
        let ts = Date()
        var rr = [AllocRowed.RawRow]()

        let actual: [AllocRowed.DecodedRow] = try imp.decode(MSecurity.self, dataStr, rejectedRows: &rr, outputSchema: .allocSecurity, timestamp: ts)
        let expected: [AllocRowed.DecodedRow] = [
            ["securityID": "SCHB", "sharePrice": 48.08, "updatedAt": ts],
        ]
        XCTAssertEqual(expected, actual)
        XCTAssertEqual(0, rr.count)
    }

    func testParseSourceMeta() throws {
        let str = """
        "Positions for account Individual                        ...234 as of 09:59 PM ET, 2021/09/26"

        "First block starts here...
        """

        let timestamp = Date()
        var rr = [AllocRowed.RawRow]()
        let dataStr = str.data(using: .utf8)!

        let actual: [MSourceMeta.DecodedRow] = try imp.decode(MSourceMeta.self,
                                                              dataStr,
                                                              rejectedRows: &rr,
                                                              outputSchema: .allocMetaSource,
                                                              url: URL(string: "http://blah.com"),
                                                              timestamp: timestamp)

        XCTAssertEqual(1, actual.count)
        XCTAssertNotNil(actual[0]["sourceMetaID"]!)
        XCTAssertEqual(URL(string: "http://blah.com"), actual[0]["url"])
        XCTAssertEqual("chuck_positions_indiv", actual[0]["importerID"])
        let exportedAt: Date? = actual[0]["exportedAt"] as? Date
        let expectedExportedAt = df.date(from: "2021-09-27T01:59:00+0000")!
        XCTAssertEqual(expectedExportedAt, exportedAt)
        XCTAssertEqual(0, rr.count)
    }

    func testParseAccountTitleID() throws {
        let str = "\"Positions for account Individual Something                       ...234 as of xxxxx\""
        let actual = ChuckPositions.parseAccountTitleID(ChuckPositionsIndiv.accountTitleRE, str)
        XCTAssertEqual("Individual Something", actual!.title)
        XCTAssertEqual("...234", actual!.id)
    }
}
