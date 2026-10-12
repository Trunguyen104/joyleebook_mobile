import 'package:flutter/foundation.dart';

@immutable
class GatewayCheckResult {
  const GatewayCheckResult({
    required this.endpoint,
    required this.name,
    required this.description,
    this.statusCode,
    this.statusMessage,
    this.latencyMs,
    this.isSuccess = false,
    this.isLoading = false,
    this.rawBody,
    this.errorMessage,
    this.timestamp,
  });

  final String endpoint;
  final String name;
  final String description;
  final int? statusCode;
  final String? statusMessage;
  final int? latencyMs;
  final bool isSuccess;
  final bool isLoading;
  final String? rawBody;
  final String? errorMessage;
  final DateTime? timestamp;

  GatewayCheckResult copyWith({
    int? statusCode,
    String? statusMessage,
    int? latencyMs,
    bool? isSuccess,
    bool? isLoading,
    String? rawBody,
    String? errorMessage,
    DateTime? timestamp,
  }) {
    return GatewayCheckResult(
      endpoint: endpoint,
      name: name,
      description: description,
      statusCode: statusCode ?? this.statusCode,
      statusMessage: statusMessage ?? this.statusMessage,
      latencyMs: latencyMs ?? this.latencyMs,
      isSuccess: isSuccess ?? this.isSuccess,
      isLoading: isLoading ?? this.isLoading,
      rawBody: rawBody ?? this.rawBody,
      errorMessage: errorMessage ?? this.errorMessage,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
