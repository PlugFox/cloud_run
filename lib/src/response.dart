import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

Converter<Object?, List<int>>? _jsonEncoderStored;
Converter<Object?, List<int>> get _jsonEncoder =>
    _jsonEncoderStored ??= JsonUtf8Encoder();

class ServerResponse {
  const ServerResponse.stream(
    this.data, {
    this.statusCode = io.HttpStatus.ok,
    this.headers = const <String, String>{
      io.HttpHeaders.connectionHeader: 'close',
      io.HttpHeaders.contentTypeHeader: 'application/octet-stream',
    },
  });

  factory ServerResponse.json(
    Object? json, {
    int statusCode,
    Map<String, String>? headers,
  }) = _JSONServerResponse;

  factory ServerResponse.text(
    String? text, {
    int statusCode,
    Map<String, String>? headers,
  }) = _TextServerResponse;

  factory ServerResponse.image(
    Stream<List<int>> image,
    String mime, {
    int statusCode,
    Map<String, String>? headers,
  }) = _ImageServerResponse;

  ///
  /// The status code of the response.
  ///
  /// Any integer value is accepted. For
  /// the official HTTP status codes use the fields from
  /// [HttpStatus]. If no status code is explicitly set the default
  /// value [HttpStatus.ok] is used.
  ///
  final int statusCode;

  ///
  /// Response headers.
  /// [HttpHeaders] object may be handy to fill this hash table.
  ///
  final Map<String, String> headers;

  ///
  /// Body byte stream
  ///
  final Stream<List<int>> data;
}

class _JSONServerResponse extends ServerResponse {
  _JSONServerResponse(
    Object? json, {
    int statusCode = io.HttpStatus.ok,
    Map<String, String>? headers,
  }) : super.stream(
          Stream<Object?>.value(json).transform<List<int>>(_jsonEncoder),
          statusCode: statusCode,
          headers: Map<String, String>.of(headers ??
              <String, String>{
                io.HttpHeaders.connectionHeader: 'close',
              })
            ..addAll({
              io.HttpHeaders.contentTypeHeader: 'application/json',
            }),
        );
}

class _TextServerResponse extends ServerResponse {
  _TextServerResponse(
    String? text, {
    int statusCode = io.HttpStatus.ok,
    Map<String, String>? headers,
  }) : super.stream(
          Stream<String>.value(text ?? '')
              .transform<List<int>>(const Utf8Encoder()),
          statusCode: statusCode,
          headers: Map<String, String>.of(headers ??
              <String, String>{
                io.HttpHeaders.connectionHeader: 'close',
              })
            ..addAll({
              io.HttpHeaders.contentTypeHeader: 'text/plain; charset=utf-8',
            }),
        );
}

class _ImageServerResponse extends ServerResponse {
  _ImageServerResponse(
    Stream<List<int>> image,
    String mime, {
    int statusCode = io.HttpStatus.ok,
    Map<String, String>? headers,
  }) : super.stream(
          image,
          statusCode: statusCode,
          headers: Map<String, String>.of(headers ??
              <String, String>{
                io.HttpHeaders.connectionHeader: 'close',
              })
            ..addAll({
              io.HttpHeaders.contentTypeHeader: mime, // 'image/png'
            }),
        );
}

/// TODO: multipart/byteranges
