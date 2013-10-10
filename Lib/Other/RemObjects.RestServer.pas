unit RemObjects.RestServer;

// Version 0.1
//
// RemObjects TROIndyHTTPServer extension to support REST requests.
//
//----------------------------------------------------------------------------------------------------------------------
//
// The contents of this file are subject to the Mozilla Public License
// Version 1.1 (the "License"); you may not use this file except in compliance
// with the License. You may obtain a copy of the License at http://www.mozilla.org/MPL/
//
// Alternatively, you may redistribute this library, use and/or modify it under the terms of the
// GNU Lesser General Public License as published by the Free Software Foundation;
// either version 2.1 of the License, or (at your option) any later version.
// You may obtain a copy of the LGPL at http://www.gnu.org/copyleft/.
//
// Software distributed under the License is distributed on an "AS IS" basis,
// WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the
// specific language governing rights and limitations under the License.
//
// The original code is RemObjects.RestServer.pas, released October 2013.
//
// The initial developer of the original code is Easy-IP AS (Oslo, Norway, www.easy-ip.net),
// written by Paul Spencer Thornton (paul.thornton@easy-ip.net, www.easy-ip.net).
//
//----------------------------------------------------------------------------------------------------------------------
// Features:
//
// Access a RemObjects SDK/DataAbstract server using a URI e.g.
// http://127.0.0.1:8181/json/DemoService/GetSum?A=5&B=5
//
// The results are returned as JSON or XML
//
// See the RORestServer/RestMobileClient demos

interface

uses
  System.SysUtils, System.Classes,

  uROIndyHTTPServer, uROJSONMessage, uROSOAPMessage, uROXMLSerializer,
  uROServer, uROClient,

  IdURI, IdCustomHTTPServer;

type
  // The format that the URI is expected to be in
  TURIHandlingMethod = (
    urhNone,       // No URI parameters. This is a normal HTTP request
    urhJSON,       // JSON style URI
    urhParameters  // Parameter style URI
  );

  TRORestServer = class(TROIndyHTTPServer)
  private
    FURIHandlingMethod: TURIHandlingMethod;
    FJSONVersion: String;
    FJSONMessage: TROJSONMessage;
    FSOAPMessage: TROSOAPMessage;
    FJSONEntryName: String;
    FXMLEntryName: String;
    FXMLLibraryName: String;

    function NextBlock(var Value: String; Delimiter: Char = '/'): String;
    function ConvertURIToMessageFormat(const Document, Params: String): String;
  protected
    procedure InternalServerCommandGet(AThread: TIdThreadClass; RequestInfo: TIdHTTPRequestInfo; ResponseInfo: TIdHTTPResponseInfo); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property URIHandlingMethod: TURIHandlingMethod read FURIHandlingMethod write FURIHandlingMethod;
    property JSONVersion: String read FJSONVersion write FJSONVersion;
    property JSONEntryName: String read FJSONEntryName write FJSONEntryName;
    property XMLEntryName: String read FXMLEntryName write FXMLEntryName;
    property XMLLibraryName: String read FXMLLibraryName write FXMLLibraryName;
  end;

implementation

{ TROJSONURIIndyHTTPServer }

constructor TRORestServer.Create(AOwner: TComponent);

  function AddMessageDispatcher(AMessage: TROMessage): TROMessageDispatcher;
  var
    MessageDispatcher: TROMessageDispatcher;
  begin
    // Add the message to the list of server dispatchers
    Result := TROMessageDispatcher(Dispatchers.Add);
    Result.Message := AMessage;
    Result.Enabled := TRUE;
  end;

begin
  inherited;

  // Create the JSON message
  FJSONMessage := TROJSONMessage.Create(Self);
  FJSONMessage.SetSubComponent(TRUE);
  AddMessageDispatcher(FJSONMessage);

  // Create the SOAP message
  FSOAPMessage := TROSOAPMessage.Create(Self);
  FSOAPMessage.SetSubComponent(TRUE);
  AddMessageDispatcher(FSOAPMessage);

  // Set the default JSON properties
  FJSONMessage.SendExtendedException := TRUE;
  FJSONVersion := '1.1';
  FJSONEntryName := 'JSON';

  // Set the default SOAP/XML properties
  FSOAPMessage.SerializationOptions := [xsoSendUntyped, xsoStrictStructureFieldOrder, xsoDocument, xsoSplitServiceWsdls];
  FXMLEntryName := 'XML';
  FXMLLibraryName := 'Library';
  FURIHandlingMethod := urhParameters;
end;

function TRORestServer.NextBlock(var Value: String; Delimiter: Char): String;
var
  p: Integer;
