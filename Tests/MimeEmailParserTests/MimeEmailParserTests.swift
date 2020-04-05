import XCTest
@testable import MimeEmailParser

final class MimeEmailParserTests: XCTestCase {
    //    func testExample() {
    //        // This is an example of a functional test case.
    //        // Use XCTAssert and related functions to verify your tests produce the correct
    //        // results.
    //        XCTAssertEqual(MimeEmailParser().text, "Hello, World!")
    //    }
    
    func testRFC2047Encoding() throws {
        let testCases:KeyValuePairs = ["Café":"=?utf-8?b?Q2Fmw6k=?=",
                                       "La Seleção": "=?utf-8?q?La_Sele=C3=A7=C3=A3o?=",
                                       "François-Jérôme":"=?utf-8?q?Fran=C3=A7ois-J=C3=A9r=C3=B4me?=",
                                       "This is a horsey: 🐎":"=?UTF-8?B?VGhpcyBpcyBhIGhvcnNleTog8J+Qjg==?=",
                                       "¡Hola, señor!":"=?UTF-8?Q?=C2=A1Hola,_se=C3=B1or!?=",
                                       "ascii":"=?UTF-8?q?ascii?=",
                                       "André":"=?utf-8?B?QW5kcsOp?=",
                                       "Raphaël Dupont":"=?ISO-8859-1?Q?Rapha=EBl_Dupont?=",
                                       "\"Antonio José\" <jose@example.org>":"=?utf-8?b?IkFudG9uaW8gSm9zw6kiIDxqb3NlQGV4YW1wbGUub3JnPg==?=",
                                       "":"=?UTF-8?Q??=",
                                       "{#Dèé£åý M$áí.çøm}":"=?UTF-8?b?eyNEw6jDqcKjw6XDvSBNJMOhw60uw6fDuG19?=",
                                       "fõö":"=?ISO-8859-15?Q?f=F5=F6?=",
                                       "bàr":"=?windows-1252?Q?b=E0r?="]
        
        let rfc2047 = WordDecoder()
        for (expected, encoded) in testCases {
            let decoded = try rfc2047.decodeRFC2047Word(word: encoded)
            print("Decoded: \(decoded)")
            XCTAssertEqual(expected, decoded)
        }
    }
    
    func testRFC2057Invalid() throws {
        let invalidTestCases:[String] = ["=?UTF-8?Q?A=B?=","=?UTF-8?Q?=A?=", "=????="]
        
        let rfc2047 = WordDecoder()
        for str in invalidTestCases {
            do {
                _ = try rfc2047.decodeRFC2047Word(word: str)
                XCTFail("this string  should have failed \(str)")
            } catch  {
                // ok
                print("failed")
            }
        }
    }
    
    func testParseadressListEmptyGroup() throws {
        let test = "empty group: ;"
        let addresses = try MimeEmailParser().parseAddressList(addresses: test)
        XCTAssertEqual(0, addresses.count)
    }
    
    func testParseAddressList() throws {
        
        let tests:[String:Address] = ["Igor <igor@mail.io>":Address(Name: "Igor", Address: "igor@mail.io"),
                                      "jdoe@machine.example":Address(Name: nil, Address: "jdoe@machine.example"),
                                      // RFC 5322, Appendix A.1.1
            "John Doe <jdoe@machine.example>":Address(Name: "John Doe", Address: "jdoe@machine.example"),
            // RFC 5322, Appendix A.1.2
            "\"Joe Q. Public\" <john.q.public@example.com>":Address(Name: "Joe Q. Public", Address: "john.q.public@example.com"),
            "\"John (middle) Doe\" <jdoe@machine.example>": Address(Name: "John (middle) Doe", Address: "jdoe@machine.example"),
            "John (middle) Doe <jdoe@machine.example>":Address(Name: "John (middle) Doe", Address: "jdoe@machine.example"),
            "John !@M@! Doe <jdoe@machine.example>": Address(Name: "John !@M@! Doe", Address: "jdoe@machine.example"),
            "\"John <middle> Doe\" <jdoe@machine.example>": Address(Name: "John <middle> Doe", Address: "jdoe@machine.example"),
            // RFC 5322, Appendix A.6.1
            "Joe Q. Public <john.q.public@example.com>":Address(Name: "Joe Q. Public", Address: "john.q.public@example.com"),
            // RFC 5322, Appendix A.1.3
            "group1: groupaddr1@example.com;":Address(Name: nil, Address: "groupaddr1@example.com")
        ]
        
        for (test,addr) in tests {
            let addresses = try MimeEmailParser().parseAddressList(addresses: test)
            customPrint(items: addresses[0])
            XCTAssertEqual(addr.Name, addresses[0].Name)
            XCTAssertEqual(addr.Address, addresses[0].Address)
        }
    }
    
