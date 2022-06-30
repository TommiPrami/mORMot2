/// regression tests for RESTful ORM over Http or WebSockets
// - this unit is a part of the Open Source Synopse mORMot framework 2,
// licensed under a MPL/GPL/LGPL three license - see LICENSE.md
unit test.orm.network;

interface

{$I ..\src\mormot.defines.inc}

uses
  sysutils,
  contnrs,
  classes,
  mormot.core.base,
  mormot.core.os,
  mormot.core.text,
  mormot.core.buffers,
  mormot.core.unicode,
  mormot.core.datetime,
  mormot.core.rtti,
  mormot.crypt.core,
  mormot.core.data,
  mormot.core.variants,
  mormot.core.json,
  mormot.core.log,
  mormot.core.perf,
  mormot.core.search,
  mormot.core.mustache,
  mormot.core.test,
  mormot.core.interfaces,
  mormot.crypt.secure,
  mormot.crypt.jwt,
  mormot.net.client,
  mormot.net.server,
  mormot.net.relay,
  mormot.net.ws.core,
  mormot.net.ws.client,
  mormot.net.ws.server,
  mormot.db.core,
  mormot.db.nosql.bson,
  mormot.orm.base,
  mormot.orm.core,
  mormot.orm.rest,
  mormot.orm.storage,
  mormot.orm.sqlite3,
  mormot.orm.client,
  mormot.orm.server,
  mormot.soa.core,
  mormot.soa.server,
  mormot.rest.core,
  mormot.rest.client,
  mormot.rest.server,
  mormot.rest.memserver,
  mormot.rest.sqlite3,
  mormot.rest.http.client,
  mormot.rest.http.server,
  mormot.db.raw.sqlite3,
  mormot.db.raw.sqlite3.static,
  test.core.data,
  test.core.base,
  test.orm.core,
  test.orm.sqlite3;

type
  /// this test case will test most functions, classes and types defined and
  // implemented in the mORMotSQLite3 unit, i.e. the SQLite3 engine itself,
  // used as a HTTP/1.1 server and client
  // - test a HTTP/1.1 server and client on the port 888 of the local machine
  // - require the 'test.db3' SQLite3 database file, as created by TTestFileBased
  TTestClientServerAccess = class(TSynTestCase)
  protected
    { these values are used internally by the published methods below }
    Model: TOrmModel;
    DataBase: TRestServerDB;
    Server: TRestHttpServer;
    Client: TRestClientURI;
    fHttps: boolean;
    fHttpsKeyFile, fHttpsCertFile: TFileName;
    /// perform the tests of the current Client instance
    procedure ClientTest;
    /// release used instances (e.g. http server) and memory
    procedure CleanUp; override;
  public
    /// this could be called as administrator for THttpApiServer to work
    {$ifndef ONLYUSEHTTPSOCKET}
    class function RegisterAddUrl(OnlyDelete: boolean): string;
    {$endif ONLYUSEHTTPSOCKET}
  published
    /// initialize a TRestHttpServer instance
    // - uses the 'test.db3' SQLite3 database file generated by TTestSQLite3Engine
    // - creates and validates a HTTP/1.1 server on the port 888 of the local
    // machine, using the THttpApiServer (using kernel mode http.sys) class
    // if available
    procedure _TRestHttpServer;
    /// validate the HTTP/1.1 client implementation
    // - by using a request of all records data
    procedure _TRestHttpClient;
    /// validate the HTTP/1.1 client multi-query implementation with one
    // connection for the all queries
    // - this method keep alive the HTTP connection, so is somewhat faster
    // - it runs 1000 remote SQL queries, and check the JSON data retrieved
    // - the time elapsed for this step is computed, and displayed on the report
    procedure HttpClientKeepAlive;
    /// validate the HTTP/1.1 client multi-query implementation with one
    // connection initialized per query
    // - this method don't keep alive the HTTP connection, so is somewhat slower:
    // a new HTTP connection is created for every query
    // - it runs 1000 remote SQL queries, and check the JSON data retrieved
    // - the time elapsed for this step is computed, and displayed on the report
    procedure HttpClientMultiConnect;
    {$ifndef PUREMORMOT2}
    /// validate the HTTP/1.1 client multi-query implementation with one
    // connection for the all queries and our proprietary SHA-256 / AES-256-CTR
    // encryption encoding
    // - it runs 1000 remote SQL queries, and check the JSON data retrieved
    // - the time elapsed for this step is computed, and displayed on the report
    procedure HttpClientEncrypted;
    {$endif PUREMORMOT2}
    {$ifdef HASRESTCUSTOMENCRYPTION} // not fully safe -> not in mORMot 2
    /// validates TRest.SetCustomEncryption process with AES+SHA
    procedure HttpClientCustomEncryptionAesSha;
    /// validates TRest.SetCustomEncryption process with only AES
    procedure HttpClientCustomEncryptionAes;
    /// validates TRest.SetCustomEncryption process with only SHA
    procedure HttpClientCustomEncryptionSha;
    {$endif HASRESTCUSTOMENCRYPTION}
    {$ifdef OSWINDOWSTODO}
    /// validate the Named-Pipe client implementation
    // - it first launch the Server as Named-Pipe
    // - it then runs 1000 remote SQL queries, and check the JSON data retrieved
    // - the time elapsed for this step is computed, and displayed on the report
    procedure NamedPipeAccess;
    /// validate the Windows Windows Messages based client implementation
    // - it first launch the Server to handle Windows Messages
    // - it then runs 1000 remote SQL queries, and check the JSON data retrieved
    // - the time elapsed for this step is computed, and displayed on the report
    procedure LocalWindowMessages;
    {$endif OSWINDOWS}
    /// validate the HTTPS/1.1 server implementation
    procedure _TRestHttpsServer;
    /// validate the HTTPS/1.1 client implementation
    procedure _TRestHttpsClient;
    /// validate the HTTPS/1.1 client over one TLS connection
    procedure HttpsClientKeepAlive;
    /// validate the client implementation, using direct access to the server
    // - it connects directly the client to the server, therefore use the same
    // process and memory during the run: it's the fastest possible way of
    // communicating
    // - it then runs 1000 remote SQL queries, and check the JSON data retrieved
    // - the time elapsed for this step is computed, and displayed on the report
    procedure DirectInProcessAccess;
    /// validate HTTP/1.1 client-server with multiple TRestServer instances
    procedure HTTPSeveralDBServers;
  end;

