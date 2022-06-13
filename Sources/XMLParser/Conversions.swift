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
    struct TagHeadToXML: Conversion {
        @inlinable
        init() { }
        
        @inlinable
        func apply(_ input: (String, OrderedDictionary<String, String>)) -> XML {
            XML.element(input.0, input.1, [])
        }
        
        @inlinable
        func unapply(_ output: XML) throws -> (String, OrderedDictionary<String, String>) {
            switch output {
            case let .element(tagName, attributes, []):
                return (tagName, attributes)
            default:
                throw XMLConversionError()
            }
        }
    }
    
    struct XMLElement: Conversion {
        @inlinable
        init() { }
        
        @inlinable
        func apply(_ input: ((String, OrderedDictionary<String, String>), [XML], String)) -> XML {
            .element(input.0.0, input.0.1, input.1)
        }
        
        @inlinable
        func unapply(_ output: XML) throws -> ((String, OrderedDictionary<String, String>), [XML], String) {
            switch output {
            case let .element(tagName, attributes, xml):
                return ((tagName, attributes), xml, tagName)
            default:
                throw XMLConversionError()
            }
        }
    }
    
    struct XMLComment: Conversion {
        @inlinable
        init() { }
        
        @inlinable
        func apply(_ input: String) throws -> XML {
            .comment(input)
        }
        
        @inlinable
        func unapply(_ output: XML) throws -> String {
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
        func apply(_ input: String) throws -> XML {
            .text(input)
        }
        
        @inlinable
        func unapply(_ output: XML) throws -> String {
            switch output {
            case let .text(comment):
                return comment
            default:
                throw XMLConversionError()
            }
        }
    }
    
    struct XMLDoctype: Conversion {
        @inlinable
        init() { }
        
        @inlinable
        func apply(_ input: OrderedDictionary<String, String>) throws -> XML {
            .doctype(input)
        }
        
        @inlinable
        func unapply(_ output: XML) throws -> OrderedDictionary<String, String> {
            switch output {
            case let .doctype(attributes):
                return attributes
            default:
                throw XMLConversionError()
            }
        }
    }
    
    struct XMLRoot: Conversion {
        @inlinable
        init() { }
        
        @inlinable
        func apply(_ input: (XML?, XML)) throws -> [XML] {
            let doctype = input.0
            let root = input.1
            if let doctype = doctype {
                return [doctype, root]
            } else {
                return [root]
            }
        }
        
        @inlinable
        func unapply(_ output: [XML]) throws -> (XML?, XML) {
            guard output.count > 0, output.count <= 2 else  {
                throw XMLConversionError()
            }
            
            let doctype: XML? = output.count == 2 ? output[0] : nil
            let root: XML = output[output.count-1]
            
            if let doctype {
                switch doctype {
                case .doctype:
                    break
                default:
                    throw XMLConversionError()
                }
            }
            
            switch root {
            case .element:
                break
            default:
                throw XMLConversionError()
            }
            
            return (doctype, root)
        }
    }
}

internal struct XMLConversionError: Error { }
