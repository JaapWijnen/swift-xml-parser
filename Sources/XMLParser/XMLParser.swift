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

let contentParser: AnyParserPrinter<Substring.UTF8View, XML> = OneOf {
    containerTagParser
    emptyTagParser
    commentParser
    textParser
}.eraseToAnyParserPrinter()

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

let containerTagParser = ParsePrint {
    openingTagParser
    Whitespace()
    Many {
        Lazy {
            contentParser
            Whitespace()
        }
    } terminator: {
        "</".utf8
    }
    Prefix { $0 != .init(ascii: ">") }.map(.string)
    ">".utf8
}
    .filter { tagHead, _, closingTag in tagHead.0 == closingTag }
    .map(Conversions.XMLElement())

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

let xmlParser = ParsePrint {
    Optionally {
        xmlDoctypeParser
        Whitespace()
    }
    containerTagParser
    End()
}.map(
    .convert(
        apply: { doctype, root in
            if let doctype {
                return [doctype, root]
            } else {
                return [root]
            }
        },
        unapply: { xml in
            guard xml.count > 0, xml.count <= 2 else  {
                return nil
            }
            
            let doctype: XML? = xml.count == 2 ? xml[0] : nil
            let root: XML = xml[xml.count-1]
            
            if let doctype {
                switch doctype {
                case .doctype:
                    break
                default:
                    return nil
                }
            }
            
            switch root {
            case .element:
                break
            default:
                return nil
            }
            
            return (doctype, root)
        }
    )
)

let indentedContentParser: (Int) -> AnyParserPrinter<Substring.UTF8View, XML> = { indentation in
    OneOf {
        indentedContainerTagParser(indentation)
        ParsePrint {
            Whitespace(.horizontal).printing(String(repeating: " ", count: indentation).utf8)
            emptyTagParser
            Whitespace(.horizontal)
        }
        commentParser
        textParser
    }.eraseToAnyParserPrinter()
}

let indentedContainerTagParser = { (indentation: Int) in
    ParsePrint {
        Whitespace(.horizontal).printing(String(repeating: " ", count: indentation).utf8)
        openingTagParser
        Whitespace(.vertical).printing("\n".utf8)
        Many {
            Lazy {
                indentedContentParser(indentation + 4)
                Whitespace(.vertical).printing("\n".utf8)
            }
        } terminator: {
            Whitespace(.horizontal).printing(String(repeating: " ", count: indentation).utf8)
            "</".utf8
        }
        Prefix { $0 != .init(ascii: ">") }.map(.string)
        ">".utf8
    }
    .filter { tagHead, _, closingTag in tagHead.0 == closingTag }
    .map(Conversions.XMLElement())
}

let indentedXMLParser = ParsePrint {
    Optionally {
        xmlDoctypeParser
        Whitespace(.vertical).printing("\n".utf8)
    }
    indentedContainerTagParser(0)
    End()
}.map(Conversions.XMLRoot())