const
  // some pre-computed CryptCertAlgoOpenSsl[caaRS256].New key for Windows
  PrivKeyCertPfx: array[0..2344] of byte = (
    $30, $82, $09, $25, $02, $01, $03, $30, $82, $08, $EF, $06, $09, $2A, $86, $48,
    $86, $F7, $0D, $01, $07, $01, $A0, $82, $08, $E0, $04, $82, $08, $DC, $30, $82,
    $08, $D8, $30, $82, $03, $8F, $06, $09, $2A, $86, $48, $86, $F7, $0D, $01, $07,
    $06, $A0, $82, $03, $80, $30, $82, $03, $7C, $02, $01, $00, $30, $82, $03, $75,
    $06, $09, $2A, $86, $48, $86, $F7, $0D, $01, $07, $01, $30, $1C, $06, $0A, $2A,
    $86, $48, $86, $F7, $0D, $01, $0C, $01, $06, $30, $0E, $04, $08, $28, $5B, $1C,
    $99, $A0, $68, $9E, $96, $02, $02, $08, $00, $80, $82, $03, $48, $75, $1A, $97,
    $22, $60, $63, $C1, $95, $B4, $12, $9D, $27, $E0, $B0, $8B, $59, $EC, $55, $9B,
    $C8, $60, $8E, $15, $EF, $18, $02, $52, $9A, $32, $0A, $C1, $29, $81, $C9, $56,
    $58, $53, $FC, $0D, $30, $FB, $80, $66, $57, $4E, $69, $5A, $02, $63, $A4, $F9,
    $78, $3F, $0C, $E1, $BC, $6F, $19, $D1, $29, $95, $AB, $7E, $97, $8A, $2B, $46,
    $D6, $3A, $13, $69, $50, $93, $A2, $9D, $82, $AA, $51, $EA, $7B, $3B, $57, $E2,
    $95, $9B, $5E, $96, $89, $0A, $51, $68, $8D, $55, $92, $93, $92, $31, $3B, $AB,
    $57, $6A, $8F, $2E, $95, $DE, $16, $66, $19, $71, $04, $AA, $A2, $6E, $82, $2B,
    $DE, $29, $AD, $F1, $C8, $48, $B6, $18, $43, $1E, $0B, $F5, $73, $D5, $D9, $3D,
    $3B, $B1, $91, $84, $4F, $76, $A3, $FB, $A4, $B3, $3F, $C0, $3D, $D7, $BF, $23,
    $17, $86, $E0, $06, $8B, $E8, $D9, $A4, $BC, $82, $71, $37, $76, $0F, $47, $C8,
    $47, $B3, $AB, $F8, $5E, $41, $26, $A0, $A1, $BB, $A6, $EB, $C9, $4B, $45, $6E,
    $39, $5A, $71, $32, $2E, $5C, $49, $38, $6D, $F6, $A2, $5A, $F0, $24, $0C, $CE,
    $7B, $33, $0A, $0E, $62, $82, $21, $82, $CF, $0D, $6A, $4D, $55, $17, $A0, $59,
    $0C, $E7, $5B, $1A, $17, $FB, $F9, $61, $20, $53, $74, $3D, $B3, $F9, $85, $EC,
    $4D, $49, $AA, $0D, $B8, $8D, $0B, $02, $6C, $02, $E1, $33, $CE, $7B, $FB, $7A,
    $97, $95, $93, $67, $45, $0D, $D9, $D0, $F0, $A9, $3E, $3E, $A1, $4E, $6F, $03,
    $43, $CE, $B7, $1D, $6D, $54, $7C, $D3, $5E, $2C, $E2, $30, $25, $4F, $61, $B6,
    $75, $0A, $29, $B6, $D7, $38, $D1, $9F, $D4, $68, $29, $49, $DA, $AB, $F8, $5F,
    $32, $60, $9D, $46, $80, $58, $1A, $5A, $E2, $CA, $50, $F2, $7A, $76, $B1, $90,
    $F9, $70, $8E, $A7, $09, $68, $C1, $DD, $76, $FB, $D7, $FB, $6A, $EE, $F9, $DE,
    $FB, $62, $DF, $CE, $EA, $DB, $1D, $FB, $14, $05, $BB, $95, $C3, $19, $AF, $62,
    $1E, $B0, $CB, $0A, $8D, $0A, $CE, $C2, $C6, $84, $9B, $F9, $D9, $2F, $08, $CF,
    $BE, $0E, $DB, $9A, $87, $DE, $A1, $51, $1F, $63, $E3, $CA, $13, $1B, $59, $F5,
    $EB, $81, $C5, $82, $96, $35, $51, $AB, $00, $38, $A5, $06, $1F, $87, $05, $68,
    $12, $8E, $3E, $6F, $3E, $F8, $0F, $15, $6B, $E0, $38, $15, $A2, $69, $94, $A2,
    $64, $38, $08, $C9, $47, $05, $03, $55, $20, $55, $E0, $7B, $EE, $F7, $96, $2E,
    $B9, $1C, $B6, $01, $A8, $AC, $5D, $86, $5C, $75, $53, $E8, $AA, $91, $C2, $0C,
    $F5, $28, $9C, $40, $C7, $3D, $37, $AD, $6F, $F8, $3F, $E5, $73, $05, $EC, $55,
    $A6, $77, $33, $E0, $23, $3E, $6B, $A2, $BA, $75, $DD, $20, $C0, $86, $BF, $14,
    $9B, $41, $14, $83, $F9, $41, $3A, $C0, $F6, $27, $35, $C7, $AC, $A0, $CA, $EE,
    $87, $E7, $06, $DE, $61, $AE, $76, $E1, $7E, $C3, $CB, $F8, $39, $60, $BB, $1E,
    $AA, $0E, $ED, $54, $A0, $7D, $BB, $74, $FC, $E0, $28, $95, $19, $2C, $02, $32,
    $7F, $A5, $7B, $8F, $5B, $C3, $88, $E1, $F4, $C5, $C4, $9A, $6D, $BA, $40, $0C,
    $EB, $EE, $CF, $EC, $79, $02, $DE, $BD, $A1, $58, $B3, $C9, $DB, $95, $9F, $EE,
    $6B, $A3, $DB, $3A, $E2, $9F, $26, $52, $78, $80, $6D, $1E, $2F, $B7, $78, $95,
    $F1, $30, $E6, $49, $FF, $F0, $DB, $95, $C2, $6E, $6A, $EF, $C4, $F3, $5D, $A2,
    $4A, $79, $CC, $EC, $3A, $E9, $13, $60, $2B, $8B, $EC, $4A, $F8, $3E, $31, $A9,
    $48, $CD, $70, $EC, $7E, $AB, $7A, $B3, $94, $78, $08, $8F, $27, $79, $0D, $2C,
    $55, $FC, $3A, $E9, $5E, $61, $EF, $78, $CD, $FF, $BA, $92, $1E, $C9, $EC, $49,
    $D5, $80, $BC, $1A, $8B, $CB, $53, $EF, $D2, $F4, $D7, $3E, $23, $97, $3B, $F0,
    $4A, $DB, $B6, $84, $8A, $82, $0D, $2B, $BF, $89, $98, $76, $97, $5F, $60, $67,
    $87, $53, $09, $F8, $FC, $9E, $9C, $41, $9D, $5D, $34, $A2, $C2, $A5, $F8, $F2,
    $47, $F6, $1C, $A9, $B3, $6A, $1A, $29, $A4, $A2, $D3, $37, $1E, $57, $E5, $DD,
    $8A, $0F, $A8, $C5, $C4, $B3, $02, $1F, $4A, $8D, $F9, $81, $D7, $68, $D9, $22,
    $BA, $6D, $04, $07, $B4, $65, $69, $A8, $33, $45, $AC, $14, $66, $01, $B9, $36,
    $F8, $82, $78, $0A, $82, $3F, $7C, $64, $F3, $67, $46, $DE, $86, $56, $06, $B1,
    $B3, $B0, $C1, $E9, $50, $E0, $6C, $21, $44, $6C, $00, $CE, $68, $12, $FA, $05,
    $8B, $6D, $40, $52, $C6, $28, $A6, $1C, $2E, $F8, $D9, $7F, $71, $91, $5A, $4F,
    $FF, $A3, $CA, $B5, $78, $F7, $2B, $C8, $62, $6D, $64, $84, $FA, $CD, $E2, $C3,
    $2D, $79, $43, $F0, $EA, $9E, $F4, $22, $B2, $B6, $64, $63, $F2, $7C, $E8, $C2,
    $D1, $1C, $B5, $43, $F4, $6B, $04, $39, $F7, $9A, $5B, $E0, $BC, $08, $1B, $7C,
    $6E, $13, $02, $71, $57, $75, $69, $F8, $8F, $21, $27, $E0, $07, $19, $7B, $39,
    $6A, $1B, $52, $A2, $B7, $30, $82, $05, $41, $06, $09, $2A, $86, $48, $86, $F7,
    $0D, $01, $07, $01, $A0, $82, $05, $32, $04, $82, $05, $2E, $30, $82, $05, $2A,
    $30, $82, $05, $26, $06, $0B, $2A, $86, $48, $86, $F7, $0D, $01, $0C, $0A, $01,
    $02, $A0, $82, $04, $EE, $30, $82, $04, $EA, $30, $1C, $06, $0A, $2A, $86, $48,
    $86, $F7, $0D, $01, $0C, $01, $03, $30, $0E, $04, $08, $7A, $CA, $E9, $53, $FE,
    $D7, $6F, $72, $02, $02, $08, $00, $04, $82, $04, $C8, $28, $4E, $82, $59, $25,
    $B5, $AF, $CB, $C0, $3F, $C7, $E7, $8F, $38, $60, $88, $97, $06, $19, $C5, $4A,
    $68, $46, $B8, $6F, $E4, $DF, $93, $6A, $95, $9A, $49, $46, $BF, $97, $CB, $E3,
    $44, $CF, $E7, $C7, $6C, $31, $59, $8A, $8E, $85, $3E, $62, $B3, $FE, $BE, $6C,
    $0A, $62, $2A, $2E, $1D, $0C, $9B, $ED, $9A, $73, $66, $06, $F6, $8C, $34, $90,
    $67, $84, $AA, $0A, $76, $AA, $47, $BB, $D4, $30, $C7, $8C, $83, $A5, $20, $76,
    $4E, $C0, $99, $A1, $31, $4D, $5C, $3C, $D4, $6F, $EA, $43, $CB, $C2, $75, $95,
    $25, $BB, $0A, $EF, $D9, $9E, $D2, $0B, $EF, $AA, $6F, $14, $8E, $12, $D8, $6E,
    $EB, $B0, $01, $0A, $91, $8B, $32, $78, $05, $AC, $AF, $D2, $EE, $76, $8A, $76,
    $2F, $94, $B6, $58, $B4, $40, $D4, $36, $6C, $71, $BB, $B6, $1C, $91, $B8, $6E,
    $9C, $4E, $1F, $8C, $71, $3B, $B5, $7A, $45, $7D, $75, $09, $40, $06, $03, $F4,
    $75, $E4, $8B, $BD, $43, $74, $1E, $E4, $B2, $7D, $C7, $39, $DF, $8E, $0E, $93,
    $B8, $E4, $50, $3D, $32, $3D, $19, $91, $D1, $44, $B0, $A6, $EF, $5D, $39, $5E,
    $07, $D9, $93, $31, $52, $E0, $8D, $1B, $85, $68, $B5, $D9, $70, $17, $CD, $77,
    $80, $A1, $EF, $83, $81, $3A, $74, $C4, $7C, $3E, $32, $A2, $34, $84, $9B, $31,
    $13, $FF, $CD, $43, $9E, $53, $6C, $74, $D5, $ED, $D2, $BF, $8B, $65, $A2, $24,
    $0D, $73, $03, $AE, $D6, $C2, $C7, $7C, $2C, $77, $1B, $B2, $57, $A5, $D9, $B7,
    $53, $20, $33, $E4, $67, $1F, $E2, $E7, $B7, $6C, $B4, $79, $02, $68, $DD, $EE,
    $4D, $E4, $5F, $1E, $09, $90, $65, $CB, $BB, $7D, $D3, $F7, $F4, $F0, $10, $67,
    $53, $69, $AD, $55, $F7, $B2, $E1, $4A, $EE, $01, $57, $B8, $04, $C7, $96, $32,
    $73, $33, $94, $6F, $4B, $BE, $40, $07, $BD, $3B, $40, $60, $54, $2C, $D9, $49,
    $25, $C6, $9C, $24, $6B, $A8, $E0, $63, $21, $38, $7C, $C1, $79, $D8, $56, $2F,
    $EA, $7A, $35, $82, $2C, $D9, $5F, $16, $2D, $A1, $3C, $8A, $1A, $6B, $98, $CB,
    $F0, $4A, $F6, $33, $FC, $71, $2E, $01, $96, $37, $5D, $75, $D9, $3E, $7E, $F6,
    $64, $E1, $3F, $98, $7C, $C6, $0D, $8C, $62, $33, $10, $F5, $C1, $E3, $96, $FB,
    $3E, $89, $56, $4E, $31, $A3, $C4, $6E, $E3, $48, $7E, $0F, $45, $A7, $00, $86,
    $D2, $45, $4E, $E2, $8B, $32, $2D, $CE, $AA, $CC, $8F, $70, $21, $0C, $FF, $F7,
    $24, $CD, $9B, $14, $F1, $1F, $85, $DB, $F4, $71, $51, $45, $58, $0F, $D1, $85,
    $E3, $7E, $F4, $7C, $FC, $E6, $55, $50, $6A, $2C, $54, $F4, $20, $8E, $AC, $A5,
    $D1, $BB, $E2, $5C, $97, $1F, $A2, $E2, $D4, $10, $DB, $12, $BE, $48, $A2, $5D,
    $1D, $6B, $55, $2C, $1E, $4D, $64, $16, $9D, $F8, $9E, $E1, $5E, $26, $7B, $4F,
    $F7, $66, $77, $40, $35, $0A, $C3, $C8, $92, $AB, $11, $EB, $DB, $7C, $FA, $F7,
    $47, $4B, $63, $9F, $69, $DA, $C5, $A1, $DB, $FD, $FE, $8E, $93, $82, $02, $FF,
    $DC, $77, $7B, $9B, $A4, $67, $61, $28, $9B, $45, $AF, $10, $9E, $25, $21, $E1,
    $DD, $71, $A2, $88, $28, $C3, $EB, $D6, $32, $A2, $CF, $52, $24, $70, $27, $15,
    $E8, $C5, $2B, $FE, $2A, $66, $70, $23, $E4, $FE, $08, $1C, $D0, $39, $A3, $8F,
    $26, $D3, $B7, $4B, $CF, $9E, $11, $4E, $98, $76, $2F, $77, $B7, $E0, $73, $68,
    $90, $93, $FE, $7D, $0C, $4A, $5F, $FA, $B9, $48, $D7, $77, $AF, $35, $08, $C5,
    $98, $F1, $97, $BA, $EE, $BC, $0E, $59, $DE, $8B, $EB, $50, $92, $B2, $4B, $D1,
    $4A, $0B, $C3, $21, $2D, $DF, $72, $57, $19, $89, $47, $18, $EE, $E8, $24, $B7,
    $F5, $0B, $5F, $7E, $60, $F5, $22, $16, $88, $2C, $55, $F2, $D0, $5D, $A1, $0A,
    $17, $86, $42, $5C, $44, $66, $D2, $B7, $69, $F2, $A2, $D9, $0A, $3A, $0A, $B0,
    $DB, $C6, $04, $39, $F7, $90, $92, $1B, $05, $C8, $EF, $68, $58, $10, $22, $53,
    $34, $99, $25, $19, $5E, $3B, $F3, $77, $21, $93, $66, $65, $DE, $61, $E4, $6A,
    $53, $F5, $B2, $E4, $C5, $A3, $F8, $AF, $D7, $C4, $CE, $09, $B8, $9B, $CD, $44,
    $4A, $68, $43, $65, $48, $DE, $48, $FB, $FA, $E6, $17, $95, $0F, $B8, $ED, $4E,
    $DB, $7F, $95, $44, $5D, $C6, $65, $D4, $3F, $A8, $3E, $CB, $19, $34, $4E, $F8,
    $53, $BD, $8E, $B4, $96, $AE, $E1, $26, $34, $40, $3E, $8C, $9D, $72, $D6, $B7,
    $54, $D8, $0D, $38, $BC, $BD, $FA, $6E, $17, $2A, $35, $14, $1F, $2B, $C3, $44,
    $DB, $8A, $6A, $E6, $29, $A1, $20, $0F, $41, $69, $78, $33, $D5, $63, $E0, $7E,
    $39, $0F, $1C, $7E, $E1, $B0, $C6, $8D, $C3, $2C, $48, $F0, $6C, $BC, $8A, $2F,
    $F5, $5E, $06, $CB, $C9, $76, $3C, $1C, $E1, $CB, $4D, $F4, $B0, $0B, $70, $16,
    $CC, $89, $94, $12, $27, $21, $77, $0F, $17, $83, $35, $23, $F5, $DB, $80, $2D,
    $E0, $F1, $93, $72, $DA, $AD, $CB, $FC, $48, $ED, $E2, $B7, $CC, $7A, $59, $7C,
    $C5, $E9, $21, $45, $F5, $0C, $EE, $D3, $45, $22, $C4, $99, $BD, $FB, $20, $60,
    $8B, $F4, $42, $A0, $F1, $6D, $0F, $71, $DD, $74, $A4, $B1, $C4, $BB, $0A, $6B,
    $23, $AF, $19, $00, $8E, $54, $A3, $B6, $E3, $6E, $82, $BB, $1A, $74, $38, $31,
    $15, $13, $82, $3D, $CC, $DE, $55, $FC, $A0, $84, $0C, $59, $71, $E9, $69, $4C,
    $B8, $D0, $A6, $5E, $DD, $5E, $66, $FD, $FD, $36, $A9, $24, $AE, $91, $5D, $40,
    $E4, $F4, $C5, $D9, $3D, $CA, $45, $54, $FB, $CE, $2F, $10, $B6, $D1, $59, $26,
    $E6, $F8, $DB, $7C, $11, $F2, $14, $D4, $2B, $1F, $94, $CD, $6A, $EF, $22, $CE,
    $3C, $B2, $31, $CD, $21, $3B, $8E, $92, $E4, $84, $9F, $40, $C4, $B6, $8D, $AA,
    $D2, $D9, $E1, $1C, $AA, $E6, $8B, $6C, $D3, $BB, $B0, $06, $C9, $E8, $0A, $8C,
    $17, $4F, $E5, $EB, $58, $D5, $24, $F7, $6E, $F7, $A9, $29, $C3, $11, $F8, $BC,
    $F5, $C5, $BC, $53, $80, $8D, $4E, $E9, $31, $B7, $37, $2F, $DD, $8E, $85, $6B,
    $4C, $D5, $A7, $CC, $3D, $5B, $35, $96, $FE, $3B, $21, $4E, $D5, $1C, $BC, $29,
    $84, $AD, $44, $3E, $1B, $EF, $2B, $2E, $23, $CA, $51, $80, $9D, $01, $12, $DB,
    $5D, $D7, $FA, $AC, $22, $7A, $38, $44, $DA, $08, $41, $78, $07, $15, $F6, $CE,
    $1E, $E3, $84, $46, $1E, $95, $4B, $31, $5A, $44, $12, $0B, $AA, $BA, $16, $90,
    $DC, $1B, $CE, $21, $B2, $68, $7A, $99, $DF, $5B, $45, $98, $E2, $6F, $F1, $08,
    $0C, $58, $A0, $A2, $00, $19, $2B, $B5, $72, $22, $C8, $D3, $E9, $F5, $48, $96,
    $CD, $7D, $37, $B7, $9F, $5E, $84, $9C, $D3, $3D, $81, $1F, $39, $40, $FD, $66,
    $DA, $7F, $FB, $DF, $B8, $3C, $17, $F3, $13, $B8, $5E, $BC, $4F, $1F, $8F, $A4,
    $89, $52, $B2, $A6, $E1, $63, $9D, $4A, $48, $E6, $CE, $AB, $E4, $12, $68, $5A,
    $7E, $6C, $30, $11, $CA, $49, $57, $89, $B0, $91, $30, $E7, $23, $C2, $1B, $A1,
    $AF, $EC, $56, $02, $26, $1A, $6D, $C7, $71, $5B, $95, $CD, $77, $52, $E6, $22,
    $60, $5A, $7C, $42, $BE, $2F, $91, $C1, $B6, $93, $6F, $01, $F7, $F7, $FA, $F3,
    $91, $55, $44, $31, $25, $30, $23, $06, $09, $2A, $86, $48, $86, $F7, $0D, $01,
    $09, $15, $31, $16, $04, $14, $56, $B9, $70, $13, $C8, $9C, $6F, $FD, $AA, $83,
    $DC, $22, $2B, $33, $4A, $BD, $D8, $07, $16, $5E, $30, $2D, $30, $21, $30, $09,
    $06, $05, $2B, $0E, $03, $02, $1A, $05, $00, $04, $14, $01, $84, $3F, $C2, $85,
    $92, $3C, $95, $E5, $7E, $67, $FB, $48, $26, $4D, $5E, $B6, $F5, $CD, $24, $04,
    $08, $F1, $91, $00, $F4, $F9, $06, $7B, $85);


