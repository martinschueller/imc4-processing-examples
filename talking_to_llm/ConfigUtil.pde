// ---------------------------------------------------------------------------
// Load KEY=VALUE pairs from a .env file in the sketch folder (gitignored).
// Copy .env.example to .env and fill in your token.
// ---------------------------------------------------------------------------

String API_KEY = "";

boolean isApiKeyConfigured() {
  return API_KEY != null
    && API_KEY.length() > 0
    && !API_KEY.equals("CHANGE_API_KEY_HERE")
    && !API_KEY.equals("YOUR_API_KEY_HERE");
}

void loadConfig() {
  API_KEY = loadEnvValue("API_KEY", "");
}

String loadEnvValue(String key, String fallback) {
  File envFile = new File(sketchPath(".env"));
  if (!envFile.exists()) {
    return fallback;
  }

  BufferedReader reader = null;
  try {
    reader = new BufferedReader(new FileReader(envFile));
    String line;
    while ((line = reader.readLine()) != null) {
      line = line.trim();
      if (line.length() == 0 || line.startsWith("#")) {
        continue;
      }
      int eq = line.indexOf('=');
      if (eq <= 0) {
        continue;
      }
      String envKey = line.substring(0, eq).trim();
      String value = line.substring(eq + 1).trim();
      if ((value.startsWith("\"") && value.endsWith("\""))
        || (value.startsWith("'") && value.endsWith("'"))) {
        value = value.substring(1, value.length() - 1);
      }
      if (envKey.equals(key)) {
        return value;
      }
    }
  } catch (IOException e) {
    println("WARN: could not read .env — " + e.getMessage());
  } finally {
    if (reader != null) {
      try {
        reader.close();
      } catch (IOException ignored) {}
    }
  }
  return fallback;
}
