<?php
/*
 * ScratchBird-driver
 * Copyright (c) 2025-2026 Dalton Calford
 *
 * Licensed under the Initial Developer's Public License Version 1.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at:
 * https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
 */

require_once __DIR__ . '/bootstrap.php';

use PHPUnit\Framework\TestCase;
use ScratchBird\PDO\Composite;
use ScratchBird\PDO\CompositeField;
use ScratchBird\PDO\Geometry;
use ScratchBird\PDO\Jsonb;
use ScratchBird\PDO\Range;
use ScratchBird\PDO\TypeDecoder;

final class TypeDecoderTest extends TestCase
{
    public function testEncodeParamCoversRepresentativeScalarAndStructuredInputs(): void
    {
        $bool = TypeDecoder::encodeParam(true);
        $this->assertSame(TypeDecoder::OID_BOOL, $bool['oid']);
        $this->assertSame("\1", $bool['param']['data']);

        $int4 = TypeDecoder::encodeParam(42);
        $this->assertSame(TypeDecoder::OID_INT4, $int4['oid']);
        $this->assertSame(42, unpack('V', $int4['param']['data'])[1]);

        $int8 = TypeDecoder::encodeParam(2147483648);
        $this->assertSame(TypeDecoder::OID_INT8, $int8['oid']);
        $this->assertSame(8, strlen($int8['param']['data']));

        $json = TypeDecoder::encodeParam((object)['role' => 'admin', 'active' => true]);
        $this->assertSame(TypeDecoder::OID_JSON, $json['oid']);
        $this->assertGreaterThan(4, strlen($json['param']['data']));

        $vector = TypeDecoder::encodeParam([1, 2, 3]);
        $this->assertSame(TypeDecoder::OID_SB_VECTOR, $vector['oid']);
        $this->assertSame('[1,2,3]', substr($vector['param']['data'], 4));
    }

    public function testEncodeParamRejectsInvalidInputs(): void
    {
        $this->expectException(\InvalidArgumentException::class);
        $this->expectExceptionMessage('JSONB requires raw payload');
        TypeDecoder::encodeParam(new Jsonb(''));
    }

    public function testEncodeParamRejectsInvalidGeometryAndUnsupportedType(): void
    {
        try {
            TypeDecoder::encodeParam(new Geometry(''));
            $this->fail('Expected geometry encode to fail');
        } catch (\InvalidArgumentException $ex) {
            $this->assertStringContainsString('geometry requires WKB payload', $ex->getMessage());
        }

        $resource = tmpfile();
        try {
            TypeDecoder::encodeParam($resource);
            $this->fail('Expected resource encode to fail');
        } catch (\InvalidArgumentException $ex) {
            $this->assertStringContainsString('Unsupported parameter type', $ex->getMessage());
        } finally {
            if (is_resource($resource)) {
                fclose($resource);
            }
        }
    }

    public function testDecodeRepresentativeBinaryValues(): void
    {
        $numeric = TypeDecoder::decode(TypeDecoder::OID_NUMERIC, $this->lenPrefixed('12345.678'), TypeDecoder::FORMAT_BINARY);
        $this->assertSame('12345.678', $numeric);

        $money = TypeDecoder::decode(TypeDecoder::OID_MONEY, pack('V2', 12345, 0), TypeDecoder::FORMAT_BINARY);
        $this->assertSame('123.45', $money);

        $uuid = TypeDecoder::decode(TypeDecoder::OID_UUID, hex2bin('00112233445566778899aabbccddeeff'), TypeDecoder::FORMAT_BINARY);
        $this->assertSame('00112233-4455-6677-8899-aabbccddeeff', $uuid);

        $jsonb = TypeDecoder::decode(TypeDecoder::OID_JSONB, $this->lenPrefixed('{"k":1}'), TypeDecoder::FORMAT_BINARY);
        $this->assertInstanceOf(Jsonb::class, $jsonb);
        $this->assertSame('{"k":1}', $jsonb->raw);

        $vector = TypeDecoder::decode(TypeDecoder::OID_SB_VECTOR, $this->lenPrefixed('[0.5,1.5,2.5]'), TypeDecoder::FORMAT_BINARY);
        $this->assertSame([0.5, 1.5, 2.5], $vector);
    }

    public function testDecodeRangeAndCompositePayloads(): void
    {
        $rangePayload = pack('C4', 0, 0, 0, 0)
            . pack('V', 8) . pack('V2', 10, 0)
            . pack('V', 8) . pack('V2', 20, 0);
        $range = TypeDecoder::decode(TypeDecoder::OID_INT8RANGE, $rangePayload, TypeDecoder::FORMAT_BINARY);
        $this->assertInstanceOf(Range::class, $range);
        $this->assertSame(10, $range->lower);
        $this->assertSame(20, $range->upper);
        $this->assertFalse($range->empty);

        $compositePayload = pack('V', 1)
            . pack('V', TypeDecoder::OID_INT4)
            . pack('V', 4)
            . pack('V', 77);
        $composite = TypeDecoder::decode(TypeDecoder::OID_RECORD, $compositePayload, TypeDecoder::FORMAT_BINARY);
        $this->assertInstanceOf(Composite::class, $composite);
        $this->assertCount(1, $composite->fields);
        $this->assertInstanceOf(CompositeField::class, $composite->fields[0]);
        $this->assertSame(TypeDecoder::OID_INT4, $composite->fields[0]->oid);
        $this->assertSame(77, $composite->fields[0]->value);
    }

    public function testDecodeUnknownTypeHeuristicsForTextAndBinary(): void
    {
        $this->assertTrue(TypeDecoder::decode(0, 'true', TypeDecoder::FORMAT_TEXT));
        $this->assertSame(42, TypeDecoder::decode(0, '42', TypeDecoder::FORMAT_TEXT));
        $this->assertSame(12.5, TypeDecoder::decode(0, '12.5', TypeDecoder::FORMAT_TEXT));

        $binaryInt = pack('V', 321);
        $this->assertSame(321, TypeDecoder::decode(0, $binaryInt, TypeDecoder::FORMAT_BINARY));
    }

    private function lenPrefixed(string $value): string
    {
        return pack('V', strlen($value)) . $value;
    }
}
