import XCTest
@testable import ScratchBird

final class TypeMappingTests: XCTestCase {
    func testVectorRoundTrip() throws {
        let encoded = try encodeParam([1.0, 2.5, 3.25])
        XCTAssertEqual(encoded.oid, TypeOid.sbVector)
        let decoded = decodeValue(oid: TypeOid.sbVector, data: encoded.param.data ?? Data(), format: 1)
        guard let values = decoded as? [Double] else {
            XCTFail("Expected vector decode to [Double]")
            return
        }
        XCTAssertEqual(values.count, 3)
        XCTAssertEqual(values[0], 1.0, accuracy: 0.00001)
        XCTAssertEqual(values[1], 2.5, accuracy: 0.00001)
        XCTAssertEqual(values[2], 3.25, accuracy: 0.00001)
    }

    func testArrayRoundTrip() throws {
        let encoded = try encodeParam([1, 2, 3])
        let decoded = decodeValue(oid: 0, data: encoded.param.data ?? Data(), format: 1)
        guard let values = decoded as? [Any] else {
            XCTFail("Expected array decode to [Any]")
            return
        }
        let ints = values.compactMap { $0 as? Int }
        XCTAssertEqual(ints, [1, 2, 3])
    }

    func testRangeRoundTrip() throws {
        var range = ScratchBirdRange(lower: 1, upper: 10, lowerInclusive: true, upperInclusive: false)
        range.rangeOid = TypeOid.int4range
        let encoded = try encodeParam(range)
        XCTAssertEqual(encoded.oid, TypeOid.int4range)
        guard let decoded = decodeValue(oid: TypeOid.int4range, data: encoded.param.data ?? Data(), format: 1) as? ScratchBirdRange else {
            XCTFail("Expected range decode to ScratchBirdRange")
            return
        }
        XCTAssertEqual(decoded.lower as? Int, 1)
        XCTAssertEqual(decoded.upper as? Int, 10)
        XCTAssertTrue(decoded.lowerInclusive)
        XCTAssertFalse(decoded.upperInclusive)
        XCTAssertFalse(decoded.empty)
    }

    func testCompositeRoundTrip() throws {
        let comp = ScratchBirdComposite(fields: [
            ScratchBirdCompositeField(oid: TypeOid.int4, value: 7, raw: nil),
            ScratchBirdCompositeField(oid: TypeOid.text, value: "hello", raw: nil),
        ])
        let encoded = try encodeParam(comp)
        XCTAssertEqual(encoded.oid, TypeOid.record)
        guard let decoded = decodeValue(oid: TypeOid.record, data: encoded.param.data ?? Data(), format: 1) as? ScratchBirdComposite else {
            XCTFail("Expected composite decode to ScratchBirdComposite")
            return
        }
        XCTAssertEqual(decoded.fields.count, 2)
        XCTAssertEqual(decoded.fields[0].value as? Int, 7)
        XCTAssertEqual(decoded.fields[1].value as? String, "hello")
    }

    func testInetCidrMacaddrRoundTrip() throws {
        let inet = ScratchBirdInet(value: "127.0.0.1")
        let cidr = ScratchBirdCidr(value: "10.0.0.0/24")
        let mac = ScratchBirdMacaddr(value: "aa:bb:cc:dd:ee:ff")

        let inetEnc = try encodeParam(inet)
        let cidrEnc = try encodeParam(cidr)
        let macEnc = try encodeParam(mac)

        XCTAssertEqual(decodeValue(oid: TypeOid.inet, data: inetEnc.param.data ?? Data(), format: 1) as? String, "127.0.0.1")
        XCTAssertEqual(decodeValue(oid: TypeOid.cidr, data: cidrEnc.param.data ?? Data(), format: 1) as? String, "10.0.0.0/24")
        XCTAssertEqual(decodeValue(oid: TypeOid.macaddr, data: macEnc.param.data ?? Data(), format: 1) as? String, "aa:bb:cc:dd:ee:ff")
    }
}
