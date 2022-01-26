import XCTest
@testable import XMLParser
import Parsing
import CustomDump

final class XMLParserTests: XCTestCase {
    
    let biggerExample = """
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
    </Schema>
    """
    
    let nestedExample = """
    <EnumType Name="appliedConditionalAccessPolicyResult">
        <Member Name="success" Value="0"/>
        <Member Name="failure" Value="1"/>
        <Member Name="notApplied" Value="2"/>
        <Member Name="notEnabled" Value="3"/>
        <Member Name="unknown" Value="4"/>
        <Member Name="unknownFutureValue" Value="5"/>
    </EnumType>
    """
    
    let multipleSingleTagsExample = """
        <Member Name="success" Value="0"/>
        <Member Name="failure" Value="1"/>
        <Member Name="notApplied" Value="2"/>
        <Member Name="notEnabled" Value="3"/>
        <Member Name="unknown" Value="4"/>
        <Member Name="unknownFutureValue" Value="5"/>
    """
    
    func testClosingSlash() throws {
        let test = "/"
        let (result, rest) = closingSlash.parse(test[...].utf8)
        XCTAssertNoDifference(rest.count, 0)
        XCTAssertNoDifference(result, true)
    }
    
    func testClosingSlashNil() throws {
        let test = "d"
        let (result, rest) = closingSlash.parse(test[...].utf8)
        XCTAssertNoDifference(String(rest)!, "d")
        XCTAssertNoDifference(result, false)
    }
    
    func testTagHead() throws {
        let test = "Member Name=\"success\" Value=\"0\""
        let (result, rest) = tagHead.parse(test[...].utf8)
        
        XCTAssertNoDifference(rest.count, 0)
        XCTAssertNoDifference(result!.0, "Member")
        XCTAssertNoDifference(result!.1, ["Name": "success", "Value": "0"])
        XCTAssertNoDifference(result!.2, false)
    }
    
    func testClosingTagHead() throws {
        let test = "Member Name=\"success\" Value=\"0\"/"
        let (result, rest) = tagHead.parse(test[...].utf8)
        
        XCTAssertNoDifference(rest.count, 0)
        XCTAssertNoDifference(result!.0, "Member")
        XCTAssertNoDifference(result!.1, ["Name": "success", "Value": "0"])
        XCTAssertNoDifference(result!.2, true)
    }
    
    func testClosingTagHeadWithOffset() throws {
        let test = "Member Name=\"success\" Value=\"0\" /"
        let (result, rest) = tagHead.parse(test[...].utf8)
        
        XCTAssertNoDifference(rest.count, 0)
        XCTAssertNoDifference(result!.0, "Member")
        XCTAssertNoDifference(result!.1, ["Name": "success", "Value": "0"])
        XCTAssertNoDifference(result!.2, true)
    }
    
    func testTagHeadNoParameters() throws {
        func testTagHead() throws {
            let test = "Member"
            let (result, rest) = tagHead.parse(test[...].utf8)
            
            XCTAssertNoDifference(rest.count, 0)
            XCTAssertNoDifference(result!.0, "Member")
            XCTAssertTrue(zip(result!.1, []).allSatisfy { $0 == $1 })
            XCTAssertNoDifference(result!.2, false)
        }
    }
    
    func testClosingTagHeadNoParameters() throws {
        func testTagHead() throws {
            let test = "Member/"
            let (result, rest) = tagHead.parse(test[...].utf8)
            
            XCTAssertNoDifference(rest.count, 0)
            XCTAssertNoDifference(result!.0, "Member")
            XCTAssertTrue(zip(result!.1, []).allSatisfy { $0 == $1 })
            XCTAssertNoDifference(result!.2, true)
        }
    }
    
    func testClosingTagHeadNoParametersWithOffset() throws {
        func testTagHead() throws {
            let test = "Member /"
            let (result, rest) = tagHead.parse(test[...].utf8)
            
            XCTAssertNoDifference(rest.count, 0)
            XCTAssertNoDifference(result!.0, "Member")
            XCTAssertTrue(zip(result!.1, []).allSatisfy { $0 == $1 })
            XCTAssertNoDifference(result!.2, true)
        }
    }
    
    func testThing() {
        XCTAssertNoDifference(["hoi": "hoi", "nee": "nee"], ["nee": "nee", "hoi": "hoi"])
    }