implementation

{ TTestClientServerAccess }

{$ifndef ONLYUSEHTTPSOCKET}
class function TTestClientServerAccess.RegisterAddUrl(OnlyDelete: boolean): string;
begin
  result := THttpApiServer.AddUrlAuthorize(
    'root', HTTP_DEFAULTPORT, false, '+', OnlyDelete);
end;
{$endif ONLYUSEHTTPSOCKET}

procedure TTestClientServerAccess._TRestHttpServer;
var
  c: ICryptCert;
  pfx: RawByteString;
begin
  if fHttps then
  begin
    if CryptCertAlgoOpenSsl[caaRS256] = nil then
    begin
      // some pre-computed CryptCertAlgoOpenSsl[caaRS256].New key for Windows
      fHttpsCertFile := WorkDir + 'privkeycert.pfx';
      FastSetRawByteString(pfx, @PrivKeyCertPfx, SizeOf(PrivKeyCertPfx));
      FileFromString(pfx, fHttpsCertFile);
    end
    else
    begin
      // create a new self-signed key pair using OpenSSL
      fHttpsKeyFile := WorkDir + 'privkey.pem';
      fHttpsCertFile := WorkDir + 'cert.pem';
      c := CryptCertAlgoOpenSsl[caaRS256].New;
      c.Generate([cuTlsServer], '127.0.0.1', nil, 3650);
      //writeln(c.GetPeerInfo);
      FileFromString(c.Save('pass', ccfPem), fHttpsKeyFile); // public + private keys
      FileFromString(c.Save('', ccfPem), fHttpsCertFile);    // public key
      pfx := c.Save('pass', ccfBinary);
      FileFromString(pfx, WorkDir + 'privkeycert.pfx');
      //FileFromString(BinToSource('PrivKeyCertPfx', '', pointer(pfx), length(pfx)), WorkDir + 'privkeycert.pas');
    end;
    // on Windows: create PKCS#12 privkeycert.pfx
  end;
  Model := TOrmModel.Create([TOrmPeople], 'root');
  Check(Model <> nil);
  Check(Model.GetTableIndex('people') >= 0);
  try
    DataBase := TRestServerDB.Create(Model, WorkDir + 'test.db3');
    DataBase.DB.Synchronous := smOff;
    DataBase.DB.LockingMode := lmExclusive;
    Server := TRestHttpServer.Create(HTTP_DEFAULTPORT, [DataBase], '+',
      HTTPS_DEFAULT_MODE[fHttps], 16, HTTPS_SECURITY[fHttps], '', '',
      [rsoLogVerbose], fHttpsCertFile, fHttpsKeyFile, 'pass');
    AddConsole('using % %', [Server.HttpServer, Server.HttpServer.APIVersion]);
    Database.NoAjaxJson := true; // expect not expanded JSON from now on
  except
    on E: Exception do
      Check(false, E.Message);
  end;
