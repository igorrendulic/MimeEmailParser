//
//  MimeEmailParser.swift
//  MimeEmailParser
//
//  Created by Igor Rendulic on 4/2/20.
//
//  Copyright (c) 2020 Igor Rendulic. All rights reserved.
/*
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import Foundation

public enum EmailError: Error {
    case noAddrSpec // no email
    case utf8Invalid // invalid utf-8 address
    case leadingDotInAtom
    case doubleDotInAtom
    case trailingDotInAtom
    case unclosedQuotedString
    case badCharacter
    case missingAtInAddrSpace
    case noDomainInAddrSpec
    case commendNotStartedWithParantheses
    case misformattedParentheticalComment
    case missingWordInPhrase
    case expectedComma
    case noAngleAddr
    case unclosedAngleAddr
    case invalidEmailAddress
}

public class MimeEmailParser {
    
    public init() {}
    // MARK:  For the most part, this package follows the syntax as specified by RFC 5322 and extended by RFC 6532.
    
    // ParseList parses the given string as a list of addresses
    public func parseAddressList(addresses:String) throws -> [Address] {
        return try parseAddressList(addresses: addresses, handleGroup: true)
    }
    
    // ParseAddress parses a single RFC 5322 address, e.g. "Barry Gibbs <bg@example.com>"
    public func parseSingleAddress(address:String) throws -> Address {
        let addresses = try parseAddressList(addresses: address, handleGroup: true)
        if addresses.count > 0 {
            return addresses[0]
        }
        throw EmailError.invalidEmailAddress
    }
    
    
    fileprivate func parseAddressList(addresses: String, handleGroup: Bool) throws -> [Address] {
        let lexer = Lexer(input: addresses)
        var list:[Address] = []
        while true {
            lexer.skipSpace()
            let addrs = try parseAddress(lexer: lexer, handleGroup: true)
            list.append(contentsOf: addrs)
            
            if !skipCFWS(lexer: lexer) {
                throw EmailError.misformattedParentheticalComment
            }
            if lexer.isEmpty() {
                break
            }
            if !consume(lexer: lexer, char: ",") {
                throw EmailError.expectedComma
            }
        }
        return list
    }
    
    
    
    // MARK: private functions for parsing email address
    
    fileprivate func parseAddress(lexer:Lexer, handleGroup:Bool) throws -> [Address] {
        
        // address = mailbox / group
        // mailbox = name-addr / addr-spec
        // group = display-name ":" [group-list] ";" [CFWS]
        
        
        // addr-spec has a more restricted grammar than name-addr,
        // so try parsing it first, and fallback to name-addr.
        lexer.skipSpace()
        if lexer.isEmpty() {
            throw EmailError.noAddrSpec
        }
        do {
            let spec = try consumeAddrSpec(lexer: lexer)
            lexer.skipSpace()
            var displayName:String?
            if !lexer.isEmpty() && lexer.peek() == "(" {
                displayName = try consumeDisplayNameComment(lexer: lexer)
                displayName = displayName?.trimmingCharacters(in: .whitespaces)
            }
            let output:[Address] = [Address(Name: displayName, Address: spec)]
            return output
        } catch {
            // do nothing (address not an addr-spec)
            print("state is now \(lexer.toString())")
        }
        
        // consumePhrase
        var displayName = ""
        if lexer.peek() !=  "<" {
            displayName = try consumePhrase(lexer: lexer)
        }
//        customPrint(items: "parseAddress: displayName:", displayName)
        
        lexer.skipSpace()
        if handleGroup {
            if consume(lexer: lexer, char: ":") {
                return try consumeGroupList(lexer: lexer)
            }
        }
        // angle-addr = "<" addr-spec ">"
        if !consume(lexer: lexer, char: "<") {
            var atext:Bool = true
            for char in displayName {
                if  !isAText(char: char, dot: true, permissive: false) {
                    atext = false
                    break
                }
            }
            if atext {
                // The input is like "foo.bar"; it's possible the input
                // meant to be "foo.bar@domain", or "foo.bar <...>".
                throw EmailError.missingAtInAddrSpace
            }
            // The input is like "Full Name", which couldn't possibly be a
            // valid email address if followed by "@domain"; the input
            // likely meant to be "Full Name <...>".
            throw EmailError.noAngleAddr
        }
        let spec = try consumeAddrSpec(lexer: lexer)
        if !consume(lexer: lexer, char: ">") {
            throw EmailError.unclosedAngleAddr
        }
        var dName:String?
        if !displayName.isEmpty {
            dName = displayName.trimmingCharacters(in: .whitespaces)
        }
        return [Address(Name: dName, Address: spec)]
    }
    
    // consumeAtom parses an RFC 5322 atom at the start of address.
    // If dot is true, consumeAtom parses an RFC 5322 dot-atom instead.
    fileprivate func consumeAtom(lexer: Lexer, dot:Bool, permissive: Bool) throws -> String {
        var i = 0
        while true {
            guard let char = lexer.current() else {
                break
            }
            let size = char.utf8.count
            if size == 1 && char.unicodeScalarCodePoint() >= 128 { // 128
                throw EmailError.utf8Invalid
            }
            if lexer.size() == 0 || !isAText(char: char, dot: dot, permissive: permissive) {
                break
            }
            i += size
            lexer.advance()
        }
        if i == 0 {
            throw EmailError.noAddrSpec
        }
        
        let atom = lexer.toString()[..<i]
        let ps = lexer.toString()[i...] // remaining address
        lexer.newInput = String(ps)
        if !permissive {
            if atom.first == "." {
                throw EmailError.leadingDotInAtom
            }
            if atom.contains("..") {
                throw EmailError.doubleDotInAtom
            }
            if atom.last == "." {
                throw EmailError.trailingDotInAtom
            }
        }
        return String(atom)
    }
    
    // consumeAddrSpec parses a single RFC 5322 addr-spec at the start of address.
    fileprivate func consumeAddrSpec(lexer:Lexer) throws -> String {
        // local-part = dot-atom / quoted-string
        
        let original = lexer.toString() // if error replace lexers input with original
        
        var localPart = ""
        lexer.skipSpace()
        if lexer.isEmpty() {
            lexer.newInput = original
            throw EmailError.noAddrSpec
        }
        if lexer.peek() == "\"" {
            // quoted-string
            localPart = try consumeQuotedString(lexer: lexer)
            if localPart.isEmpty {
                lexer.newInput = original
                throw EmailError.noAddrSpec
            }
        } else {
            // dot-atom
            do {
                localPart = try consumeAtom(lexer: lexer, dot: true, permissive: false)
            } catch {
                lexer.newInput = original
                throw error
            }
        }
        if !consume(lexer: lexer, char: "@") {
            lexer.newInput = original
            throw EmailError.missingAtInAddrSpace
        }
        // domain = dot-atom / domain-literal
        lexer.skipSpace()
        if lexer.isEmpty() {
            lexer.newInput = original
            throw EmailError.noDomainInAddrSpec
        }
        do {
            let domain = try consumeAtom(lexer: lexer, dot: true, permissive: false)
            return localPart + "@" + domain
        } catch {
            lexer.newInput = original
            throw error
        }
    }
    
    fileprivate func consume(lexer:Lexer, char:Character) -> Bool {
        if lexer.isEmpty() || lexer.peek() != char {
            return false
        }
        lexer.newInput = String(lexer.toString()[1...])
        return true
    }
    
    // consumeQuotedString parses the quoted string at the start of address
    fileprivate func consumeQuotedString(lexer:Lexer) throws -> String {
        // asume first byte is "
        var escaped:Bool = false
        var qsb = Data()
        var j = 0
        while true {
            guard let char = lexer.current() else {
                break
            }
            if j == 0 {
                lexer.advance()
                j+=1
                continue // skip first
            }
            let charSize = char.utf8.count
            if charSize == 0 {
                throw EmailError.unclosedQuotedString
            } else if charSize == 1 && char.unicodeScalarCodePoint() >= 128 {
                throw EmailError.utf8Invalid
            } else if escaped {
                //  quoted-pair = ("\" (VCHAR / WSP))
                if !isVchar(char: char) && !isWSP(char: char) {
                    throw EmailError.badCharacter
                }
                qsb.append(String(char).data(using: .utf8)!)
                escaped = false
            } else if isQText(char: char) || isWSP(char: char) {
                // qtext (printable US-ASCII excluding " and \), or
                // FWS (almost; we're ignoring CRLF)
                qsb.append(String(char).data(using: .utf8)!)
            } else if char == "\"" {
                break // end of quoted string
            } else if char == "\\" {
                escaped = true
            } else {
                throw EmailError.badCharacter
            }
            j+=1
            lexer.advance()
        }
        let addr = lexer.toString()[(j+1)...]
        lexer.newInput = String(addr)
        let strQsb = String(data: qsb, encoding: .utf8)!
        return strQsb
    }
    
    fileprivate func consumeDisplayNameComment(lexer:Lexer) throws -> String {
        if !consume(lexer: lexer, char: "(") {
            throw EmailError.commendNotStartedWithParantheses
        }
        let comment = try consumeComment(lexer: lexer)
        
        // parse quoted-string within comment
        let separators = CharacterSet(charactersIn: " \t")
        var words = comment.components(separatedBy: separators)
        let wordDecoder = WordDecoder()
        for (idx, word) in words.enumerated() {
            do {
                let decoded = try wordDecoder.decodeRFC2047Word(word: word)
                // word was decoded, replace in splitted array
                words[idx] = decoded
            } catch {
                continue // word  not encoded, skip
            }
        }
        return words.joined(separator: " ")
    }
    
    fileprivate func consumeComment(lexer:Lexer) throws -> String {
        // '(' already consumed
        var depth = 1
        var comment = ""
        while true {
            if lexer.isEmpty() {
                break
            }
            if lexer.peek() == "\\" && lexer.size() > 1 {
                lexer.newInput = String(lexer.toString()[1...])
            } else if lexer.peek() == "(" {
                depth += 1
            } else if lexer.peek() == ")" {
                depth -= 1
            }
            if depth > 0 {
                let cmt = lexer.toString()[..<1]
                comment.append(contentsOf: cmt)
            }
            lexer.newInput = String(lexer.toString()[1...])
        }
        if depth !=  0 {
            // misformatted parenthetical comment
            throw EmailError.misformattedParentheticalComment
        }
        return comment
    }
    
    // consumePhrase parses the RFC 5322 phrase at the start of p.
    fileprivate func consumePhrase(lexer:Lexer) throws -> String {
        var words:[String] = []
        var isPrevEncoded:Bool = false
        while true {
            var word:String?
            lexer.skipSpace()
            if lexer.isEmpty() {
                break
            }
            var isEncoded:Bool = false
            if lexer.peek() == "\"" {
                // quoted-string
                word = try consumeQuotedString(lexer: lexer)
            } else {
                // atom
                // We actually parse dot-atom here to be more permissive
                // than what RFC 5322 specifies.
                do {
                    word = try consumeAtom(lexer: lexer, dot: true, permissive: true)
                    do {
                        word = try WordDecoder().decodeRFC2047Word(word: word!)
                    } catch WordError.notEncoded {
                        isEncoded = false
                    }
                } catch {
                    break // skip
                }
            }
            if isPrevEncoded  && isEncoded {
                words[words.count-1] += word!
            } else {
                words.append(word!)
            }
            isPrevEncoded = isEncoded
        }
        if words.count == 0 {
            throw EmailError.missingWordInPhrase
        }
        let phrase = words.joined(separator: " ")
        return phrase
    }
    
    fileprivate func consumeGroupList(lexer:Lexer) throws -> [Address] {
        var group:[Address] = []
        lexer.skipSpace()
        // handle empty group.
        if consume(lexer: lexer, char: ";") {
            _ = skipCFWS(lexer: lexer)
            return group
        }
        
        while true {
            lexer.skipSpace()
            // embedded groups not allowed.
            do {
                let addrs = try parseAddress(lexer: lexer, handleGroup: false)
                group.append(contentsOf: addrs)
            } catch {
                return []
            }
            if !skipCFWS(lexer: lexer) {
                throw EmailError.misformattedParentheticalComment
            }
            if consume(lexer: lexer, char: ";") {
                _ = skipCFWS(lexer: lexer)
                break
            }
            if !consume(lexer: lexer, char: ",") {
                throw EmailError.expectedComma
            }
        }
        return group
    }
    
    // skipCFWS skips CFWS as defined in RFC5322.
    fileprivate func skipCFWS(lexer:Lexer) -> Bool {
        lexer.skipSpace()
        
        while true {
            if !consume(lexer: lexer, char: "(") {
                break
            }
            do {
                _ = try consumeComment(lexer: lexer)
            } catch {
                return false
            }
            lexer.skipSpace()
        }
        return true
    }
    
    // isAtext reports whether r is an RFC 5322 atext character.
    // If dot is true, period is included.
    // If permissive is true, RFC 5322 3.2.3 specials is included,
    // except '<', '>', ':' and '"'.
    fileprivate func isAText(char:Character, dot:Bool, permissive:Bool) -> Bool {
        switch char {
        case ".":
            return dot
        case "(", ")", "[", "]", ";", "@", "\\", ",":
            return permissive
        // RFC 5322 3.2.3. specials
        case "<", ">", "\"", ":":
            return false
        default:
            return isVchar(char: char)
        }
    }
    
    // isQtext reports whether r is an RFC 5322 qtext character.
    fileprivate func isQText(char:Character) -> Bool {
        if char == "\\" || char == "\"" {
            return false
        }
        return isVchar(char: char)
    }
    
    // isVchar reports whether r is an RFC 5322 VCHAR character.
    // visible printing character
    fileprivate func isVchar(char:Character) -> Bool {
        return "!" <= char &&  char <= "~" || isMultibyte(char: char)
    }
    
    // isMultibyte reports whether r is a multi-byte UTF-8 character
    // as supported by RFC 6532
    fileprivate func isMultibyte(char:Character) -> Bool {
        return String(char).lengthOfBytes(using: .utf8) > 1
    }
    
    // isWSP reports whether r is a WSP (white space).
    // WSP is a space or horizontal tab (RFC 5234 Appendix B)
    fileprivate func isWSP(char:Character) -> Bool {
        return char.isWhitespace || char == "\t"
    }
}