    func testSelfClosingTag() throws {
        let test = "<Member Name=\"success\" Value=\"0\"/>"
        let (result, rest) = singleXMLTag.parse(test[...].utf8)
        XCTAssertNoDifference(rest.count, 0)
        XCTAssertNoDifference(result, XML.element("Member", ["Name": "success", "Value": "0"], []))
    }
    
    func testSelfClosingTagWithOffset() throws {
        let test = "<Member Name=\"success\" Value=\"0\" />"
        let (result, rest) = singleXMLTag.parse(test[...].utf8)
        XCTAssertNoDifference(rest.count, 0)
        XCTAssertNoDifference(result, XML.element("Member", ["Name": "success", "Value": "0"], []))
    }
    
    func testTagNoParameters() throws {
        let test = "<Member/>"
        let (result, rest) = singleXMLTag.parse(test[...].utf8)
        XCTAssertNoDifference(rest.count, 0)
        XCTAssertNoDifference(result, XML.element("Member", [:], []))
    }
    
    func testTagNoParametersWithOffset() throws {
        let test = "<Member />"
        let (result, rest) = singleXMLTag.parse(test[...].utf8)
        XCTAssertNoDifference(rest.count, 0)
        XCTAssertNoDifference(result, XML.element("Member", [:], []))
    }
    
    func testRestText() throws {
        let test = "line1"
        let (result, rest) = text.parse(test[...].utf8)
        XCTAssertNoDifference(rest.count, 0)
        XCTAssertNoDifference(result, .text("line1"))
    }
    
    func testComment() throws {
        let test = "<!--comment here-->"
        let (result, rest) = comment.parse(test[...].utf8)
        XCTAssertNoDifference(rest.count, 0)
        XCTAssertNoDifference(result, XML.comment("comment here"))
    }
    
    func testCommentFromBody() throws {
        let test = "<!--oh man some comment-->"
        let (result, rest) = xmlBody.parse(test[...].utf8)
        XCTAssertNoDifference(rest.count, 0)
        XCTAssertNoDifference(result, [.comment("oh man some comment")])
    }
    
    func testTagWithComment() throws {
        let test = """
            <tag1/>
            <!--oh man some comment-->
            text
            """
        let (result, rest) = xmlBody.parse(test[...].utf8)
        XCTAssertNoDifference(rest.count, 0)
        XCTAssertNoDifference(result, [.element("tag1", [:], []), .comment("oh man some comment"), .text("text")])
    }
    
    func testNestedComment() throws {
        let test = """
            <parent>
                <derp/>
                hmm content
                <!--oh man some comment-->
                <derp/>
            </parent>
            """
        let (result, rest) = xmlBody.parse(test[...].utf8)
        XCTAssertNoDifference(rest.count, 0)
        XCTAssertNoDifference(result, [.element("parent", [:], [.element("derp", [:], []), .text("hmm content"), .comment("oh man some comment"), .element("derp", [:], [])])])
    }
    
    func testMultilineRestText() throws {
        let test = """
            line1
            line2
            """
        let (result, rest) = xmlBody.parse(test[...].utf8)
        XCTAssertNoDifference(rest.count, 0)
        XCTAssertNoDifference(result, [.text("line1"), .text("line2")])
    }
    
//    Skip(Whitespace())
//    .take(
//        Many(
//            newSingleXMLTag
//                .orElse(newContainerXMLTag)
//                .orElse(
//                    Optional.parser(of: Newline()).flatMap {
//                        $0 != nil
//                        ? Conditional.first(
//                            Skip(Whitespace())
//                                .take(newestRestText))
//                        : Conditional.second(newestRestText)
//                    }
//                )
//        )
//    )
//    .skip(Whitespace())
//    .skip(End())
//    .eraseToAnyParser()
    
    func testMultilineRestTextWithNewline() throws {
        let test = """
            line1
            line2
            
            
            """
        let (result, rest) = xmlBody.parse(test[...].utf8)
        XCTAssertNoDifference(rest.count, 0)
        XCTAssertNoDifference(result, [.text("line1"), .text("line2"), .text("")])
    }
    
//    var newestRestText: AnyParser<Input, XML> {
//        Optional.parser(of: End()).flatMap {
//            $0 != nil
//            ? Conditional.first(Fail())
//            : Conditional.second(
//                Prefix<Input> { $0 != .init(ascii: "<") || $0 != .init(ascii: "\n") }
//                    .map { .text(String(decoding: $0, as: UTF8.self)) }
//            )
//        }.eraseToAnyParser()
//    }
    
