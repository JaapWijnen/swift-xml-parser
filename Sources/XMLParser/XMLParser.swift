import Parsing

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
    From<Conversions.UTF8ViewToSubstring, Prefix<Substring>>(.substring) {
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
}.map(Conversions.TagHeadToXML())

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

let commentParser = ParsePrint {
    "<!--".utf8
    PrefixUpTo("-->".utf8).map(.string).map(Conversions.XMLComment())
    "-->".utf8
}

let textParser = ParsePrint {
    Whitespace(.horizontal)
    Prefix(1...) {
        $0 != .init(ascii: "<") && $0 != .init(ascii: "\n")
    }
}.map(.string).map(Conversions.XMLText())

let xmlDoctypeParser = ParsePrint {
    "<?xml".utf8
    Whitespace(1..., .horizontal)
    attributesParser
    Whitespace(.horizontal)
    "?>".utf8
}.map(Conversions.XMLDoctype())

public let xmlParser: (Bool) -> AnyParserPrinter<Substring.UTF8View, [XML]> = { (indenting: Bool) in
    ParsePrint {
        Optionally {
            xmlDoctypeParser
            Whitespace(.vertical).printing(indenting ? "\n".utf8 : "".utf8)
        }
        containerTagParser(indenting ? 0 : nil)
        End()
    }.map(Conversions.XMLRoot())
    .eraseToAnyParserPrinter()
}

let contentParser: (Int?) -> AnyParserPrinter<Substring.UTF8View, XML> = { indentation in
    OneOf {
        containerTagParser(indentation)
        ParsePrint {
            Whitespace(.horizontal).printing(String(repeating: " ", count: indentation ?? 0).utf8)
            emptyTagParser
            Whitespace(.horizontal)
        }
        commentParser
        textParser
    }.eraseToAnyParserPrinter()
}

let containerTagParser = { (indentation: Int?) in
    ParsePrint {
        Whitespace(.horizontal).printing(String(repeating: " ", count: indentation ?? 0).utf8)
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
    .filter { tagHead, _, closingTag in tagHead.0 == closingTag }
    .map(Conversions.XMLElement())
}
