// ---------------------------------------------------------------------------
// Small HTTP helpers built on plain java.net.HttpURLConnection, so the sketch
// needs no extra Processing libraries. All of these are BLOCKING calls —
// always run them via thread("...") from the UI code, never straight from
// draw()/mousePressed().
// ---------------------------------------------------------------------------

byte[] readAllBytes(InputStream is) throws IOException {
  ByteArrayOutputStream buffer = new ByteArrayOutputStream();
  byte[] chunk = new byte[8192];
  int n;
  while ((n = is.read(chunk)) != -1) {
    buffer.write(chunk, 0, n);
  }
  return buffer.toByteArray();
}

HttpURLConnection openConnection(String urlStr, String method, String contentType) throws IOException {
  URL url = new URL(urlStr);
  HttpURLConnection conn = (HttpURLConnection) url.openConnection();
  conn.setRequestMethod(method);
  conn.setConnectTimeout(20000);
  conn.setReadTimeout(600000); // some of these generations take minutes
  if (contentType != null) {
    conn.setRequestProperty("Content-Type", contentType);
  }
  if (isApiKeyConfigured()) {
    conn.setRequestProperty("Authorization", "Bearer " + API_KEY);
  }
  return conn;
}

byte[] readResponse(HttpURLConnection conn) throws IOException {
  int code = conn.getResponseCode();
  InputStream is = (code >= 200 && code < 300) ? conn.getInputStream() : conn.getErrorStream();
  byte[] result = is != null ? readAllBytes(is) : new byte[0];
  if (is != null) is.close();
  if (code < 200 || code >= 300) {
    throw new IOException("HTTP " + code + ": " + new String(result, "UTF-8"));
  }
  return result;
}

byte[] httpGetBytes(String urlStr) throws IOException {
  HttpURLConnection conn = openConnection(urlStr, "GET", null);
  return readResponse(conn);
}

String httpGetString(String urlStr) throws IOException {
  return new String(httpGetBytes(urlStr), "UTF-8");
}

byte[] httpPostJsonBytes(String urlStr, String jsonBody) throws IOException {
  HttpURLConnection conn = openConnection(urlStr, "POST", "application/json");
  conn.setDoOutput(true);
  byte[] bodyBytes = jsonBody.getBytes("UTF-8");
  OutputStream os = conn.getOutputStream();
  os.write(bodyBytes);
  os.close();
  return readResponse(conn);
}

String httpPostJsonString(String urlStr, String jsonBody) throws IOException {
  return new String(httpPostJsonBytes(urlStr, jsonBody), "UTF-8");
}

// Uploads a single file field as multipart/form-data (used for /stt).
byte[] httpPostMultipartFile(String urlStr, String fieldName, String fileName, byte[] fileBytes) throws IOException {
  String boundary = "----ProcessingBoundary" + System.currentTimeMillis();
  HttpURLConnection conn = openConnection(urlStr, "POST", "multipart/form-data; boundary=" + boundary);
  conn.setDoOutput(true);

  ByteArrayOutputStream body = new ByteArrayOutputStream();
  String prefix = "--" + boundary + "\r\n" +
    "Content-Disposition: form-data; name=\"" + fieldName + "\"; filename=\"" + fileName + "\"\r\n" +
    "Content-Type: audio/wav\r\n\r\n";
  body.write(prefix.getBytes("UTF-8"));
  body.write(fileBytes);
  String suffix = "\r\n--" + boundary + "--\r\n";
  body.write(suffix.getBytes("UTF-8"));
  byte[] bodyBytes = body.toByteArray();

  conn.setRequestProperty("Content-Length", String.valueOf(bodyBytes.length));
  OutputStream os = conn.getOutputStream();
  os.write(bodyBytes);
  os.close();

  return readResponse(conn);
}
