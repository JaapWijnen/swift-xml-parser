# ``XMLParser``

A reversible XML parser the parses XML into a structured ``XML`` data type and can print instances of this type into formatted XML string.

## Overview

Basic usage: 
```swift
import XMLParser

var input = """
<?xml version=\"1.0\" encoding=\"utf-8\"?>
<root>
    <content attribute1="value" />
</root>
"""

// The `XMLParser` type takes a single `Bool` parameter which determines the printing mode (with or without newlines/indentation)
let xml = try XMLParser(indenting: true).parse(input)
//XML(
//    prolog: [
//        "version": "1.0", 
//        "encoding": "utf-8"
//    ], 
//    root: XML.Element(
//        name: "root", 
//        attributes: [:], 
//        content: [
//            .element(.init(name: "content", attributes: ["attribute1": "value"]))
//        ]
//    )
//)

let indentedPrintedXML = xmlParser(true).print(xml)
//<?xml version=\"1.0\" encoding=\"utf-8\"?>
//<root>
//    <content attribute1="value"/>
//</root>

let flatPrintedXML = xmlParser(false).print(xml)
//<?xml version=\"1.0\" encoding=\"utf-8\"?><root><content attribute1="value"/></root>
```

## Topics

### Types
- ``XMLParser/XMLParser``
- ``XML``
- ``XML/Element``
- ``XML/Node``

