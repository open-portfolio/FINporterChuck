//
//  ChuckDateFormatterTests.swift
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

import FINporter
@testable import FINporterChuck
import XCTest

final class ChuckDateFormatterTests: XCTestCase {
    let df = ISO8601DateFormatter()
    let tzNewYork = TimeZone(identifier: "America/New_York")!
    let tzDenver = TimeZone(identifier: "America/Denver")!

    func testBasic() throws {
        let actual = parseChuckMMDDYYYY("03/01/2021", timeZone: tzNewYork)
        let expected = df.date(from: "2021-03-01T17:00:00Z")
        XCTAssertEqual(expected, actual)
    }

    func testOverrideTimeOfDay() throws {
        let actual = parseChuckMMDDYYYY("03/01/2021", defTimeOfDay: "13:00", timeZone: tzNewYork)
        let expected = df.date(from: "2021-03-01T18:00:00Z")
        XCTAssertEqual(expected, actual)
    }

    func testOverrideTimeZone() throws {
        let actual = parseChuckMMDDYYYY("03/01/2021", timeZone: tzDenver)
        let expected = df.date(from: "2021-03-01T19:00:00Z")
        XCTAssertEqual(expected, actual)
    }

    func testOverrideBoth() throws {
        let actual = parseChuckMMDDYYYY("03/01/2021", defTimeOfDay: "13:00", timeZone: tzDenver)
        let expected = df.date(from: "2021-03-01T20:00:00Z")
        XCTAssertEqual(expected, actual)
    }

    func testBankInterestCompound() throws {
        let dateStr = "08/16/2021 as of 08/15/2021"
        let actual = parseChuckMMDDYYYY(dateStr, timeZone: tzNewYork)
        let expected = df.date(from: "2021-08-16T16:00:00Z")
        XCTAssertEqual(expected, actual)
    }

    func testBasic2() throws {
        let actual = parseChuckYYYYMMDD("2021/03/01", timeZone: tzNewYork)
        let expected = df.date(from: "2021-03-01T17:00:00Z")
        XCTAssertEqual(expected, actual)
    }

    func testOverrideTimeOfDay2() throws {
        let actual = parseChuckYYYYMMDD("2021/03/01", defTimeOfDay: "13:00", timeZone: tzNewYork)
        let expected = df.date(from: "2021-03-01T18:00:00Z")
        XCTAssertEqual(expected, actual)
    }

    func testOverrideTimeZone2() throws {
        let actual = parseChuckYYYYMMDD("2021/03/01", timeZone: tzDenver)
        let expected = df.date(from: "2021-03-01T19:00:00Z")
        XCTAssertEqual(expected, actual)
    }

    func testOverrideBoth2() throws {
        let actual = parseChuckYYYYMMDD("2021/03/01", defTimeOfDay: "13:00", timeZone: tzDenver)
        let expected = df.date(from: "2021-03-01T20:00:00Z")
        XCTAssertEqual(expected, actual)
    }

    func testBankInterestCompound2() throws {
        let dateStr = "2021/08/16 as of 2021/08/15"
        let actual = parseChuckYYYYMMDD(dateStr, timeZone: tzNewYork)
        let expected = df.date(from: "2021-08-16T16:00:00Z")
        XCTAssertEqual(expected, actual)
    }
}
