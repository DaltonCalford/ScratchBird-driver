import 'package:test/test.dart';
import 'package:scratchbird/src/types.dart';

void main() {
  test('array literal round-trip (binary unknown)', () {
    final encoded = encodeParam([1, 2, 3]);
    final decoded = decodeValue(0, encoded.param.data!, 1);
    expect(decoded, equals([1, 2, 3]));
  });

  test('vector literal round-trip', () {
    final encoded = encodeParam([1.0, 2.5, 3.25]);
    expect(encoded.oid, equals(oidVector));
    final decoded =
        decodeValue(oidVector, encoded.param.data!, 1) as List<dynamic>;
    expect(decoded.length, equals(3));
    expect(decoded[0], closeTo(1.0, 0.00001));
    expect(decoded[1], closeTo(2.5, 0.00001));
    expect(decoded[2], closeTo(3.25, 0.00001));
  });

  test('range round-trip (int4range)', () {
    final range = ScratchBirdRange<int>(
      lower: 1,
      upper: 10,
      lowerInclusive: true,
      upperInclusive: false,
      rangeOid: oidInt4Range,
    );
    final encoded = encodeParam(range);
    expect(encoded.oid, equals(oidInt4Range));
    final decoded =
        decodeValue(encoded.oid, encoded.param.data!, 1) as ScratchBirdRange;
    expect(decoded.lower, equals(1));
    expect(decoded.upper, equals(10));
    expect(decoded.lowerInclusive, isTrue);
    expect(decoded.upperInclusive, isFalse);
    expect(decoded.empty, isFalse);
  });

  test('composite round-trip', () {
    final comp = ScratchBirdComposite(fields: [
      ScratchBirdCompositeField(oid: oidInt4, value: 7),
      ScratchBirdCompositeField(oid: oidText, value: "hello"),
    ]);
    final encoded = encodeParam(comp);
    expect(encoded.oid, equals(oidRecord));
    final decoded =
        decodeValue(oidRecord, encoded.param.data!, 1) as ScratchBirdComposite;
    expect(decoded.fields.length, equals(2));
    expect(decoded.fields[0].value, equals(7));
    expect(decoded.fields[1].value, equals("hello"));
  });

  test('inet/cidr/macaddr round-trip', () {
    final inet = ScratchBirdInet("127.0.0.1");
    final cidr = ScratchBirdCidr("10.0.0.0/24");
    final mac = ScratchBirdMacaddr("aa:bb:cc:dd:ee:ff");

    final inetEnc = encodeParam(inet);
    final cidrEnc = encodeParam(cidr);
    final macEnc = encodeParam(mac);

    expect(decodeValue(oidInet, inetEnc.param.data!, 1), equals("127.0.0.1"));
    expect(decodeValue(oidCidr, cidrEnc.param.data!, 1), equals("10.0.0.0/24"));
    expect(decodeValue(oidMacaddr, macEnc.param.data!, 1),
        equals("aa:bb:cc:dd:ee:ff"));
  });
}
