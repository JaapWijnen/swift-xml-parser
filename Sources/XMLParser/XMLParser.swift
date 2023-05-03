import Parsing
import CasePaths

let quotedStringParser = ParsePrint {
    "\"".utf8
    PrefixUpTo("\"".utf8).map(.string)
    "\"".utf8
}

let attributeParser = ParsePrint {
    PrefixUpTo("=".utf8).map(.string)
    "=".utf8
    quotedStringParser
}

let attributesParser = Many {
    attributeParser
} separator: {
    Whitespace(1..., .horizontal)
}.map(Conversions.TuplesToDictionary())

let tagNameParser = ParsePrint {
    From<Conversions.UTF8ViewToSubstring, Substring, Prefix<Substring>>(.substring) {
        Prefix { $0.isLetter }
    }.map(.string)
}

let tagHeadParser = ParsePrint {
    tagNameParser
    Optionally {
        Whitespace(1..., .horizontal)
        attributesParser
    }.map(Conversions.OptionalEmptyDictionary())
    Whitespace(.horizontal)
}

struct XMLParsingError: Error { }

let emptyTagParser = ParsePrint {
    "<".utf8
    Not { "/".utf8 }
    Prefix(1...) { $0 != .init(ascii: ">") }.pipe {
        tagHeadParser
        "/".utf8
    }
    ">".utf8
    Always(Array<XML.Node>())
    Always("")
}
.filter { $0.2.isEmpty }
.map(Conversions.UnpackXMLElement())
.map(.memberwise(XML.Element.init))

let commentParser = ParsePrint {
    "<!--".utf8
    PrefixUpTo("-->".utf8).map(.string).map(/XML.Node.comment)
    "-->".utf8
}

let textParser = ParsePrint(input: Substring.UTF8View.self) {
    Whitespace(.horizontal)
    Prefix(1...) {
        $0 != .init(ascii: "<") && $0 != .init(ascii: "\n")
    }
}
.map(.string).map(/XML.Node.text)

let xmlPrologParser = ParsePrint {
    "<?xml".utf8
    Whitespace(1..., .horizontal)
    attributesParser
    Whitespace(.horizontal)
    "?>".utf8
}

let openingTagParser = ParsePrint {
    "<".utf8
    Not { "/".utf8 }
    Prefix(1...) { $0 != .init(ascii: ">") }.pipe {
        tagHeadParser
        Whitespace(.horizontal)
        Not { "/".utf8 }
    }
    ">".utf8
}

let containerTagParser = { (indentation: Int?) in
    ParsePrint {
        openingTagParser
        Whitespace(.vertical).printing(indentation != nil ? "\n".utf8 : "".utf8)
        Many {
            Lazy {
                contentParser(indentation.map { $0 + 4 })
                Whitespace(.vertical).printing(indentation != nil ? "\n".utf8 : "".utf8)
            }
        } terminator: {
            Whitespace(.horizontal).printing(String(repeating: " ", count: indentation ?? 0).utf8)
            "</".utf8
        }
        Prefix { $0 != .init(ascii: ">") }.map(.string)
        ">".utf8
    }
    .filter { tagHead, _, _, closingTag in tagHead == closingTag }
    .map(Conversions.UnpackXMLElement())
    .map(.memberwise(XML.Element.init))
}

let contentParser: (Int?) -> AnyParserPrinter<Substring.UTF8View, XML.Node> = { indentation in
    ParsePrint {
        Whitespace(.horizontal).printing(String(repeating: " ", count: indentation ?? 0).utf8)
        OneOf {
            containerTagParser(indentation).map(/XML.Node.element)
            emptyTagParser.map(/XML.Node.element)
            commentParser
            textParser
        }
    }.eraseToAnyParserPrinter()
}

/// A reversible parser that takes in a string of XML and parses it into a structured ``XML`` type, or prints structured ``XML`` into an XML string.
///
/// You can create an ``XMLParser/XMLParser`` using ``init(indenting:)``
///
/// ```swift
/// let xmlParser = XMLParser(indenting: true)
/// let xmlString = "<root><value/></root>"
/// let xml: XML = try xmlParser.parse(xmlString)
/// ```
public struct XMLParser: ParserPrinter {
    let parser: AnyParserPrinter<Substring.UTF8View, XML>
    /// Creates an XMLParser with indented or `minified` printing.
    /// - Parameters:
    ///   - indenting: wether to print using indentation and newlines or not.
    public init(indenting: Bool = true) {
        self.parser = ParsePrint {
            Optionally {
                xmlPrologParser
                Whitespace(.vertical).printing(indenting ? "\n".utf8 : "".utf8)
            }.map(Conversions.OptionalEmptyDictionary())
            containerTagParser(indenting ? 0 : nil)
            End()
        }
        .map(.memberwise(XML.init(prolog:root:)))
        .eraseToAnyParserPrinter()
    }
    
    /// Prints an string representation of xml into the provided input.
    /// - Parameters:
    ///   - output: the structured XML to turn into a string
    ///   - input: the input to write the string representation to
    public func print(_ output: XML, into input: inout Substring.UTF8View) throws {
        try parser.print(output, into: &input)
    }
    
    /// Parses an xml string into a structured ``XML`` type
    /// - Parameters:
    ///   - input: the input string to parse
    /// - Returns: A structured ``XML``  type
    public func parse(_ input: inout Substring.UTF8View) throws -> XML {
        try parser.parse(&input)
    }
}