    func testParseMultipleAddressList() throws {
        let test = "Mary Smith <mary@x.test>, jdoe@example.org, Who? <one@y.test>"
        let addresses = try MimeEmailParser().parseAddressList(addresses: test)
        XCTAssertEqual("Mary Smith", addresses[0].Name)
        XCTAssertEqual("mary@x.test", addresses[0].Address)
        XCTAssertEqual(nil, addresses[1].Name)
        XCTAssertEqual("jdoe@example.org", addresses[1].Address)
        XCTAssertEqual("Who?", addresses[2].Name)
        XCTAssertEqual("one@y.test", addresses[2].Address)
        
        let test2 = #"<boss@nil.test>, "Giant; \"Big\" Box" <sysservices@example.net>"#
        let addresses2 = try MimeEmailParser().parseAddressList(addresses: test2)
        XCTAssertEqual("boss@nil.test", addresses2[0].Address)
        XCTAssertEqual(nil, addresses2[0].Name)
        XCTAssertEqual("Giant; \"Big\" Box", addresses2[1].Name)
        XCTAssertEqual("sysservices@example.net", addresses2[1].Address)
        
        let testAddresses:[String:[Address]] = [
            "A Group:Ed Jones <c@a.test>,joe@where.test,John <jdoe@one.test>;":[Address(Name: "Ed Jones", Address: "c@a.test"),Address(Name: nil, Address: "joe@where.test"),Address(Name: "John", Address: "jdoe@one.test")]
        ]
        let addresses3 = try MimeEmailParser().parseAddressList(addresses: testAddresses.first!.key)
        try validateCase(parsedAddresses: addresses3, expectedAddresses: testAddresses.first!.value)
        
        let testAddresses4:[String:[Address]] = [
            "Group1: <addr1@example.com>;, Group 2: addr2@example.com;, John <addr3@example.com>":[Address(Name: nil, Address: "addr1@example.com"), Address(Name: nil, Address: "addr2@example.com"), Address(Name: "John", Address: "addr3@example.com")]
        ]
        let addresses4 = try MimeEmailParser().parseAddressList(addresses: testAddresses4.first!.key)
        try validateCase(parsedAddresses: addresses4, expectedAddresses: testAddresses4.first!.value)
    }
    
    func testEmailValidation() throws {
        do {
            _ = try MimeEmailParser().parseSingleAddress(address: "John Doe@foo.bar")
        } catch EmailError.noAngleAddr {
        }
    }
    
