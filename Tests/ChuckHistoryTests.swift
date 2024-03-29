//
//  ChuckHistoryTests.swift
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
import SwiftCSV

final class ChuckHistoryTests: XCTestCase {
    var imp: ChuckHistory!
    let df = ISO8601DateFormatter()
    var rr: [AllocRowed.RawRow]!
    let tzNewYork = TimeZone(identifier: "America/New_York")!

    let goodHeader = """
    "Transactions  for account ...234 as of 09/26/2021 22:00:26 AM ET"
    "Date","Action","Symbol","Description","Quantity","Price","Fees & Comm","Amount"
    """

    let goodBody = """
    "Transactions  for account ...234 as of 09/27/2021 22:00:26 AM ET"
    "Date","Action","Symbol","Description","Quantity","Price","Fees & Comm","Amount"
    "08/03/2021","Promotional Award","","PROMOTIONAL AWARD","","","","$100.00"
    "07/02/2021","Buy","SCHB","SCHWAB US BROAD MARKET ETF","961","$105.0736","","-$100975.73"
    "06/16/2021","Security Transfer","NO NUMBER","TOA ACAT 0001","","","","$101000.00"
    Transactions Total,"","","","","","",$524.82,

    "Transactions  for account ...678 as of 09/27/2021 22:00:26 AM ET"
    "Date","Action","Symbol","Description","Quantity","Price","Fees & Comm","Amount"
    "09/27/2021","Sell","VOO","VANGUARD S&P 500","10","$137.1222","","$1370.12"
    "06/16/2021 as of 07/15/2021","Bank Interest","","BANK INT 061621-071521 SCHWAB BANK","","","","$0.55"
    Transactions Total,"","","","","","",$524.82,
    """

    override func setUpWithError() throws {
        imp = ChuckHistory()
        rr = []
    }

    func testSourceFormats() {
        let expected = Set([AllocFormat.CSV])
        let actual = Set(imp.sourceFormats)
        XCTAssertEqual(expected, actual)
    }

    func testTargetSchema() {
        let expected: [AllocSchema] = [.allocTransaction]
        let actual = imp.outputSchemas
        XCTAssertEqual(expected, actual)
    }

    func testDetectFailsDueToHeaderMismatch() throws {
        let badHeader = goodHeader.replacingOccurrences(of: "Symbol", with: "Symbal")
        let expected: FINporter.DetectResult = [:]
        let actual = try imp.detect(dataPrefix: badHeader.data(using: .utf8)!)
        XCTAssertEqual(expected, actual)
    }

    func testDetectSucceeds() throws {
        let expected: FINporter.DetectResult = [.allocTransaction: [.CSV]]
        let actual = try imp.detect(dataPrefix: goodHeader.data(using: .utf8)!)
        XCTAssertEqual(expected, actual)
    }

    func testDetectViaMain() throws {
        let expected: FINporter.DetectResult = [.allocTransaction: [.CSV]]
        let main = FINprospector([ChuckHistory()])
        let data = goodHeader.data(using: .utf8)!
        let actual = try main.prospect(sourceFormats: [.CSV], dataPrefix: data)
        XCTAssertEqual(1, actual.count)
        _ = actual.map { key, value in
            XCTAssertNotNil(key as? ChuckHistory)
            XCTAssertEqual(expected, value)
        }
    }

    func testAccountBlockRE() throws {
        var str = goodBody
        var count = 0
        while let range = str.range(of: ChuckHistory.accountBlockRE, options: .regularExpression) {
            str.removeSubrange(range)
            count += 1
        }
        XCTAssertEqual(2, count)
    }

    func testRows() throws {
        let dataStr = goodBody.data(using: .utf8)!

        let timestamp1 = df.date(from: "2021-07-02T16:00:00Z")!
        let timestamp2 = df.date(from: "2021-09-27T16:00:00Z")!
        let timestamp3 = df.date(from: "2021-08-03T16:00:00Z")!
        let timestamp4 = df.date(from: "2021-06-16T16:00:00Z")!

        let actual: [AllocRowed.DecodedRow] = try imp.decode(MTransaction.self,
                                                             dataStr,
                                                             rejectedRows: &rr,
                                                             outputSchema: .allocTransaction,
                                                             timeZone: tzNewYork)

        let expected: [AllocRowed.DecodedRow] = [
            ["txnAction": MTransaction.Action.miscflow, "txnTransactedAt": timestamp3, "txnAccountID": "...234", "txnShareCount": 100.0, "txnSharePrice": 1.0],
            ["txnAction": MTransaction.Action.buysell, "txnTransactedAt": timestamp1, "txnAccountID": "...234", "txnShareCount": 961.0, "txnSharePrice": 105.0736, "txnSecurityID": "SCHB"],
            ["txnAction": MTransaction.Action.transfer, "txnTransactedAt": timestamp4, "txnAccountID": "...234", "txnShareCount": 101_000.0, "txnSharePrice": 1.0],
            ["txnAction": MTransaction.Action.buysell, "txnTransactedAt": timestamp2, "txnAccountID": "...678", "txnShareCount": -10.0, "txnSharePrice": 137.1222, "txnSecurityID": "VOO"],
            ["txnAction": MTransaction.Action.income, "txnTransactedAt": timestamp4, "txnAccountID": "...678", "txnShareCount": 0.55, "txnSharePrice": 1.0],
        ]
        XCTAssertEqual(expected, actual)
        XCTAssertEqual(0, rr.count)
    }

    func testParseAccountTitleID() throws {
        let str = "\"Transactions  for account ...234 as of 09/26/2021 22:00:26 ET\""
        let actual = ChuckHistory.parseAccountID(str)
        XCTAssertEqual("...234", actual)
    }
}