end;

procedure TTestClientServerAccess.CleanUp;
begin
  FreeAndNil(Client); // should already be nil
  Server.Shutdown;
  FreeAndNil(Server);
  FreeAndNil(DataBase);
  FreeAndNil(Model);
end;

procedure TTestClientServerAccess._TRestHttpClient;
var
  Resp: TOrmTable;
begin
  Client := TRestHttpClient.Create('127.0.0.1', HTTP_DEFAULTPORT, Model, fHttps);
  AddConsole('using %', [Client]);
  (Client as TRestHttpClientGeneric).Compression := [];
  (Client as TRestHttpClientGeneric).IgnoreTlsCertificateErrors := fHttps;
  Resp := Client.Client.List([TOrmPeople], '*');
  if CheckFailed(Resp <> nil) then
    exit;
  try
    Check(Resp.InheritsFrom(TOrmTableJson));
    CheckEqual(Resp.RowCount, 11011);
    CheckHash(TOrmTableJson(Resp).PrivateInternalCopy, 4045204160);
    if fHttps and
       Client.InheritsFrom(TRestHttpClientSocket) then
      AddConsole(' %', [TRestHttpClientSocket(Client).Socket.TLS.CipherName]);
    //FileFromString(TOrmTableJson(Resp).PrivateInternalCopy, 'internalfull2.parsed');
    //FileFromString(Resp.GetODSDocument, WorkDir + 'people.ods');
  finally
    Resp.Free;
  end;
