// Created by Nejc Skerjanc, copyright © 2023 ZeroPass. All rights reserved.

import 'package:dmrtd/src/proto/dh_pace.dart';
import 'package:dmrtd/src/proto/ecdh_pace.dart';
import 'package:pointycastle/asn1/primitives/asn1_integer.dart';
import 'package:pointycastle/asn1/primitives/asn1_sequence.dart';
import 'package:pointycastle/asn1/primitives/asn1_object_identifier.dart';

import '../asn1ObjectIdentifiers.dart';
import "package:dmrtd/src/extension/logging_apis.dart";
import 'package:logging/logging.dart';

import "package:dmrtd/src/lds/ef.dart";

///PACEInfo ::= SEQUENCE {
///      protocol OBJECT IDENTIFIER(
///                  id-PACE-DH-GM-3DES-CBC-CBC |
///                  id-PACE-DH-GM-AES-CBC-CMAC-128 |
///                  id-PACE-DH-GM-AES-CBC-CMAC-192 |
///                  id-PACE-DH-GM-AES-CBC-CMAC-256 |
///                  id-PACE-ECDH-GM-3DES-CBC-CBC |
///                  id-PACE-ECDH-GM-AES-CBC-CMAC-128 |
///                  id-PACE-ECDH-GM-AES-CBC-CMAC-192 |
///                  id-PACE-ECDH-GM-AES-CBC-CMAC-256 |
///                  id-PACE-DH-IM-3DES-CBC-CBC |
///                  id-PACE-DH-IM-AES-CBC-CMAC-128 |
///                  id-PACE-DH-IM-AES-CBC-CMAC-192 |
///                  id-PACE-DH-IM-AES-CBC-CMAC-256 |
///                  id-PACE-ECDH-IM-3DES-CBC-CBC |
///                  id-PACE-ECDH-IM-AES-CBC-CMAC-128 |
///                  id-PACE-ECDH-IM-AES-CBC-CMAC-192 |
///                  id-PACE-ECDH-IM-AES-CBC-CMAC-256 |
///                  id-PACE-ECDH-CAM-AES-CBC-CMAC-128 |
///                  id-PACE-ECDH-CAM-AES-CBC-CMAC-192 |
///                  id-PACE-ECDH-CAM-AES-CBC-CMAC-256),
///      version INTEGER, -- MUST be 2
///      parameterId INTEGER OPTIONAL
///}

int VERSION_VALUE_CONST = 2;

class PaceInfo {
  late OIEPaceProtocol _protocol;
  late int _version;
  int? _parameterId;

  bool _isPaceDomainParameterSupported = false;

  final _log = Logger("PaceInfo");

  OIEPaceProtocol get protocol => _protocol;
  int get version => _version;

  bool get isParameterSet => _parameterId != null;
  int? get parameterId => _parameterId;

  bool get isPaceDomainParameterSupported => _isPaceDomainParameterSupported;

  PaceInfo({required ASN1Sequence content}) {
    _log.debug("PaceInfo constructor");
    ASN1ObjectIdentifierType? protocolType = ASN1ObjectIdentifierType.instance;
    parse(content: content, protocolType: protocolType);
  }

  String toString() {
    return "PaceInfo(protocol: $_protocol, version: $_version, "
        "parameterId: $_parameterId, isPaceDomainParameterSupported: $_isPaceDomainParameterSupported)";
  }

