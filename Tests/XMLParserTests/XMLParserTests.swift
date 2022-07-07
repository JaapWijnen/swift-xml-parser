import XCTest
@testable import XMLParser
import Parsing
import CustomDump


final class XMLParserTests: XCTestCase {
    func testQuotedString() throws {
        let quotedString = "\"hoi\""
        let result = try quotedStringParser.parse(quotedString)
        XCTAssertNoDifference("hoi", result)
        let printResult = try quotedStringParser.print(result)
        XCTAssertNoDifference(String(printResult), quotedString)
    }

    func testAttribute() throws {
        let attribute = "header=\"none\""
        let result = try attributeParser.parse(attribute)
        XCTAssertNoDifference(result.0, "header")
        XCTAssertNoDifference(result.1, "none")
        let printResult = try attributeParser.print(result)
        XCTAssertNoDifference(String(printResult), attribute)
    }

    func testAttributes() throws {
        let attributes = "header1=\"none\" header2=\"some\""
        let result = try attributesParser.parse(attributes)
        XCTAssertNoDifference(result["header1"], "none")
        XCTAssertNoDifference(result["header2"], "some")
        let printResult = try attributesParser.print(result)
        XCTAssertNoDifference(String(printResult), attributes)
    }

    func testTagHead() throws {
        let tagHead1 = "xmlTag header=\"none\" "
        let result1 = try tagHeadParser.parse(tagHead1)
        XCTAssertNoDifference(result1.0, "xmlTag")
        XCTAssertNoDifference(result1.1["header"], "none")

        let tagHead2 = "xmlTag "
        let result2 = try tagHeadParser.parse(tagHead2)
        XCTAssertNoDifference(result2.0, "xmlTag")
        XCTAssertNoDifference(result2.1["header"], nil)
    }

    func testEmptyTag() throws {
        let emptyTag1 = "<xmlTag header1=\"none\"/>"
        let result1 = try emptyTagParser.parse(emptyTag1)
        XCTAssertNoDifference(result1, .init(name: "xmlTag", attributes: ["header1": "none"]))
        let printResult1 = try emptyTagParser.print(result1)
        XCTAssertNoDifference(String(printResult1), emptyTag1)
        
        let emptyTag2 = "<xmlTag header1=\"none\" />"
        let result2 = try emptyTagParser.parse(emptyTag2)
        XCTAssertNoDifference(result2, .init(name: "xmlTag", attributes: ["header1": "none"]))
        let printResult2 = try emptyTagParser.print(result2)
        XCTAssertNoDifference(String(printResult2), emptyTag1)
    }

    func testOpeningTag() throws {
        let openingTag = "<xmlTag header1=\"none\">"
        let result = try openingTagParser.parse(openingTag)
        XCTAssertNoDifference(result.0, "xmlTag")
        XCTAssertNoDifference(result.1["header1"], "none")
        let printResult = try openingTagParser.print(result)
        XCTAssertNoDifference(String(printResult), openingTag)
    }

    func testContainerTag() throws {
        let containerTag = "<xmlTag headerContent=\"none\">tagContent</xmlTag>"
        let result = try containerTagParser(nil).parse(containerTag)
        XCTAssertNoDifference(result, .init(name: "xmlTag", attributes: ["headerContent": "none"], content: [.text("tagContent")]))
        let printResult = try containerTagParser(nil).print(result)
        XCTAssertNoDifference(String(printResult), containerTag)
    }

    func testText() throws {
        let text = "hoi"
        let result = try textParser.parse(text)
        XCTAssertNoDifference(result, .text("hoi"))
        let printResult = try textParser.print(result)
        XCTAssertNoDifference(String(printResult), text)
    }

    func testComment() throws {
        let comment = "<!--some comments <xml in=\"between\"> endOfcomment-->"
        let result = try commentParser.parse(comment)
        XCTAssertNoDifference(result, .comment("some comments <xml in=\"between\"> endOfcomment"))
        let printResult = try commentParser.print(result)
        XCTAssertNoDifference(String(printResult), comment)
    }

    func testXMLContentText() throws {
        let body = "hoi"
        let result = try contentParser(nil).parse(body)
        XCTAssertNoDifference(result, .text("hoi"))
        let printResult = try contentParser(nil).print(result)
        XCTAssertNoDifference(String(printResult), body)
    }

    func testXMLContentComment() throws {
        let body = "<!--hoi-->"
        let result = try contentParser(nil).parse(body)
        XCTAssertNoDifference(result, .comment("hoi"))
        let printResult = try contentParser(nil).print(result)
        XCTAssertNoDifference(String(printResult), body)
    }

    func testXMLContentEmptyTag() throws {
        let tag = "<xmlTag header=\"none\"/>"
        let result = try contentParser(nil).parse(tag)
        XCTAssertNoDifference(result, .element(.init(name: "xmlTag", attributes: ["header": "none"])))
        let printResult = try contentParser(nil).print(result)
        XCTAssertNoDifference(String(printResult), tag)
    }