end;

{$define WTIME}

const
  CLIENTTEST_WHERECLAUSE = 'FirstName Like "Sergei1%"';

procedure TTestClientServerAccess.ClientTest;
const
  IDTOUPDATE = 3;
{$ifdef WTIME}
  LOOP = 1000;
var
  Timer: ILocalPrecisionTimer;
{$else}
  LOOP = 100;
{$endif WTIME}
var
  i: integer;
  Resp: TOrmTable;
  Rec, Rec2: TOrmPeople;
  Refreshed: boolean;

  procedure TestOne;
  var
    i: integer;
  begin
    i := Rec.YearOfBirth;
    Rec.YearOfBirth := 1982;
    Check(Client.Orm.Update(Rec));
    Rec2.ClearProperties;
    Check(Client.Orm.Retrieve(IDTOUPDATE, Rec2));
    Check(Rec2.YearOfBirth = 1982);
    Rec.YearOfBirth := i;
    Check(Client.Orm.Update(Rec));
    if Client.InheritsFrom(TRestClientURI) then
    begin
      Check(Client.Client.UpdateFromServer([Rec2], Refreshed));
      Check(Refreshed, 'should have been refreshed');
    end
    else
      Check(Client.Orm.Retrieve(IDTOUPDATE, Rec2));
    Check(Rec.SameRecord(Rec2));
  end;