    func testMultilineRestTextWithWhiteSpace() throws {
        let test = """
            line1
                line2
            """
        let (result, rest) = xmlBody.parse(test[...].utf8)
        XCTAssertNoDifference(rest.count, 0)
        XCTAssertNoDifference(result, [.text("line1"), .text("line2")])
    }
    
    func testEmptyRestText() throws {
        let test = ""
        let (result, rest) = text.parse(test[...].utf8)
        XCTAssertNoDifference(rest.count, 0)
        XCTAssertNil(result) // or map to empty array?
    }
    
    func testEmptyXMLBody() throws {
        let test = ""
        let (result, rest) = xmlBody.parse(test[...].utf8)
        XCTAssertNoDifference(rest.count, 0)
        XCTAssertNoDifference(result, [])
    }
    
    func testContainerTag() throws {
        let test = "<EnumType Name=\"appliedConditionalAccessPolicyResult\"></EnumType>"
        let (result, rest) = containerXMLTag.parse(test[...].utf8)
        XCTAssertNoDifference(rest.count, 0)
        XCTAssertNoDifference(result, XML.element("EnumType", ["Name": "appliedConditionalAccessPolicyResult"], []))
    }
    
    func testTagWithText() throws {
        let test = "<testTag>hee text</testTag>"
        let (result, rest) = containerXMLTag.parse(test[...].utf8)
        XCTAssertNoDifference(rest.count, 0)
        XCTAssertNoDifference(result, XML.element("testTag", [:], [.text("hee text")]))
    }
    
    func testContainerTagContentWithTextAndTag() throws {
        let test = "hee text<Derp/>"
        let (result, rest) = xmlBody.parse(test[...].utf8)
        XCTAssertNoDifference(rest.count, 0)
        XCTAssertNoDifference(result, [.text("hee text"), XML.element("Derp", [:], [])])
    }
    
    func testTagWithTextAndTag() throws {
        let test = "<testTag>hee text<Derp/></testTag>"
        let (result, rest) = containerXMLTag.parse(test[...].utf8)
        XCTAssertNoDifference(rest.count, 0)
        XCTAssertNoDifference(result, XML.element("testTag", [:], [.text("hee text"), .element("Derp", [:], [])]))
    }
    
    func testEmptyContainerTag() throws {
        let test = """
        <parent>
        </parent>
        """
        let (result, rest) = xmlBody.parse(test[...].utf8)
        XCTAssertNoDifference(rest.count, 0)
        XCTAssertNoDifference(result, [XML.element("parent", [:], [])])
    }
    
    func testNestedTag() throws {
        let test = """
        <parent>
            <child/>
            <child/>
        </parent>
        """
    
        let (result, rest) = xmlBody.parse(test[...].utf8)
        XCTAssertNoDifference(rest.count, 0)
        XCTAssertNoDifference(result, [XML.element("parent", [:], [.element("child", [:], []), .element("child", [:], [])])])
    }
    
    func testDoublyNestedTag() throws {
        let test = """
        <parent>
            <child>
                <subchild/>
            </child>
        </parent>
        """

        let (result, rest) = xmlBody.parse(test[...].utf8)
        XCTAssertNoDifference(rest.count, 0)
        XCTAssertNoDifference(result, [XML.element("parent", [:], [.element("child", [:], [.element("subchild", [:], [])])])])
    }
    
    func testMultipleLinesOfText() throws {
        let test = """
        <parent>
            line 1
            line 2
            line 3
        </parent>
        """
        let (result, rest) = xmlBody.parse(test[...].utf8)
        XCTAssertNoDifference(rest.count, 0)
        XCTAssertNoDifference(result, [XML.element("parent", [:], [.text("line 1"), .text("line 2"), .text("line 3")])])
    }
    
