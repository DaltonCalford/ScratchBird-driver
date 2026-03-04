package com.scratchbird.hibernate;

import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;

public final class ScratchBirdJdbcUrlPolicy {
  private ScratchBirdJdbcUrlPolicy() {}

  public static Map<String, String> validateAndParse(String jdbcUrl) {
    if (jdbcUrl == null || jdbcUrl.isBlank()) {
      throw new IllegalArgumentException("JDBC URL is required");
    }
    if (!jdbcUrl.startsWith("jdbc:scratchbird:")) {
      throw new IllegalArgumentException("JDBC URL must start with jdbc:scratchbird:");
    }

    int queryIndex = jdbcUrl.indexOf('?');
    Map<String, String> params = new LinkedHashMap<>();
    if (queryIndex < 0 || queryIndex == jdbcUrl.length() - 1) {
      return params;
    }

    String query = jdbcUrl.substring(queryIndex + 1);
    for (String pair : query.split("&")) {
      if (pair.isBlank()) {
        continue;
      }
      String[] parts = pair.split("=", 2);
      String key = decode(parts[0]);
      String value = parts.length > 1 ? decode(parts[1]) : "";
      String normalizedKey = key.toLowerCase(Locale.ROOT);
      String normalizedValue = value.trim().toLowerCase(Locale.ROOT);

      if (normalizedKey.equals("sslmode") && normalizedValue.equals("disable")) {
        throw new IllegalArgumentException("sslmode=disable is not supported");
      }
      if ((normalizedKey.equals("binarytransfer") || normalizedKey.equals("binary_transfer"))
          && isFalse(normalizedValue)) {
        throw new IllegalArgumentException("binaryTransfer=false is not supported");
      }
      if (normalizedKey.equals("compression") && normalizedValue.equals("zstd")) {
        throw new IllegalArgumentException("compression=zstd is not supported");
      }

      params.put(key, value);
    }
    return params;
  }

  private static String decode(String value) {
    return URLDecoder.decode(value, StandardCharsets.UTF_8);
  }

  private static boolean isFalse(String value) {
    return value.equals("false") || value.equals("0") || value.equals("off") || value.equals("no");
  }
}