    func testXMLContentContainerTag() throws {
        let containerTag = "<xmlTag headerContent=\"none\">tagContent</xmlTag>"
        let result = try contentParser(nil).parse(containerTag)
        XCTAssertNoDifference(result, .element(.init(name: "xmlTag", attributes: ["headerContent": "none"], content: [.text("tagContent")])))
        let printResult = try contentParser(nil).print(result)
        XCTAssertNoDifference(String(printResult), containerTag)
    }

    func testProlog() throws {
        let prolog = "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
        let result = try xmlPrologParser.parse(prolog)
        XCTAssertNoDifference(result, ["version": "1.0", "encoding": "utf-8"])
        let printResult = try xmlPrologParser.print(result)
        XCTAssertNoDifference(String(printResult), prolog)
    }

    func testXMLProlog() throws {
        let prolog = "<?xml version=\"1.0\" encoding=\"utf-8\"?><root></root>"
        let result = try XMLParser(indenting: false).parse(prolog)
        XCTAssertNoDifference(result, XML(prolog: ["version": "1.0", "encoding": "utf-8"], root: .init(name: "root")))
        let printResult = try XMLParser(indenting: false).print(result)
        XCTAssertNoDifference(String(printResult), prolog)
    }
    
    func testXMLEmptyTag() throws {
        let xml = "<?xml version=\"1.0\" encoding=\"utf-8\"?><root><empty/></root>"
        let result = try XMLParser(indenting: false).parse(xml)
        XCTAssertNoDifference(
            result,
            XML(
                prolog: ["version": "1.0", "encoding": "utf-8"],
                root: .init(
                    name: "root",
                    attributes: [:],
                    content: [
                        .element(.init(
                            name: "empty",
                            attributes: [:],
                            content: []
                        ))
                    ]
                )
            )
        )
        let printResult = try XMLParser(indenting: false).print(result)
        XCTAssertNoDifference(String(printResult), xml)
    }

    func testXMLContainerTag() throws {
        let xml = "<?xml version=\"1.0\" encoding=\"utf-8\"?><root><nonEmpty>a</nonEmpty></root>"
        let result = try XMLParser(indenting: false).parse(xml)
        XCTAssertNoDifference(
            result,
            XML(
                prolog: ["version": "1.0", "encoding": "utf-8"],
                root: .init(
                    name: "root",
                    attributes: [:],
                    content: [
                        .element(.init(
                            name: "nonEmpty",
                            attributes: [:],
                            content: [.text("a")]
                        ))
                    ]
                )
            )
        )
        let printResult = try XMLParser(indenting: false).print(result)
        XCTAssertNoDifference(String(printResult), xml)
    }

    func testXMLText() throws {
        let xml = "<?xml version=\"1.0\" encoding=\"utf-8\"?><root>text</root>"
        let result = try XMLParser(indenting: false).parse(xml)
        XCTAssertNoDifference(result, XML(prolog: ["version": "1.0", "encoding": "utf-8"], root: .init(name: "root", content: [.text("text")])))
        let printResult = try XMLParser(indenting: false).print(result)
        XCTAssertNoDifference(String(printResult), xml)
    }

    func testXMLComment() throws {
        let xml = "<?xml version=\"1.0\" encoding=\"utf-8\"?><root><!--comment--></root>"
        let result = try XMLParser(indenting: false).parse(xml)
        XCTAssertNoDifference(result, XML(prolog: ["version": "1.0", "encoding": "utf-8"], root: .init(name: "root", content: [.comment("comment")])))
        let printResult = try XMLParser(indenting: false).print(result)
        XCTAssertNoDifference(String(printResult), xml)
    }

    func testXMLNewlines() throws {
        let xml = """
        <?xml version=\"1.0\" encoding=\"utf-8\"?>
        <root>
            <nonEmpty>
                text
            </nonEmpty>
        </root>
        """
        let result = try XMLParser(indenting: false).parse(xml)
        XCTAssertNoDifference(result, XML(prolog: ["version": "1.0", "encoding": "utf-8"], root: .init(name: "root", content: [.element(.init(name: "nonEmpty", content: [.text("text")]))])))
    }
}

