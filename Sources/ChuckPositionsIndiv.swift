//
//  ChuckPositionsIndiv.swift
//
//
//  Input: for use with Individual-Positions-2021-09-26-000000.CSV from Schwab Brokerage Services
//
//  Output: supports openalloc/holding, /security, /account, and /meta schemas
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

import Foundation

import SwiftCSV

import AllocData
import FINporter

public class ChuckPositionsIndiv: FINporter {
    override public var name: String { "Chuck Positions (Individual)" }
    override public var id: String { "chuck_positions_indiv" }
    override public var description: String { "Detect and decode 'individual' position export files from Schwab." }
    override public var sourceFormats: [AllocFormat] { [.CSV] }
    override public var outputSchemas: [AllocSchema] { [.allocMetaSource, .allocAccount, .allocHolding, .allocSecurity] }

    private let trimFromTicker = CharacterSet(charactersIn: "*")

    internal static let headerRE = #"""
    "Positions for account Individual .+
    "",.+
    "Symbol","Description","Quantity","Price","Price Change %","Price Change \$","Market Value","Day Change %","Day Change \$","Cost Basis",.+
    """#

    internal static let csvRE = #"""
    "Symbol","Description",.+
    (?:.+(\n|\Z))+
    """#

    internal static let accountTitleRE = #""Positions for account (.+?)\s+([A-Z0-9-_.]+) as of .+""# // lazy greedy non-space

    override public func detect(dataPrefix: Data) throws -> DetectResult {
        guard let str = FINporter.normalizeDecode(dataPrefix),
              str.range(of: ChuckPositionsIndiv.headerRE,
                        options: .regularExpression) != nil
        else {
            return [:]
        }

        return outputSchemas.reduce(into: [:]) { map, schema in
            map[schema, default: []].append(.CSV)
        }
    }

    override open func decode<T: AllocRowed>(_: T.Type,
                                             _ data: Data,
                                             rejectedRows: inout [T.RawRow],
                                             inputFormat _: AllocFormat? = nil,
                                             outputSchema: AllocSchema? = nil,
                                             url: URL? = nil,
                                             defTimeOfDay _: String? = nil,
                                             timeZone _: TimeZone = TimeZone.current,
                                             timestamp: Date? = nil) throws -> [T.DecodedRow]
    {
        guard let str = FINporter.normalizeDecode(data) else {
            throw FINporterError.decodingError("unable to parse data")
        }

        guard let outputSchema_ = outputSchema else {
            throw FINporterError.needExplicitOutputSchema(outputSchemas)
        }

        if outputSchema_ == .allocMetaSource {
            let item = ChuckPositions.meta(id, str, url)
            return [item]
        }

        return try ChuckPositions.parseBlock(block: str,
                                             outputSchema: outputSchema_,
                                             rejectedRows: &rejectedRows,
                                             timestamp: timestamp,
                                             accountTitleRE: ChuckPositionsIndiv.accountTitleRE,
                                             csvRE: ChuckPositionsIndiv.csvRE)
    }
}