    func testRFC2047EncodedAddresses() throws {
        let tests:[String:Address] = [
            // RFC 2047 "Q"-encoded ISO-8859-1 address.
            "=?iso-8859-1?q?J=F6rg_Doe?= <joerg@example.com>":Address(Name: "Jörg Doe", Address: "joerg@example.com"),
            // RFC 2047 "Q"-encoded US-ASCII address.
            "=?us-ascii?q?J=6Frg_Doe?= <joerg@example.com>":Address(Name: "Jorg Doe", Address: "joerg@example.com"),
            // RFC 2047 "Q"-encoded UTF-8 address.
            "=?utf-8?q?J=C3=B6rg_Doe?= <joerg@example.com>":Address(Name: "Jörg Doe", Address: "joerg@example.com"),
            // RFC 2047 "Q"-encoded UTF-8 address with multiple encoded-words.
            "=?utf-8?q?J=C3=B6rg?=  =?utf-8?q?Doe?= <joerg@example.com>":Address(Name: "Jörg Doe", Address: "joerg@example.com"),
            // RFC 2047, Section 8.
            "=?ISO-8859-1?Q?Andr=E9?= Pirard <PIRARD@vm1.ulg.ac.be>":Address(Name: "André Pirard", Address: "PIRARD@vm1.ulg.ac.be"),
            // Custom example of RFC 2047 "B"-encoded ISO-8859-1 address.
            "=?ISO-8859-1?B?SvZyZw==?= <joerg@example.com>":Address(Name: "Jörg", Address: "joerg@example.com"),
            // // Custom example of RFC 2047 "B"-encoded UTF-8 addres
            "=?UTF-8?B?SsO2cmc=?= <joerg@example.com>": Address(Name: "Jörg", Address: "joerg@example.com"),
            // Custom example with "." in name
            "Asem H. <noreply@example.com>": Address(Name: "Asem H.", Address: "noreply@example.com"),
            // RFC 6532 3.2.3, qtext /= UTF8-non-ascii
            "\"Gø Pher\" <gopher@example.com>": Address(Name: "Gø Pher", Address: "gopher@example.com"),
            // RFC 6532 3.2, atext /= UTF8-non-ascii
            "µ <micro@example.com>": Address(Name: "µ", Address: "micro@example.com"),
            
            // TODO:🇸🇮 support for direct utf-8 characters in local address part and domain parts
            // RFC 6532 3.2.2, local address parts allow UTF-8
            //            "Micro <µ@example.com>": Address(Name: "Micro", Address: "µ@example.com")
            // RFC 6532 3.2.4, domains parts allow UTF-8
            //            "Micro <micro@µ.example.com>":Address(Name: "Micro", Address: "micro@µ.example.com"),
            
            "\"\" <emptystring@example.com>": Address(Name: nil, Address: "emptystring@example.com"),
            // CFWS
            "<cfws@example.com> (CFWS (cfws))  (another comment)": Address(Name: nil, Address: "cfws@example.com"),
            // Comment as display name
            "john@example.com (John Doe)": Address(Name: "John Doe", Address: "john@example.com"),
            // Comment and display name
            "John Doe <john@example.com> (Joey)": Address(Name: "John Doe", Address: "john@example.com"),
            // Comment as display name, no space
            "john@example.com(John Doe)": Address(Name: "John Doe", Address: "john@example.com"),
            // Comment as display name, Q-encoded
            "asjo@example.com (Adam =?utf-8?Q?Sj=C3=B8gren?=)": Address(Name: "Adam Sjøgren", Address: "asjo@example.com"),
            // Comment as display name, Q-encoded and tab-separated
            "asjo@example.com (Adam     =?utf-8?Q?Sj=C3=B8gren?=)": Address(Name: "Adam     Sjøgren", Address: "asjo@example.com"),
            // Nested comment as display name, Q-encoded
            "asjo@example.com (Adam =?utf-8?Q?Sj=C3=B8gren?= (Debian))": Address(Name: "Adam Sjøgren (Debian)", Address: "asjo@example.com")
        ]
        for test in tests {
            let result = try MimeEmailParser().parseAddressList(addresses: test.key)
            XCTAssertEqual(test.value.Name, result[0].Name)
            XCTAssertEqual(test.value.Address, result[0].Address)
        }
    }
    
    func testFailedAddresses() throws {
        let tests = ["John Doe", "a@gmail.com b@gmail.com", "<jdoe#machine.example>", "John <middle> Doe <jdoe@machine.example>", "cfws@example.com (\",\"misformatted parenthetical comment\"", "john.doe", "john.doe@", "John Doe@foo.bar"]
        for test in tests {
            do {
                _ = try MimeEmailParser().parseAddressList(addresses: test)
                XCTFail()
            } catch {
                // ok
            }
        }
    }
    
    func validateCase(parsedAddresses:[Address], expectedAddresses:[Address]) throws {
        for (idx,addr) in parsedAddresses.enumerated() {
            XCTAssertEqual(expectedAddresses[idx].Name, addr.Name)
            XCTAssertEqual(expectedAddresses[idx].Address, addr.Address)
        }
    }
    
    
    func testParseSingleAddress() throws {
        let address = try MimeEmailParser().parseSingleAddress(address: "Igor Rendulić <igor@igor.com>")
        XCTAssertEqual("Igor Rendulić", address.Name)
        XCTAssertEqual("igor@igor.com", address.Address)
    }
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        let rfc2047 = WordDecoder()
        self.measure {
            do {
                for _ in 1...1000 {
                    _ = try rfc2047.decodeRFC2047Word(word: "=?utf-8?q?=C2=A1Hola,_se=C3=B1or!?=")
                }
            } catch {
                print("failed")
            }
            // Put the code you want to measure the time of here.
        }
    }
    
    static var allTests = [
        ("testRFC2047Encoding", testRFC2047Encoding),
        ("testRFC2057Invalid", testRFC2057Invalid),
        ("testParseadressListEmptyGroup", testParseadressListEmptyGroup),
        ("testParseAddressList", testParseAddressList),
        ("testParseMultipleAddressList", testParseMultipleAddressList),
        ("testRFC2047EncodedAddresses", testRFC2047EncodedAddresses),
        ("testFailedAddresses", testFailedAddresses),
        ("parseSingleAddress", testParseSingleAddress),
        ("testPerformanceExample", testPerformanceExample)
    ]
}
