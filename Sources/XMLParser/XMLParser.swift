import Parsing

// MARK: - XML Type

public enum XML {
    public typealias Parameters = [String: String]
    
    case doctype(Parameters)
    indirect case element(String, Parameters, [XML])
    case text(String)
    case comment(String)
}

extension XML: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .doctype(parameters):
            return ".doctype(\(parameters))"
        case let .element(type, parameters, content):
            return ".element(\(type), \(parameters), [\(content)])"
        case let .text(string):
            return string
        case let .comment(comment):
            return "<!--\(comment)-->"
        }
    }
}

extension XML: Equatable {
    public static func == (lhs: XML, rhs: XML) -> Bool {
        switch (lhs, rhs) {
        case
            let (.doctype(lhsAttributes), .doctype(rhsAttributes)):
            return lhsAttributes == rhsAttributes
        case
            let (.comment(lhs), .comment(rhs)),
            let (.text(lhs), .text(rhs)):
            return lhs == rhs
        case let (
            .element(lhsTag, lhsParameters, lhsChildren),
            .element(rhsTag, rhsParameters, rhsChildren)):
            return lhsTag == rhsTag
                && lhsParameters == rhsParameters
                && lhsChildren == rhsChildren
        default:
            return false
        }
    }
}

// MARK: - Parser

public typealias Input = Substring.UTF8View

public let tag = "<".utf8
    .take(Prefix { $0 != .init(ascii: ">") })
    .skip(">".utf8)

public let stringLiteral = Skip("\"".utf8)
    .take(Prefix { $0 != .init(ascii: "\"") })
    .skip("\"".utf8)
    .map { String(decoding: $0, as: UTF8.self) }

public let parameter = Prefix<Input> { $0 != .init(ascii: "=") }.map { String(decoding: $0, as: UTF8.self) }
    .skip("=".utf8)
    .take(stringLiteral)
    .map { (key: $0, value: $1) }

public let parameters = Many(parameter, atLeast: 1, separator: Whitespace()).map { parameters in
    parameters.reduce(into: [:]) { $0[$1.0] = $1.1 }
}

public let doctypeHead = "?xml".utf8
    .skip(Whitespace<Input>())
    .take(parameters)
    .skip("?".utf8)
    .map { parameters in
        XML.doctype(parameters)
    }

public let doctype = tag.pipe(doctypeHead)

public let comment = "<!--".utf8
    .take(PrefixUpTo("-->".utf8).skip("-->".utf8))
    .map { XML.comment(String(decoding: $0, as: UTF8.self)) }
    .skip(Optional.parser(of: Newline().skip(Whitespace())))

public let closingSlash = Optional.parser(of: "/".utf8).map { $0 != nil ? true : false }

// covers the following tag layouts
// <tag1 param1="value1">
// <tag2 param2="value2"/>
// <tag3 param3="value3" />
public let tagHeadWithParameters = Prefix<Input> { $0 != .init(ascii: " ") }.map { String(decoding: $0, as: UTF8.self) }
    .skip(Whitespace())
    .take(parameters)
    .skip(Whitespace())
    .take(closingSlash)
    .skip(End())
    .eraseToAnyParser()

// covers the following tag layouts
// <tag1>
// <tag2/>
// <tag3 />
public let tagHeadNoParameters = Prefix<Input> { $0 != .init(ascii: " ") && $0 != .init(ascii: "/") }.skip(Whitespace()).take(closingSlash)

public let tagHead = tagHeadWithParameters.orElse(tagHeadNoParameters.map { tagName, hasClosingSlash in (String(decoding: tagName, as: UTF8.self), [:], hasClosingSlash) })

public let fullTag = tag.pipe(tagHead)

public let singleXMLTag = fullTag
    .flatMap { tagName, parameters, single in
        single == true
        ? Conditional.first(Always(XML.element(tagName, parameters, [])))
        : Conditional.second(Fail())
    }.skip(Optional.parser(of: Newline().skip(Whitespace())))

public let containerXMLTagBody: (String) -> AnyParser<Input, Input> = { tagName in
    let tag = "</\(tagName)>".utf8
    return PrefixUpTo(tag)
        .skip(tag)
        .skip(Optional.parser(of: Newline().skip(Whitespace())))
        .eraseToAnyParser()
}

public let containerXMLTag = fullTag
    .flatMap { tagName, parameters, single in
        single == false
        ? Conditional.first(
            containerXMLTagBody(tagName)
                .pipe(Lazy { xmlBody }.skip(End()))
                .map { xml in
                    return XML.element(tagName, parameters, xml)
                }
        )
        : Conditional.second(Fail())
    }

public var text: AnyParser<Input, XML> {
    Optional.parser(of: End()).flatMap {
        $0 != nil
        ? Conditional.first(Fail())
        : Conditional.second(
            Prefix<Input> { $0 != .init(ascii: "<") && $0 != .init(ascii: "\n") }
                .map { .text(String(decoding: $0, as: UTF8.self)) }
        )
    }.skip(Optional.parser(of: Newline().skip(WhitespaceNoNewline())))
    .eraseToAnyParser()
}

public var xmlBody: AnyParser<Input, [XML]> {
    Skip(Whitespace())
    .take(
        Many(
            singleXMLTag
                .orElse(containerXMLTag)
                .orElse(comment)
                .orElse(text)
        )
    )
    .skip(Whitespace())
    .skip(End())
    .eraseToAnyParser()
}

public var xml: AnyParser<Substring.UTF8View, [XML]> {
    doctype
        .skip(Newline())
        .take(xmlBody).map {
            Array([[$0], $1].joined())
        }.eraseToAnyParser()
}