var
  onelen: integer;
begin
{$ifdef WTIME}
  Timer := TLocalPrecisionTimer.CreateAndStart;
{$endif WTIME}
  // first calc result: all transfert protocols have to work from cache
  Resp := Client.Client.List([TOrmPeople], '*', CLIENTTEST_WHERECLAUSE);
  if CheckFailed(Resp <> nil) then
    exit;
  CheckEqual(Resp.RowCount, 113);
  CheckHash(TOrmTableJson(Resp).PrivateInternalCopy, $8D727024);
  onelen := length(TOrmTableJson(Resp).PrivateInternalCopy);
  CheckEqual(onelen, 4818);
  Resp.Free;
{$ifdef WTIME}
  fRunConsole := format('%s%s, first %s, ', [fRunConsole, KB(onelen), Timer.Stop]);
{$endif WTIME}
  // test global connection speed and caching (both client and server sides)
  Rec2 := TOrmPeople.Create;
  Rec := TOrmPeople.Create(Client.Orm, IDTOUPDATE);
  try
    Check(Rec.ID = IDTOUPDATE, 'retrieve record');
    Check(Database.Orm.Cache.CachedEntries = 0);
    Check(Client.Orm.Cache.CachedEntries = 0);
    Check(Client.Orm.Cache.CachedMemory = 0);
    TestOne;
    Check(Client.Orm.Cache.CachedEntries = 0);
    Client.Orm.Cache.SetCache(TOrmPeople); // cache whole table
    Check(Client.Orm.Cache.CachedEntries = 0);
    Check(Client.Orm.Cache.CachedMemory = 0);
    TestOne;
    Check(Client.Orm.Cache.CachedEntries = 1);
    Check(Client.Orm.Cache.CachedMemory > 0);
    Client.Orm.Cache.Clear; // reset cache settings
    Check(Client.Orm.Cache.CachedEntries = 0);
    Client.Orm.Cache.SetCache(Rec); // cache one = SetCache(TOrmPeople,Rec.ID)
    Check(Client.Orm.Cache.CachedEntries = 0);
    Check(Client.Orm.Cache.CachedMemory = 0);
    TestOne;
    Check(Client.Orm.Cache.CachedEntries = 1);
    Check(Client.Orm.Cache.CachedMemory > 0);
    Client.Orm.Cache.SetCache(TOrmPeople);
    TestOne;
    Check(Client.Orm.Cache.CachedEntries = 1);
    Client.Orm.Cache.Clear;
    Check(Client.Orm.Cache.CachedEntries = 0);
    TestOne;
    Check(Client.Orm.Cache.CachedEntries = 0);
    if not (Client.InheritsFrom(TRestClientDB)) then
    begin // server-side
      Database.Orm.Cache.SetCache(TOrmPeople);
      TestOne;
      Check(Client.Orm.Cache.CachedEntries = 0);
      Check(Database.Orm.Cache.CachedEntries = 1);
      Database.Orm.Cache.Clear;
      Check(Client.Orm.Cache.CachedEntries = 0);
      Check(Database.Orm.Cache.CachedEntries = 0);
      Database.Orm.Cache.SetCache(TOrmPeople, Rec.ID);
      TestOne;
      Check(Client.Orm.Cache.CachedEntries = 0);
      Check(Database.Orm.Cache.CachedEntries = 1);
      Database.Orm.Cache.SetCache(TOrmPeople);
      Check(Database.Orm.Cache.CachedEntries = 0);
      TestOne;
      Check(Database.Orm.Cache.CachedEntries = 1);
      if Client.InheritsFrom(TRestClientURI) then
        Client.Client.ServerCacheFlush
      else
        Database.Orm.Cache.Flush;
      Check(Database.Orm.Cache.CachedEntries = 0);
      Check(Database.Orm.Cache.CachedMemory = 0);
      Database.Orm.Cache.Clear;
    end;
  finally
    Rec2.Free;
    Rec.Free;
  end;
  // test average speed for a 5 KB request
  Resp := Client.Client.List([TOrmPeople], '*', CLIENTTEST_WHERECLAUSE);
  Check(Resp <> nil);
  Resp.Free;
{$ifdef WTIME}
  Timer.Start;
{$endif}
  for i := 1 to LOOP do
  begin
    Resp := Client.Client.List([TOrmPeople], '*', CLIENTTEST_WHERECLAUSE);
    if CheckFailed(Resp <> nil) then
      exit;
    try
      Check(Resp.InheritsFrom(TOrmTableJson));
      // every answer contains 113 rows, for a total JSON size of 4803 bytes
      CheckEqual(Resp.RowCount, 113);
      CheckHash(TOrmTableJson(Resp).PrivateInternalCopy, $8D727024);
    finally
      Resp.Free;
    end;
  end;
{$ifdef WTIME}
  fRunConsole := format('%sdone %s i.e. %d/s, aver. %s, %s/s', [fRunConsole,
    Timer.Stop, Timer.PerSec(LOOP), Timer.ByCount(LOOP),
      KB(Timer.PerSec(onelen * (LOOP + 1)))]);
{$endif WTIME}
end;