  void parse(
      {required ASN1Sequence content,
      required ASN1ObjectIdentifierType protocolType}) {
    _log.info("Parsing PaceInfo...");
    _log.sdDebug("Data: $content");

    // parameterId is OPTIONAL per the ASN.1 spec, so at least 2 elements
    // (protocol and version) are required.
    if (content.elements == null || content.elements!.length < 2) {
      _log.error("Invalid structure of PaceInfo. Less than 2 elements in set.");
      throw EfParseError(
          "Invalid structure of PaceInfo. Less than 2 elements in set.");
    }

    //
    // parsing protocol
    //

    _log.info("... parsing protocol ...");
    if (content.elements![0] is! ASN1ObjectIdentifier) {
      _log.error(
          "Invalid structure of PaceInfo. Protocol is not ASN1ObjectIdentifier.");
      throw EfParseError(
          "Invalid structure of PaceInfo. Protocol is not ASN1ObjectIdentifier.");
    }
    ASN1ObjectIdentifier protocol =
        content.elements![0] as ASN1ObjectIdentifier;

    final String? protocolOID = protocol.objectIdentifierAsString;
    if (protocolOID == null) {
      _log.error("Invalid protocol in PaceInfo. Protocol OID is null.");
      throw EfParseError("Invalid protocol in PaceInfo. Protocol OID is null.");
    }

    if (!protocolType.hasOIDWithIdentifierString(
        identifierString: protocolOID)) {
      _log.sdError(
          "Invalid protocol in PaceInfo. Protocol is not valid: $protocolOID");
      throw EfParseError(
          "Invalid protocol in PaceInfo. Protocol is not valid: $protocolOID");
    }
    _protocol = OIEPaceProtocol.fromMap(
        item: protocolType.getOIDByIdentifierString(
            identifierString: protocolOID));
    _log.info("... protocol parsed ...");
    _log.sdDebug("Protocol: $protocol");

    //
    // parsing version
    //

    _log.info("... parsing version ...");
    if (content.elements![1] is! ASN1Integer) {
      _log.error("Invalid structure of PaceInfo. Version is not ASN1Integer.");
      throw EfParseError(
          "Invalid structure of PaceInfo. Version is not ASN1Integer.");
    }
    ASN1Integer version = content.elements![1] as ASN1Integer;
    if (version.integer == null) {
      _log.error("Invalid version in PaceInfo. Version is null.");
      throw EfParseError("Invalid version in PaceInfo. Version is null.");
    }
    if (version.integer?.toInt() != VERSION_VALUE_CONST) {
      _log.error(
          "Invalid version in PaceInfo. Version is not equal to $VERSION_VALUE_CONST.");
      throw EfParseError(
          "Invalid version in PaceInfo. Version is not equal to $VERSION_VALUE_CONST.");
    }

    _version = version.integer!.toInt();
    _log.info("... version parsed ...");
    _log.sdDebug("Version: $version");

    //
    // parsing parameterId (OPTIONAL)
    //

    _log.info("... parsing parameterId ...");
    if (content.elements!.length > 2) {
      if (content.elements![2] is! ASN1Integer) {
        _log.error(
            "Invalid structure of PaceInfo. ParameterId is not ASN1Integer.");
        throw EfParseError(
            "Invalid structure of PaceInfo. ParameterId is not ASN1Integer.");
      }
      ASN1Integer parameterId = content.elements![2] as ASN1Integer;
      if (parameterId.integer == null) {
        _log.error("Invalid parameterId in PaceInfo. ParameterId is null.");
        throw EfParseError(
            "Invalid parameterId in PaceInfo. ParameterId is null.");
      }

      _parameterId = parameterId.integer!.toInt();

      // checking if domain parameter is supported

      try {
        //check if DomainParameterSelectorEC(DH) raises exception
        if (_protocol.tokenAgreementAlgorithm == TOKEN_AGREEMENT_ALGO.ECDH)
          DomainParameterSelectorECDH.getDomainParameter(id: _parameterId!);
        else
          DomainParameterSelectorDH.getDomainParameter(id: _parameterId!);

        _isPaceDomainParameterSupported = true;
      } catch (e) {
        // we do not raise exception, because we can use paceInfo for
        // other purposes - not only for PACE
        _log.error("Token agreement algorithm not supported. Exception: $e");
        _log.debug(
            "Token agreement algorithm '${_protocol.tokenAgreementAlgorithm}'"
            " with domain parameterId '$_parameterId' is not supported.");
        _isPaceDomainParameterSupported = false;
      }

      _log.info("... parameterId parsed ...");
      _log.sdDebug("ParameterId: $parameterId");
    } else {
      _parameterId = null;
      _isPaceDomainParameterSupported = false;
      _log.info("... parameterId not present (optional) ...");
    }

    _log.info("... paceInfo successfully parsed.");
  }

  String getMappingType() {
    // Either GM, CAM, or IM.
    return ""; //_protocol.mappingType;
  }
}
