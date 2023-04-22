# FINporterChuck

Tool for detecting and transforming exports from Schwab brokerage.

Available as a component of both a `finport` command line executable and as an open source Swift library to be incorporated in other apps.

_FINporterChuck_ is part of the [OpenAlloc](https://github.com/openalloc) family of open source Swift software tools.

Used by investing apps like [FlowAllocator](https://open-portfolio.github.io/allocator) and [FlowWorth](https://open-portfolio.github.io/worth).

## Disclaimer

The developers of this project (presently OpenAlloc LLC) are not financial advisers and do not offer tax or investing advice. 

Where explicit support is provided for the transformation of data format associated with a service (brokerage, etc.), it is not a recommendation or endorsement of that service.

Software will have defects. Input data can have errors or become outdated. Carefully examine the output from _FINporter_ for accuracy to ensure it is consistent with your investment goals.

For additional disclaiming, read the LICENSE, which is Apache 2.0.

## Chuck (Schwab) Positions

There are actually two importers to handle Schwab positions. One for 'All' accounts, and a second for 'Individual' accounts. The files are named differently:

* All-Accounts-Positions-YYYY-MM-DD-000000.CSV
* Individual-Positions-YYYY-MM-DD-000000.CSV

Using the _finport_ command line tool to transform either export requires four separate commands, as there are four outputs: accounts, account holdings, securities, and 'source meta':

```bash
$ finport transform SOMETHING-Positions-2021-06-30-012345.CSV --output-schema openalloc/account
$ finport transform SOMETHING-Positions-2021-06-30-012345.CSV --output-schema openalloc/holding
$ finport transform SOMETHING-Positions-2021-06-30-012345.CSV --output-schema openalloc/security
$ finport transform SOMETHING-Positions-2021-06-30-012345.CSV --output-schema openalloc/meta/source
```

Each command above will produce comma-separated value data in the following schemas, respectively.

NOTE: "Cash & Cash Investments" holdings will be assigned a SecurityID of "CORE".

The 'source meta' can extract the export date from the content, if present, as well as other details.

Output schemas: 
* [openalloc/account](https://github.com/openalloc/AllocData#maccount)
* [openalloc/holding](https://github.com/openalloc/AllocData#mholding)
* [openalloc/security](https://github.com/openalloc/AllocData#msecurity)
* [openalloc/meta/source](https://github.com/openalloc/AllocData#msourcemeta)

## Chuck (Schwab) Transaction History

To transform the "XXXX1234_Transactions_YYYYMMDD-HHMMSS.CSV" export, which contains a record of recent sales, purchases, and other transactions:

```bash
$ finport transform XXXX1234_Transactions_YYYYMMDD-HHMMSS.CSV
```

The command above will produce comma-separated value data in the following schema.

Output schema:  [openalloc/transaction](https://github.com/openalloc/AllocData#mtransaction)

NOTE 1: Schwab's transaction export does not contain realized gains and losses of sales, and so they are not in the imported transaction.

NOTE 2: Security transfers may only specify shares transferred, with no cash valuation specified.

## Chuck (Schwab) Transaction Sales **BETA**

To transform the "XXXX1234_GainLoss_Realized_YYYYMMDD-HHMMSS.CSV" export, available in the 'Closed Positions' view of taxable accounts:

```bash
$ finport transform XXXX1234_GainLoss_Realized_YYYYMMDD-HHMMSS.CSV
```

The command above will produce comma-separated value data in the following schema.

Output schema: 
* [openalloc/transaction](https://github.com/openalloc/AllocData#mtransaction)

## See Also

This app is a member of the _Open Portfolio Project_.

* [_Open Portfolio_](https://open-portfolio.github.io/) - _Open Portfolio_ product website
* [_Open Portfolio_ Project](https://github.com/open-portfolio/) - Github site for the development project, including full source code
## License

Copyright 2021, 2022 OpenAlloc LLC

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

## Contributing

Contributions are welcome. You are encouraged to submit pull requests to fix bugs, improve documentation, or offer new features. 

The pull request need not be a production-ready feature or fix. It can be a draft of proposed changes, or simply a test to show that expected behavior is buggy. Discussion on the pull request can proceed from there.

Contributions should ultimately have adequate test coverage and command-line support. See tests for current importers to see what coverage is expected.