procedure TTestClientServerAccess.HttpClientKeepAlive;
begin
  (Client as TRestHttpClientGeneric).KeepAliveMS := 20000;
  (Client as TRestHttpClientGeneric).Compression := [];
  ClientTest;
end;

procedure TTestClientServerAccess.HttpClientMultiConnect;
begin
  (Client as TRestHttpClientGeneric).KeepAliveMS := 0;
  (Client as TRestHttpClientGeneric).Compression := [];
  ClientTest;
end;

{$ifndef PUREMORMOT2}
procedure TTestClientServerAccess.HttpClientEncrypted;
begin
  (Client as TRestHttpClientGeneric).KeepAliveMS := 20000;
  (Client as TRestHttpClientGeneric).Compression := [hcSynShaAes];
  ClientTest;
end;
{$endif PUREMORMOT2}

{$ifdef HASRESTCUSTOMENCRYPTION}

procedure TTestClientServerAccess.HttpClientCustomEncryptionAesSha;
var
  rnd: THash256;
  sign: TSynSigner;
begin
  TAESPRNG.Main.FillRandom(rnd);
  sign.Init(saSha256, 'secret1');
  Client.SetCustomEncryption(TAESOFB.Create(rnd), @sign, AlgoSynLZ);
  DataBase.SetCustomEncryption(TAESOFB.Create(rnd), @sign, AlgoSynLZ);
  ClientTest;