    func testMultipleLinesOfTextAndEmptyLine() throws {
        let test = """
        <parent>
            line 1
            line 2
            line 3
            
        </parent>
        """
        let (result, rest) = xmlBody.parse(test[...].utf8)
        XCTAssertNoDifference(rest.count, 0)
        XCTAssertNoDifference(result, [XML.element("parent", [:], [.text("line 1"), .text("line 2"), .text("line 3"), .text("")])])
    }
    
    func testDoublyNestedTagWithText() throws {
        let test = """
        <parent>
            <child>
                <subchild/>
                aha feest
            </child>
        </parent>
        """

        let (result, rest) = xmlBody.parse(test[...].utf8)
        XCTAssertNoDifference(rest.count, 0)
        XCTAssertNoDifference(result, [XML.element("parent", [:], [.element("child", [:], [.element("subchild", [:], []), .text("aha feest")])])])
    }
    
    func testContentWithText() throws {
        let test = "hee text<Derp/>"
        let (result, rest) = xmlBody.parse(test[...].utf8)
        XCTAssertNoDifference(rest.count, 0)
        XCTAssertNoDifference(result, [XML.text("hee text"), .element("Derp", [:], [])])
    }
    
    func testInline() throws {
        let test = "<parent><child>derp<subchild/>aha feest</child></parent>"

        let (result, rest) = xmlBody.parse(test[...].utf8)
        XCTAssertNoDifference(rest.count, 0)
        XCTAssertNoDifference(result, [XML.element("parent", [:], [.element("child", [:], [.text("derp"), .element("subchild", [:], []), .text("aha feest")])])])
    }
    
    
    func testThingPLSRENAME() throws {
        let test = "<strong>ja</strong> man"
        let (result, rest) = xmlBody.parse(test[...].utf8)
        XCTAssertNoDifference(rest.count, 0)
        XCTAssertNoDifference(result, [.element("strong", [:], [.text("ja")]), .text(" man")])
    }
    