final class XMLExampleTests: XCTestCase {
    let indentedXML = """
        <?xml version="1.0" encoding="utf-8"?>
        <Schema Namespace="microsoft.graph" Alias="graph" xmlns="http://docs.oasis-open.org/odata/ns/edm">
            <EnumType Name="appliedConditionalAccessPolicyResult">
                <Member Name="success" Value="0"/>
                <Member Name="failure" Value="1"/>
                <Member Name="notApplied" Value="2"/>
                <Member Name="notEnabled" Value="3"/>
                <Member Name="unknown" Value="4"/>
                <Member Name="unknownFutureValue" Value="5"/>
            </EnumType>
            <EnumType Name="conditionalAccessStatus">
                <Member Name="success" Value="0"/>
                <Member Name="failure" Value="1"/>
                <Member Name="notApplied" Value="2"/>
                <Member Name="unknownFutureValue" Value="3"/>
            </EnumType>
            <EnumType Name="groupType">
                <Member Name="unifiedGroups" Value="0"/>
                <Member Name="azureAD" Value="1"/>
                <Member Name="unknownFutureValue" Value="2"/>
            </EnumType>
            <EnumType Name="initiatorType">
                <Member Name="user" Value="0"/>
                <Member Name="application" Value="1"/>
                <Member Name="system" Value="2"/>
                <Member Name="unknownFutureValue" Value="3"/>
            </EnumType>
            <value>
                4
            </value>
        </Schema>
        """
    let flatXML = """
        <?xml version="1.0" encoding="utf-8"?><Schema Namespace="microsoft.graph" Alias="graph" xmlns="http://docs.oasis-open.org/odata/ns/edm"><EnumType Name="appliedConditionalAccessPolicyResult"><Member Name="success" Value="0"/><Member Name="failure" Value="1"/><Member Name="notApplied" Value="2"/><Member Name="notEnabled" Value="3"/><Member Name="unknown" Value="4"/><Member Name="unknownFutureValue" Value="5"/></EnumType><EnumType Name="conditionalAccessStatus"><Member Name="success" Value="0"/><Member Name="failure" Value="1"/><Member Name="notApplied" Value="2"/><Member Name="unknownFutureValue" Value="3"/></EnumType><EnumType Name="groupType"><Member Name="unifiedGroups" Value="0"/><Member Name="azureAD" Value="1"/><Member Name="unknownFutureValue" Value="2"/></EnumType><EnumType Name="initiatorType"><Member Name="user" Value="0"/><Member Name="application" Value="1"/><Member Name="system" Value="2"/><Member Name="unknownFutureValue" Value="3"/></EnumType><value>4</value></Schema>
        """
    
    let structuredXML: XML = XML(
        prolog: ["version": "1.0", "encoding": "utf-8"],
        root: .init(
            name: "Schema",
            attributes: [
                "Namespace": "microsoft.graph",
                "Alias": "graph",
                "xmlns": "http://docs.oasis-open.org/odata/ns/edm"
            ],
            content: [
                .element(.init(
                    name: "EnumType",
                    attributes: ["Name": "appliedConditionalAccessPolicyResult"],
                    content: [
                        .element(.init(name: "Member", attributes: ["Name": "success", "Value": "0"])),
                        .element(.init(name: "Member", attributes: ["Name": "failure", "Value": "1"])),
                        .element(.init(name: "Member", attributes: ["Name": "notApplied", "Value": "2"])),
                        .element(.init(name: "Member", attributes: ["Name": "notEnabled", "Value": "3"])),
                        .element(.init(name: "Member", attributes: ["Name": "unknown", "Value": "4"])),
                        .element(.init(name: "Member", attributes: ["Name": "unknownFutureValue", "Value": "5"])),
                    ]
                )),
                .element(.init(
                    name: "EnumType",
                    attributes: ["Name": "conditionalAccessStatus"],
                    content: [
                        .element(.init(name: "Member", attributes: ["Name": "success", "Value": "0"])),
                        .element(.init(name: "Member", attributes: ["Name": "failure", "Value": "1"])),
                        .element(.init(name: "Member", attributes: ["Name": "notApplied", "Value": "2"])),
                        .element(.init(name: "Member", attributes: ["Name": "unknownFutureValue", "Value": "3"])),
                    ]
                )),
                .element(.init(
                    name: "EnumType",
                    attributes: ["Name": "groupType"],
                    content: [
                        .element(.init(name: "Member", attributes: ["Name": "unifiedGroups", "Value": "0"])),
                        .element(.init(name: "Member", attributes: ["Name": "azureAD", "Value": "1"])),
                        .element(.init(name: "Member", attributes: ["Name": "unknownFutureValue", "Value": "2"]))
                    ]
                )),
                .element(.init(
                    name: "EnumType",
                    attributes: ["Name": "initiatorType"],
                    content: [
                        .element(.init(name: "Member", attributes: ["Name": "user", "Value": "0"])),
                        .element(.init(name: "Member", attributes: ["Name": "application", "Value": "1"])),
                        .element(.init(name: "Member", attributes: ["Name": "system", "Value": "2"])),
                        .element(.init(name: "Member", attributes: ["Name": "unknownFutureValue", "Value": "3"])),
                    ]
                )),
                .element(.init(
                    name: "value",
                    attributes: [:],
                    content: [.text("4")]
                )),
            ]
        )
    )
    
    func testExample() throws {
        let result = try XMLParser(indenting: false).parse(indentedXML)
        XCTAssertNoDifference(
            result,
            structuredXML
        )
        let printResult = try XMLParser(indenting: false).print(result)
        XCTAssertNoDifference(String(printResult), flatXML)
    }
    
    func testIndentedExample() throws {
        let result = try XMLParser().parse(indentedXML)
        XCTAssertNoDifference(
            result,
            structuredXML
        )
        let printResult = try XMLParser().print(result)
        XCTAssertNoDifference(String(printResult), indentedXML)
    }
    
    func testFlatToIndent() throws {
        let result = try XMLParser().parse(flatXML)
        XCTAssertNoDifference(
            result,
            structuredXML
        )
        let printResult = try XMLParser().print(result)
        XCTAssertNoDifference(String(printResult), indentedXML)
    }
}