end;

procedure TTestClientServerAccess.HttpClientCustomEncryptionAes;
var
  rnd: THash256;
begin
  TAESPRNG.Main.FillRandom(rnd);
  Client.SetCustomEncryption(TAESOFB.Create(rnd), nil, AlgoSynLZ);
  DataBase.SetCustomEncryption(TAESOFB.Create(rnd), nil, AlgoSynLZ);
  ClientTest;
end;

procedure TTestClientServerAccess.HttpClientCustomEncryptionSha;
var
  sign: TSynSigner;
begin
  sign.Init(saSha256, 'secret2');
  Client.SetCustomEncryption(nil, @sign, AlgoSynLZ);
  DataBase.SetCustomEncryption(nil, @sign, AlgoSynLZ);
  ClientTest;
  Client.SetCustomEncryption(nil, nil, nil); // disable custom encryption
  DataBase.SetCustomEncryption(nil, nil, nil);
end;
{$endif HASRESTCUSTOMENCRYPTION}

procedure TTestClientServerAccess._TRestHttpsServer;
begin
  CleanUp;
  fHttps := true;
  _TRestHttpServer;
end;

procedure TTestClientServerAccess._TRestHttpsClient;
begin
  _TRestHttpClient;
end;

procedure TTestClientServerAccess.HttpsClientKeepAlive;
begin
  HttpClientKeepAlive;
  fHttps := false;
end;

procedure TTestClientServerAccess.HTTPSeveralDBServers;
var
  Instance: array[0..2] of record
    Model: TOrmModel;
    Database: TRestServerDB;
    Client: TRestHttpClientGeneric;
  end;
  i: integer;
  Rec: TOrmPeople;
begin
  Rec := TOrmPeople.CreateAndFillPrepare(Database.Orm, CLIENTTEST_WHERECLAUSE);
  try
    Check(Rec.FillTable.RowCount = 113);
    // release main http client/server and main database instances
    CleanUp;
    Check(Client = nil);
    Check(Server = nil);
    Check(DataBase = nil);
    // create 3 in-memory TRestServerDB + TRestHttpClient instances (+TOrmModel)
    for i := 0 to high(Instance) do
      with Instance[i] do
      begin
        Model := TOrmModel.Create([TOrmPeople], 'root' + Int32ToUtf8(i));
        DataBase := TRestServerDB.Create(Model, SQLITE_MEMORY_DATABASE_NAME);
        Database.NoAjaxJson := true; // expect not expanded JSON from now on
        DataBase.Server.CreateMissingTables;
      end;
    // launch one HTTP server for all TRestServerDB instances
    Server := TRestHttpServer.Create(HTTP_DEFAULTPORT, [Instance[0].Database,
      Instance[1].Database, Instance[2].Database], '+', HTTP_DEFAULT_MODE, 4,
      secNone, '', '', [rsoLogVerbose]);
    // initialize the clients
    for i := 0 to high(Instance) do
      with Instance[i] do
      begin
        Client := TRestHttpClient.Create(
          '127.0.0.1', HTTP_DEFAULTPORT, TOrmModel.Create(Model));
        Client.Model.Owner := Client;
      end;
    // fill remotely all TRestServerDB instances
    for i := 0 to high(Instance) do
      with Instance[i] do
      begin
        Client.Client.TransactionBegin(TOrmPeople);
        Check(Rec.FillRewind);
        while Rec.FillOne do
          Check(Client.Client.Add(Rec, true, true) = Rec.IDValue);
        Client.Client.Commit;
      end;
    // test remote access to all TRestServerDB instances
    try
      for i := 0 to high(Instance) do
      begin
        Client := Instance[i].Client;
        DataBase := Instance[i].DataBase;
        try
          ClientTest;
          {$ifdef WTIME}
          if i < high(Instance) then
            fRunConsole := fRunConsole + #13#10 + '     ';
          {$endif WTIME}
        finally
          Client := nil;
          DataBase := nil;
        end;
      end;
    finally
      Client := nil;
      Database := nil;
      // release all TRestServerDB + TRestHttpClient instances (and TOrmModel)
      for i := high(Instance) downto 0 do
        with Instance[i] do
        begin
          FreeAndNil(Client);
          Server.RemoveServer(DataBase);
          FreeAndNil(DataBase);
          FreeAndNil(Model);
        end;
    end;
  finally
    Rec.Free;
  end;
end;

{$ifdef OSWINDOWSTODO}
procedure TTestClientServerAccess.NamedPipeAccess;
begin
  Check(DataBase.ExportServerNamedPipe('test'));
  Client.Free;
  Client := TRestClientURINamedPipe.Create(Model, 'test');
  ClientTest;
  // note: 1st connection is slower than with HTTP (about 100ms), because of
  // Sleep(128) in TRestServerNamedPipe.Execute: but we should connect
  // localy only once, and avoiding Context switching is a must-have
  FreeAndNil(Client);
  Check(DataBase.CloseServerNamedPipe);
end;

procedure TTestClientServerAccess.LocalWindowMessages;
begin
  Check(DataBase.ExportServerMessage('test'));
  Client := TRestClientURIMessage.Create(Model, 'test', 'Client', 1000);
  ClientTest;
  FreeAndNil(Client);
end;
{$endif OSWINDOWS}

procedure TTestClientServerAccess.DirectInProcessAccess;
var
  stats: RawUtf8;
begin
  FreeAndNil(Client);
  Client := TRestClientDB.Create(Model, TOrmModel.Create([TOrmPeople], 'root'),
    DataBase.DB, TRestServerTest);
  ClientTest;
  Client.CallBackGet('stat', ['withall', true], stats);
  FileFromString(JSONReformat(stats), WorkDir + 'statsClientServer.json');
  FreeAndNil(Client);
end;

end.