    func testBigTest() throws {
        let test = """
        <?xml version="1.0" encoding="utf-8"?>
        <edmx:Edmx Version="4.0" xmlns:edmx="http://docs.oasis-open.org/odata/ns/edmx">
            <edmx:DataServices>
                <Schema Namespace="microsoft.graph" Alias="graph" xmlns="http://docs.oasis-open.org/odata/ns/edm">
                    <EnumType Name="appliedConditionalAccessPolicyResult">
                        <Member Name="success" Value="0"/>
                        <Member Name="failure" Value="1"/>
                        <Member Name="notApplied" Value="2"/>
                        <Member Name="notEnabled" Value="3"/>
                        <Member Name="unknown" Value="4"/>
                        <Member Name="unknownFutureValue" Value="5"/>
                    </EnumType>
                    <EntityType Name="entity" Abstract="true">
                        <Key>
                            <PropertyRef Name="id"/>
                        </Key>
                        <Property Name="id" Type="Edm.String" Nullable="false"/>
                    </EntityType>
                    <ComplexType Name="appIdentity">
                        <Property Name="appId" Type="Edm.String"/>
                        <Property Name="displayName" Type="Edm.String"/>
                        <Property Name="servicePrincipalId" Type="Edm.String"/>
                        <Property Name="servicePrincipalName" Type="Edm.String"/>
                    </ComplexType>
                    <Function Name="getAllMessages" IsBound="true" EntitySetPath="bindingParameter/channels/messages">
                        <Parameter Name="bindingParameter" Type="Collection(graph.team)"/>
                        <ReturnType Type="Collection(graph.chatMessage)"/>
                    </Function>
                    <Action Name="approve" IsBound="true">
                        <Parameter Name="bindingParameter" Type="graph.scheduleChangeRequest"/>
                        <Parameter Name="message" Type="Edm.String" Unicode="false"/>
                    </Action>
                    <Action Name="share" IsBound="true">
                        <Parameter Name="bindingParameter" Type="graph.schedule"/>
                        <Parameter Name="notifyTeam" Type="Edm.Boolean"/>
                        <Parameter Name="startDateTime" Type="Edm.DateTimeOffset"/>
                        <Parameter Name="endDateTime" Type="Edm.DateTimeOffset"/>
                    </Action>
                    <EntityContainer Name="GraphService">
                        <EntitySet Name="invitations" EntityType="microsoft.graph.invitation">
                            <NavigationPropertyBinding Path="invitedUser" Target="users"/>
                        </EntitySet>
                        <EntitySet Name="users" EntityType="microsoft.graph.user">
                            <NavigationPropertyBinding Path="createdObjects" Target="directoryObjects"/>
                            <NavigationPropertyBinding Path="directReports" Target="directoryObjects"/>
                            <NavigationPropertyBinding Path="manager" Target="directoryObjects"/>
                            <NavigationPropertyBinding Path="memberOf" Target="directoryObjects"/>
                            <NavigationPropertyBinding Path="ownedDevices" Target="directoryObjects"/>
                            <NavigationPropertyBinding Path="ownedObjects" Target="directoryObjects"/>
                            <NavigationPropertyBinding Path="registeredDevices" Target="directoryObjects"/>
                            <NavigationPropertyBinding Path="transitiveMemberOf" Target="directoryObjects"/>
                        </EntitySet>
                        <EntitySet Name="applicationTemplates" EntityType="microsoft.graph.applicationTemplate"/>
                        <EntitySet Name="authenticationMethodConfigurations" EntityType="microsoft.graph.authenticationMethodConfiguration"/>
                        <EntitySet Name="identityProviders" EntityType="microsoft.graph.identityProvider"/>
                        <EntitySet Name="applications" EntityType="microsoft.graph.application">
                            <NavigationPropertyBinding Path="createdOnBehalfOf" Target="directoryObjects"/>
                            <NavigationPropertyBinding Path="owners" Target="directoryObjects"/>
                        </EntitySet>
                        <EntitySet Name="certificateBasedAuthConfiguration" EntityType="microsoft.graph.certificateBasedAuthConfiguration"/>
                        <EntitySet Name="contacts" EntityType="microsoft.graph.orgContact">
                            <NavigationPropertyBinding Path="directReports" Target="directoryObjects"/>
                            <NavigationPropertyBinding Path="manager" Target="directoryObjects"/>
                            <NavigationPropertyBinding Path="memberOf" Target="directoryObjects"/>
                            <NavigationPropertyBinding Path="transitiveMemberOf" Target="directoryObjects"/>
                        </EntitySet>
                        <EntitySet Name="contracts" EntityType="microsoft.graph.contract"/>
                        <EntitySet Name="devices" EntityType="microsoft.graph.device">
                            <NavigationPropertyBinding Path="registeredOwners" Target="directoryObjects"/>
                            <NavigationPropertyBinding Path="registeredUsers" Target="directoryObjects"/>
                            <NavigationPropertyBinding Path="transitiveMemberOf" Target="directoryObjects"/>
                        </EntitySet>
                        <EntitySet Name="directoryObjects" EntityType="microsoft.graph.directoryObject"/>
                        <EntitySet Name="directoryRoles" EntityType="microsoft.graph.directoryRole">
                            <NavigationPropertyBinding Path="members" Target="directoryObjects"/>
                        </EntitySet>
                        <EntitySet Name="directoryRoleTemplates" EntityType="microsoft.graph.directoryRoleTemplate"/>
                        <EntitySet Name="domainDnsRecords" EntityType="microsoft.graph.domainDnsRecord"/>
                        <EntitySet Name="domains" EntityType="microsoft.graph.domain">
                            <NavigationPropertyBinding Path="domainNameReferences" Target="directoryObjects"/>
                        </EntitySet>
                        <EntitySet Name="groups" EntityType="microsoft.graph.group">
                            <NavigationPropertyBinding Path="createdOnBehalfOf" Target="directoryObjects"/>
                            <NavigationPropertyBinding Path="memberOf" Target="directoryObjects"/>
                            <NavigationPropertyBinding Path="members" Target="directoryObjects"/>
                            <NavigationPropertyBinding Path="owners" Target="directoryObjects"/>
                            <NavigationPropertyBinding Path="transitiveMemberOf" Target="directoryObjects"/>
                            <NavigationPropertyBinding Path="transitiveMembers" Target="directoryObjects"/>
                        </EntitySet>
                        <EntitySet Name="groupSettings" EntityType="microsoft.graph.groupSetting"/>
                        <EntitySet Name="groupSettingTemplates" EntityType="microsoft.graph.groupSettingTemplate"/>
                        <EntitySet Name="localizations" EntityType="microsoft.graph.organizationalBrandingLocalization"/>
                        <EntitySet Name="oauth2PermissionGrants" EntityType="microsoft.graph.oAuth2PermissionGrant"/>
                        <EntitySet Name="organization" EntityType="microsoft.graph.organization">
                            <NavigationPropertyBinding Path="certificateBasedAuthConfiguration" Target="certificateBasedAuthConfiguration"/>
                        </EntitySet>
                        <EntitySet Name="permissionGrants" EntityType="microsoft.graph.resourceSpecificPermissionGrant"/>
                        <EntitySet Name="scopedRoleMemberships" EntityType="microsoft.graph.scopedRoleMembership"/>
                        <EntitySet Name="servicePrincipals" EntityType="microsoft.graph.servicePrincipal">
                            <NavigationPropertyBinding Path="createdObjects" Target="directoryObjects"/>
                            <NavigationPropertyBinding Path="memberOf" Target="directoryObjects"/>
                            <NavigationPropertyBinding Path="oauth2PermissionGrants" Target="oauth2PermissionGrants"/>
                            <NavigationPropertyBinding Path="ownedObjects" Target="directoryObjects"/>
                            <NavigationPropertyBinding Path="owners" Target="directoryObjects"/>
                            <NavigationPropertyBinding Path="transitiveMemberOf" Target="directoryObjects"/>
                        </EntitySet>
                        <EntitySet Name="subscribedSkus" EntityType="microsoft.graph.subscribedSku"/>
                        <EntitySet Name="places" EntityType="microsoft.graph.place"/>
                        <EntitySet Name="drives" EntityType="microsoft.graph.drive"/>
                        <EntitySet Name="shares" EntityType="microsoft.graph.sharedDriveItem"/>
                        <EntitySet Name="sites" EntityType="microsoft.graph.site">
                            <NavigationPropertyBinding Path="sites/contentTypes/columns/term/parentTerm" Target="sites/termStore/sets/terms"/>
                            <NavigationPropertyBinding Path="sites/contentTypes/columns/term/termSet" Target="sites/termStore/sets"/>
                            <NavigationPropertyBinding Path="sites/contentTypes/documentSet/sharedColumns" Target="sites/contentTypes/columns"/>
                            <NavigationPropertyBinding Path="sites/contentTypes/documentSet/welcomePageColumns" Target="sites/contentTypes/columns"/>
                        </EntitySet>
                        <EntitySet Name="schemaExtensions" EntityType="microsoft.graph.schemaExtension"/>
                        <EntitySet Name="groupLifecyclePolicies" EntityType="microsoft.graph.groupLifecyclePolicy"/>
                        <EntitySet Name="agreementAcceptances" EntityType="microsoft.graph.agreementAcceptance"/>
                        <EntitySet Name="agreements" EntityType="microsoft.graph.agreement"/>
                        <EntitySet Name="dataPolicyOperations" EntityType="microsoft.graph.dataPolicyOperation"/>
                        <EntitySet Name="subscriptions" EntityType="microsoft.graph.subscription"/>
                        <EntitySet Name="connections" EntityType="microsoft.graph.externalConnectors.externalConnection"/>
                        <EntitySet Name="chats" EntityType="microsoft.graph.chat"/>
                        <EntitySet Name="teams" EntityType="microsoft.graph.team">
                            <NavigationPropertyBinding Path="group" Target="groups"/>
                            <NavigationPropertyBinding Path="template" Target="teamsTemplates"/>
                        </EntitySet>
                        <EntitySet Name="teamsTemplates" EntityType="microsoft.graph.teamsTemplate"/>
                        <Singleton Name="auditLogs" Type="microsoft.graph.auditLogRoot"/>
                        <Singleton Name="authenticationMethodsPolicy" Type="microsoft.graph.authenticationMethodsPolicy"/>
                        <Singleton Name="compliance" Type="microsoft.graph.compliance"/>
                        <Singleton Name="identity" Type="microsoft.graph.identityContainer"/>
                        <Singleton Name="branding" Type="microsoft.graph.organizationalBranding"/>
                        <Singleton Name="directory" Type="microsoft.graph.directory"/>
                        <Singleton Name="me" Type="microsoft.graph.user">
                            <NavigationPropertyBinding Path="createdObjects" Target="directoryObjects"/>
                            <NavigationPropertyBinding Path="directReports" Target="directoryObjects"/>
                            <NavigationPropertyBinding Path="manager" Target="directoryObjects"/>
                            <NavigationPropertyBinding Path="memberOf" Target="directoryObjects"/>
                            <NavigationPropertyBinding Path="ownedDevices" Target="directoryObjects"/>
                            <NavigationPropertyBinding Path="ownedObjects" Target="directoryObjects"/>
                            <NavigationPropertyBinding Path="registeredDevices" Target="directoryObjects"/>
                            <NavigationPropertyBinding Path="transitiveMemberOf" Target="directoryObjects"/>
                        </Singleton>
                        <Singleton Name="policies" Type="microsoft.graph.policyRoot"/>
                        <Singleton Name="education" Type="microsoft.graph.educationRoot">
                            <NavigationPropertyBinding Path="classes/group" Target="directoryObjects"/>
                            <NavigationPropertyBinding Path="classes/members" Target="education/users"/>
                            <NavigationPropertyBinding Path="classes/schools" Target="education/schools"/>
                            <NavigationPropertyBinding Path="classes/teachers" Target="education/users"/>
                            <NavigationPropertyBinding Path="me/classes" Target="education/classes"/>
                            <NavigationPropertyBinding Path="me/schools" Target="education/schools"/>
                            <NavigationPropertyBinding Path="me/taughtClasses" Target="education/classes"/>
                            <NavigationPropertyBinding Path="me/user" Target="directoryObjects"/>
                            <NavigationPropertyBinding Path="schools/administrativeUnit" Target="directoryObjects"/>
                            <NavigationPropertyBinding Path="schools/classes" Target="education/classes"/>
                            <NavigationPropertyBinding Path="schools/users" Target="education/users"/>
                            <NavigationPropertyBinding Path="users/classes" Target="education/classes"/>
                            <NavigationPropertyBinding Path="users/schools" Target="education/schools"/>
                            <NavigationPropertyBinding Path="users/taughtClasses" Target="education/classes"/>
                            <NavigationPropertyBinding Path="users/user" Target="directoryObjects"/>
                        </Singleton>
                        <Singleton Name="roleManagement" Type="microsoft.graph.roleManagement"/>
                        <Singleton Name="drive" Type="microsoft.graph.drive"/>
                        <Singleton Name="communications" Type="microsoft.graph.cloudCommunications"/>
                        <Singleton Name="identityGovernance" Type="microsoft.graph.identityGovernance"/>
                        <Singleton Name="deviceAppManagement" Type="microsoft.graph.deviceAppManagement"/>
                        <Singleton Name="deviceManagement" Type="microsoft.graph.deviceManagement"/>
                        <Singleton Name="reports" Type="microsoft.graph.reportRoot"/>
                        <Singleton Name="admin" Type="microsoft.graph.admin"/>
                        <Singleton Name="search" Type="microsoft.graph.searchEntity"/>
                        <Singleton Name="planner" Type="microsoft.graph.planner">
                            <NavigationPropertyBinding Path="buckets/tasks" Target="planner/tasks"/>
                            <NavigationPropertyBinding Path="plans/buckets" Target="planner/buckets"/>
                            <NavigationPropertyBinding Path="plans/tasks" Target="planner/tasks"/>
                        </Singleton>
                        <Singleton Name="print" Type="microsoft.graph.print"/>
                        <Singleton Name="security" Type="microsoft.graph.security"/>
                        <Singleton Name="external" Type="microsoft.graph.externalConnectors.external"/>
                        <Singleton Name="appCatalogs" Type="microsoft.graph.appCatalogs"/>
                        <Singleton Name="teamwork" Type="microsoft.graph.teamwork"/>
                        <Singleton Name="informationProtection" Type="microsoft.graph.informationProtection"/>
                    </EntityContainer>
                    <Annotations Target="microsoft.graph.installIntent">
                        <Annotation Term="Org.OData.Core.V1.Description" String="Possible values for the install intent chosen by the admin."/>
                    </Annotations>
                </Schema>
            </edmx:DataServices>
        </edmx:Edmx>
        """
        XCTAssertNotNil(xml.parse(test))
    }
    
    func testTags() throws {
        XCTAssertNotNil(xml.parse(biggerExample))
    }
}