begin
  p := 1;

  while (p <= length(Value)) and (Value[p] <> Delimiter) do
    Inc(p);

  if p = length(Value) then
    Result := Value
  else
    Result := copy(Value, 1, p - 1);

  Value := copy(Value, p + 1, MaxInt);
end;

function TRORestServer.ConvertURIToMessageFormat(const Document, Params: String): String;

type
  TDocMessageType = (
    dmtUnknown,
    dmtJSON,
    dmtSOAP
  );

const
  NewLine = #10;

  SOAPHeader = '<?xml version="1.0"?>' + NewLine +
               '  <SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" ' +
               'xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ' +
               'xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/">' + NewLine +
               '    <SOAP-ENV:Body SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" ' +
               'xmlns:NS2="http://tempuri.org/">' + NewLine +
               '      <NS1:%s xmlns:NS1="urn:%s-%s">';

  SOAPContent ='        <%s xsi:type="xsd:string">%s</%s>' + NewLine;

  SOAPFooter = '    </NS1:%s>' + NewLine +
               '  </SOAP-ENV:Body>' + NewLine +
               '</SOAP-ENV:Envelope>';

  JSONObjectTemplate = '{"method":"%s.%s"%s,"version": "%s"}';
  JSONParamTemplate = '"%s":"%s"';
  JSONParamsTemplate = ',"params":{%s}';

var
  CallService, CallMessage,
  ParsedDocument, ParsedParams, ParamsText,
  Param, ParamName, ParamValue, DocMT: String;
  DocMessageType: TDocMessageType;
begin
  Result := '';

  ParsedDocument := Trim(Document);

  // Remove the leading /
  if (length(Document) > 0) and
     (Document[1] = '/') then
    NextBlock(ParsedDocument);

  // Remove the message type
  DocMT := NextBlock(ParsedDocument);

  if SameText(DocMT, FJSONEntryName) then
    DocMessageType := dmtJSON else
  if SameText(DocMT, FXMLEntryName) then
    DocMessageType := dmtSOAP
  else
    DocMessageType := dmtUnknown;

  if DocMessageType <> dmtUnknown then
  begin
    // Extract the service
    CallService := NextBlock(ParsedDocument);

    // Exctract the service message (method)
    CallMessage := NextBlock(ParsedDocument);

    ParamsText := '';
    ParsedParams := Params;

    while ParsedParams <> '' do
    begin
      // Extract the parameter and value
      Param := NextBlock(ParsedParams, '&');

      // RFC 1866 section 8.2.1.
      Param := StringReplace(Param, '+', ' ', [rfReplaceAll]);  {do not localize}

      // Extract the parameter name
      ParamName := NextBlock(Param, '=');

      // Extract the parameter value
      ParamValue := Param;

      // Add a delimiter if required
      if ParamsText <> '' then
        ParamsText := ParamsText + ',';

      // Build the JSON style parameter
      case DocMessageType of
        dmtJSON: ParamsText := ParamsText + format(JSONParamTemplate, [ParamName, ParamValue]);
        dmtSOAP: ParamsText := ParamsText + format(SOAPContent, [ParamName, ParamValue, ParamName]);
      end;
    end;

    // Make sure we have values for all the object variables, then build the JSON object
    if (CallService <> '') and
       (CallMessage <> '') then
    begin
      case DocMessageType of
        dmtJSON:
          begin
            if FJSONVersion <> '' then
            begin
              if ParamsText <> '' then
               ParamsText := format(JSONParamsTemplate, [ParamsText]);

              Result := format(JSONObjectTemplate, [CallService, CallMessage, ParamsText, JSONVersion]);
            end;
          end;

        dmtSOAP:
          begin
            Result := format(SOAPHeader, [CallMessage, FXMLLibraryName, CallService]) +
                      ParamsText +
                      format(SOAPFooter, [CallMessage]);
          end;
      end;
    end;
  end;
end;

procedure TRORestServer.InternalServerCommandGet(
  AThread: TIdThreadClass; RequestInfo: TIdHTTPRequestInfo;
  ResponseInfo: TIdHTTPResponseInfo);
begin
  if FURIHandlingMethod in [urhJSON, urhParameters] then
  begin
    // Parse parameters into JSON if required
    if FURIHandlingMethod = urhParameters then
      RequestInfo.UnparsedParams := ConvertURIToMessageFormat(RequestInfo.Document, RequestInfo.UnparsedParams);

    // Decode the URI e.g. converts %20 to whitespace
    RequestInfo.UnparsedParams := TIdURI.URLDecode(RequestInfo.UnparsedParams);

    //  This works around a bug in TROIndyHTTPServer. By adding a whitespace to the
    //  end of the QueryParams it forces the http server to process the parameters
    RequestInfo.QueryParams := TIdURI.URLDecode(RequestInfo.QueryParams) + ' ';
  end;

  inherited;
end;

end.
