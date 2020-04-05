# MimeEmailParser

![MimeEmailParser Swift: Email parsing and validation](https://raw.githubusercontent.com/igorrendulic/MimeEmailParser/master/icon-72x72.png)
-----

## What is MimeEmailParser

MimeEmailParser is a Swift 5 library which may be used for `parsing and validation` of email addresses. If follows Multipurpose Internet Mail Extension (MIME), as defined in `RFC 5322` for email address parsing and `RFC 2047` ("Q"-encoded) for decoding Non-ASCII text. [List of IETF specifications](https://github.com/jstedfast/MimeKit/blob/master/RFCs.md)

Note that this is not the full implementation of MIME, but deals only with parsing of email addresses and decoding words as defined in RFC2047. 

Supported "high level formats":
```
address = mailbox / group
mailbox = name-addr / addr-spec
group = display-name ":" [group-list] ";" [CFWS]
```

## Features

- Parsing single and multiple email adresses
- Validation of email addresses
- Decoding RFC2047 words


## Installation

### Swift Package Manager

The Swift Package Manager is a tool for automating the distribution of Swift code and is integrated into the swift compiler. 

Once you have your Swift package set up, adding MimeEmailParser as a dependency is as easy as adding it to the dependencies value of your Package.swift.

```
dependencies: [
    .package(url: "https://github.com/igorrendulic/MimeEmailParser.git", .upToNextMajor(from: "1.0.0"))
]
```

### Manually

If you prefer not to use Swift Package Manager, you can integrate MimeEmailParser into your project manually as an `Embedded Framework`

- Open up Terminal, cd into your top-level project directory, and run the following command "if" your project is not initialized as a git repository:
```
$ git init
```

- Add MimeEmailParser as a git [submodule](https://git-scm.com/docs/git-submodule) by running the following command:
```
$ git submodule add https://github.com/igorrendulic/MimeEmailParser.git
```

- Open the new MimeEmailParser folder, and drag the Package.xcworkspace into the Project Navigator of your application's Xcode project.
> It should appear nested underneath your application's blue project icon. Whether it is above or below all the other Xcode groups does not matter.

- Select MimeEmailParser in the Project Navigator and verify the deployment target matches that of your application target.

- Next, select your application project in the Project Navigator (blue project icon) to navigate to the target configuration window and select the application target under the "Targets" heading in the sidebar.

- And that's it!


## Using MimeEmailParser

MimeEmailParser returns a single or array of `Address` objects:

```swift
public struct Address {
    let Name:String?
    let Address: String
}
```

### Parsing single email address

```swift
let address = try MimeEmailParser().parseSingleAddress(address: "jdeo@example.domain")
```
Some of the supported formats (for more examples check `MimeEmailParserTests.swift` source code)

```swift
let address = try MimeEmailParser().parseSingleAddress(address: "jdoe@example.domain")
let address = try MimeEmailParser().parseSingleAddress(address: "John Doe <jdoe@machine.example>")
let address = try MimeEmailParser().parseSingleAddress(address: "john.q.public@example.com")
let address = try MimeEmailParser().parseSingleAddress(address: "john.q.public@example.com")
let address = try MimeEmailParser().parseSingleAddress(address: "John !@M@! Doe <jdoe@machine.example>") // yes. it's a valid address 
```

Supports also "Q"-encoded email addresses:
```swift
// expected result: Address(Name: "Jörg Doe", Address: "joerg@example.com")
let address = try MimeEmailParser().parseSingleAddress(address: "=?iso-8859-1?q?J=F6rg_Doe?= <joerg@example.com>")

// expected result: Address(Name: "Jörg Doe", Address: "joerg@example.com")
let address = try MimeEmailParser().parseSingleAddress(address: "=?utf-8?q?J=C3=B6rg?=  =?utf-8?q?Doe?= <joerg@example.com>")
```

By RFC 5322 only utf-8 and ISO-8859-1 and ASCII is supported but MimeEmailParser doesn't acknowledge those limitations. 


### Parsing mulitple email addresses

```swift
// expected result: [Address(Name: "Mary Smith", Address: "mary@x.test"),Address(Name: nil, Address: "jdoe@example.org"),Address(Name: "Who?", Address: "<one@y.test>")]

let addresses = try MimeEmailParser().parseAddressList(addresses: "Mary Smith <mary@x.test>, jdoe@example.org, Who? <one@y.test>")

// expected results: Address(Name: "André Pirard", Address: "PIRARD@vm1.ulg.ac.be")
let addresses = try MimeEmailParser().parseAddressList(addresses: "=?ISO-8859-1?Q?Andr=E9?= Pirard <PIRARD@vm1.ulg.ac.be>")

// expected result: [Address(Name: nil, Address: "addr1@example.com"), Address(Name: nil, Address: "addr2@example.com"), Address(Name: "John", Address: "addr3@example.com")] 
let addresses = try MimeEmailParser().parseAddressList(addresses: "Group1: <addr1@example.com>;, Group 2: addr2@example.com;, John <addr3@example.com>")
```

### Email Validation

MimeEmailParser can also be used for email validation.

```swift
do {
    _ = try MimeEmailParser().parseSingleAddress(address: "John Doe@foo.bar")
} catch EmailError.noAngleAddr {
}
```

Possible email format errors:
| Error                                         |  Description                                  |
| ----------------------------------------------|-----------------------------------------------|
| noAddrSpec                                    |  No email specified                           |
| utf8Invalid                                   |  Invalid character in address                 |
| leadingDotInAtom                              |  Detected leading dot                         |
| doubleDotInAtom                               |  Detected double dots                         |
| trailingDotInAtom                             |  Detected trailing dot                        |
| unclosedQuotedString                          |  Unclosed quotes in the name                  |
| badCharacter                                  |  Bad character in address                     |
| missingAtInAddrSpace                          |  Missing @ symbol                             |
| noDomainInAddrSpec                            |  Domain not specified                         |
| invalidEmailAddress                           |  Email could not be parse (unknown)           |
| missingWordInPhrase                           |  Missing word in phrase                       |
| expectedComma                                 |  Missing comma in multiple email addresses    |
| noAngleAddr                                   |  Likely meant to be "Full Name <...>"         |
| unclosedAngleAddr                             |  Missing trailing >                           |
| commendNotStartedWithParantheses              |  Failed parsing quoted string in comment      |
| misformattedParentheticalComment              |  CFWS validation                              |

### License

Alamofire is released under the MIT license. See LICENSE for details.
