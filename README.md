# MimeEmailParser
=====

## What is MimeEmailParser

MimeEmailParser is a Swift 5 library which may be used for `parsing and validation` of email addresses. If follows Multipurpose Internet Mail Extension (MIME), as defined in `RFC 5322` for email address parsing and `RFC 2047` for decoding Non-ASCII text. [List of IETF specifications](https://github.com/jstedfast/MimeKit/blob/master/RFCs.md)

Note that this is not the full implementation of MIME, but deals only with parsing of email addresses and decoding words as defined in RFC2047. 

## Features
-----------------------

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

### Parsing single email address



### Parsing mulitple email addresses

### Email Validation
