import Parsing
import Collections

extension Conversions {
    struct OptionalEmptyDictionary<Key: Hashable, Value>: Conversion {
        @inlinable
         init() {}

        @inlinable
        func apply(_ input: OrderedDictionary<Key, Value>?) -> OrderedDictionary<Key, Value> {
            input ?? [:]
        }

        @inlinable
        func unapply(_ output: OrderedDictionary<Key, Value>) -> OrderedDictionary<Key, Value>? {
            output.isEmpty ? nil : output
        }
    }
}

extension Conversions {
    struct TuplesToDictionary<Key: Hashable, Value>: Conversion {
        @inlinable
        init() {}
        
        @inlinable
        func apply(_ input: [(Key, Value)]) -> OrderedDictionary<Key, Value> {
            input.reduce(into: [:]) { $0[$1.0] = $1.1 }
        }

        @inlinable
        func unapply(_ output: OrderedDictionary<Key, Value>) -> [(Key, Value)] {
            output.map { $0 }
        }
    }
}

extension Conversions {
    struct XMLEmptyElement: Conversion {
        @inlinable
        init() { }
        
        @inlinable
        func apply(_ input: (String, OrderedDictionary<String, String>)) throws -> XML.Element {
            XML.Element(name: input.0, attributes: input.1, content: [])
        }
        
        @inlinable
        func unapply(_ output: XML.Element) throws -> (String, OrderedDictionary<String, String>) {
            guard output.content.isEmpty else {
                throw XMLConversionError()
            }
            return (output.name, output.attributes)
        }
    }
    
    struct XMLNodeElement: Conversion {
        @inlinable
        init() { }
        
        @inlinable
        func apply(_ input: XML.Element) throws -> XML.Node {
            .element(input)
        }
        
        @inlinable
        func unapply(_ output: XML.Node) throws -> XML.Element {
            switch output {
            case let .element(element):
                return element
            default:
                throw XMLConversionError()
            }
        }
    }
//    struct TagHeadToXML: Conversion {
//        @inlinable
//        init() { }
//
//        @inlinable
//        func apply(_ input: (String, OrderedDictionary<String, String>)) -> XML.Node {
//            XML.Node.element(input.0, input.1, [])
//        }
//
//        @inlinable
//        func unapply(_ output: XML.Node) throws -> (String, OrderedDictionary<String, String>) {
//            switch output {
//            case let .element(tagName, attributes, []):
//                return (tagName, attributes)
//            default:
//                throw XMLConversionError()
//            }
//        }
//    }
    
    struct XMLElement: Conversion {
        @inlinable
        init() { }
        
        @inlinable
        func apply(_ input: ((String, OrderedDictionary<String, String>), [XML.Node], String)) -> XML.Element {
            XML.Element(name: input.0.0, attributes: input.0.1, content: input.1)
        }
        
        @inlinable
        func unapply(_ output: XML.Element) -> ((String, OrderedDictionary<String, String>), [XML.Node], String) {
            ((output.name, output.attributes), output.content, output.name)
        }
    }
    
    struct XMLComment: Conversion {
        @inlinable
        init() { }
        
        @inlinable
        func apply(_ input: String) throws -> XML.Node {
            .comment(input)
        }
        
        @inlinable
        func unapply(_ output: XML.Node) throws -> String {
            switch output {
            case let .comment(comment):
                return comment
            default:
                throw XMLConversionError()
            }
        }
    }
    
    struct XMLText: Conversion {
        @inlinable
        init() { }
        
        @inlinable
        func apply(_ input: String) throws -> XML.Node {
            .text(input)
        }
        
        @inlinable
        func unapply(_ output: XML.Node) throws -> String {
            switch output {
            case let .text(comment):
                return comment
            default:
                throw XMLConversionError()
            }
        }
    }
    
    struct XMLRoot: Conversion {
        @inlinable
        init() { }
        
        @inlinable
        func apply(_ input: (XML.Prolog, XML.Element)) -> XML {
            XML(prolog: input.0, root: input.1)
        }
        
        @inlinable
        func unapply(_ output: XML) -> (XML.Prolog, XML.Element) {
            return (output.prolog, output.root)
        }
    }
}

internal struct XMLConversionError: Error { }
