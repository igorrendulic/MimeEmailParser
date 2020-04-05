# MimeEmailParser

## What is MimeEmailParser

MimeEmailParser is a Swift 5 library which may be used for `parsing and validation` of email addresses. If follows Multipurpose Internet Mail Extension (MIME), as defined in `RFC 5322` for email address parsing and `RFC 2047` for decoding Non-ASCII text. [List of IETF specifications](https://github.com/jstedfast/MimeKit/blob/master/RFCs.md)

Note that this is not the full implementation of MIME, but deals only with parsing of email addresses and decoding words as defined in RFC2047. 

## Features

- Parsing single and multiple email adresses
- Validation of email addresses
- Decoding RFC2047 words


## Using MimeEmailParser

### Parsing single email address



### Parsing mulitple email addresses

### Email Validation

## Installation

### Swift Package Manager

The Swift Package Manager is a tool for automating the distribution of Swift code and is integrated into the swift compiler. It is in early development, but Alamofire does support its use on supported platforms.

Once you have your Swift package set up, adding MimeEmailParser as a dependency is as easy as adding it to the dependencies value of your Package.swift.

```
dependencies: [
    .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "1.0.0"))
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
$ git submodule add https://github.com/Alamofire/Alamofire.git
```



