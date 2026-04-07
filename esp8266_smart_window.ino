#include <ESP8266WiFi.h>
#include <PubSubClient.h>
#include <Stepper.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <EEPROM.h>

// --- Налаштування мережі ---
const char* ssid = "TP-Link_E81F";
const char* password = "1";
const char* mqtt_server = "192.168.0.101";


// --- EEPROM адреси ---
#define EEPROM_SIZE 512
#define EEPROM_POSITION_ADDR 0
#define EEPROM_WAKEY_ENABLED_ADDR 4
#define EEPROM_WAKEY_MODE_ADDR 5
#define EEPROM_WAKEY_TIME_ADDR 25
#define EEPROM_WAKEY_MINUTES_ADDR 35
#define EEPROM_WAKEY_OPEN_ADDR 39
#define EEPROM_TEMP_ENABLED_ADDR 43
#define EEPROM_TEMP_THRESHOLD_ADDR 44
#define EEPROM_TEMP_CLOSURE_ADDR 48
#define EEPROM_WEATHER_ENABLED_ADDR 52
#define EEPROM_WEATHER_CONDITIONS_ADDR 53
#define EEPROM_WEATHER_OPEN_ADDR 153
#define EEPROM_MAGIC_NUMBER_ADDR 157
#define EEPROM_MAGIC_NUMBER 0xAB12

// --- Піни ---
#define OLED_MOSI   4  // D2
#define OLED_CLK    5  // D1
#define OLED_DC     2  // D4
#define OLED_RESET 16  // D0
#define OLED_CS    -1  // GND

Stepper myStepper(2048, 14, 13, 12, 15); // D5, D7, D6, D8

Adafruit_SSD1306 display(128, 64, OLED_MOSI, OLED_CLK, OLED_DC, OLED_RESET, OLED_CS);
WiFiClient espClient;
PubSubClient client(espClient);

// Змінні стану
int currentPosition = 0;  // 0-100%
int targetPosition = 0;

// Manual
bool manualMode = true;

// Wakey
bool wakeyEnabled = false;
String wakeyMode = "at_dawn";
String wakeyTime = "";
int wakeyMinutesBefore = 0;
int wakeyOpenPercent = 100;

// Temperature
bool tempEnabled = false;
float tempThreshold = 25.0;
int tempClosurePercent = 0;

// Weather
bool weatherEnabled = false;
String weatherConditions = "";
int weatherOpenPercent = 0;

unsigned long lastDisplayUpdate = 0;
const unsigned long DISPLAY_UPDATE_INTERVAL = 1000; // Оновлювати дисплей раз на секунду

// === EEPROM функції ===
void savePositionToEEPROM() {
    EEPROM.put(EEPROM_POSITION_ADDR, currentPosition);
    EEPROM.put(EEPROM_MAGIC_NUMBER_ADDR, EEPROM_MAGIC_NUMBER);
    EEPROM.commit();
    Serial.printf("EEPROM: Збережено позицію: %d%%\n", currentPosition);
}

void saveAutoSettingsToEEPROM() {
    EEPROM.put(EEPROM_WAKEY_ENABLED_ADDR, wakeyEnabled);

    // Збереження wakeyMode (макс 20 символів)
    char modeBuffer[20] = {0};
    wakeyMode.toCharArray(modeBuffer, 20);
    for (int i = 0; i < 20; i++) {
        EEPROM.write(EEPROM_WAKEY_MODE_ADDR + i, modeBuffer[i]);
    }

    // Збереження wakeyTime (макс 10 символів)
    char timeBuffer[10] = {0};
    wakeyTime.toCharArray(timeBuffer, 10);
    for (int i = 0; i < 10; i++) {
        EEPROM.write(EEPROM_WAKEY_TIME_ADDR + i, timeBuffer[i]);
    }

    EEPROM.put(EEPROM_WAKEY_MINUTES_ADDR, wakeyMinutesBefore);

    EEPROM.put(EEPROM_WAKEY_OPEN_ADDR, wakeyOpenPercent);

    EEPROM.put(EEPROM_TEMP_ENABLED_ADDR, tempEnabled);
    EEPROM.put(EEPROM_TEMP_THRESHOLD_ADDR, tempThreshold);
    EEPROM.put(EEPROM_TEMP_CLOSURE_ADDR, tempClosurePercent);

    EEPROM.put(EEPROM_WEATHER_ENABLED_ADDR, weatherEnabled);

    // Збереження рядка weatherConditions (макс 100 символів)
    char condBuffer[100] = {0};
    weatherConditions.toCharArray(condBuffer, 100);
    for (int i = 0; i < 100; i++) {
        EEPROM.write(EEPROM_WEATHER_CONDITIONS_ADDR + i, condBuffer[i]);
    }

    EEPROM.put(EEPROM_WEATHER_OPEN_ADDR, weatherOpenPercent);
    EEPROM.put(EEPROM_MAGIC_NUMBER_ADDR, EEPROM_MAGIC_NUMBER);
    EEPROM.commit();

    Serial.println("EEPROM: Збережено автоматичні налаштування");
}

void loadSettingsFromEEPROM() {
    uint16_t magic;
    EEPROM.get(EEPROM_MAGIC_NUMBER_ADDR, magic);

    if (magic != EEPROM_MAGIC_NUMBER) {
        Serial.println("EEPROM: Перший запуск, дані не знайдено");
        // Ініціалізувати значеннями за замовчуванням
        currentPosition = 0;
        targetPosition = 0;
        wakeyEnabled = false;
        wakeyMode = "at_dawn";
        wakeyTime = "07:00";
        wakeyMinutesBefore = 0;
        wakeyOpenPercent = 100;
        tempEnabled = false;
        tempThreshold = 25;
        tempClosurePercent = 0;
        weatherEnabled = false;
        weatherConditions = "";
        weatherOpenPercent = 0;
        return;
    }

    // Завантаження позиції
    EEPROM.get(EEPROM_POSITION_ADDR, currentPosition);
    // Валідація позиції
    if (currentPosition < 0 || currentPosition > 100) {
        currentPosition = 0;
        Serial.println("EEPROM: Невалідна позиція, встановлено 0");
    }
    targetPosition = currentPosition;
    Serial.printf("EEPROM: Завантажено позицію: %d%%\n", currentPosition);

    // Завантаження wakey налаштувань
    EEPROM.get(EEPROM_WAKEY_ENABLED_ADDR, wakeyEnabled);

    char modeBuffer[20] = {0};
    for (int i = 0; i < 20; i++) {
        modeBuffer[i] = EEPROM.read(EEPROM_WAKEY_MODE_ADDR + i);
        if (modeBuffer[i] == 0) break; // Stop at null terminator
    }
    wakeyMode = String(modeBuffer);
    if (wakeyMode.length() == 0 || (wakeyMode != "at_dawn" && wakeyMode != "custom")) {
        wakeyMode = "at_dawn";
    }

    char timeBuffer[10] = {0};
    for (int i = 0; i < 10; i++) {
        timeBuffer[i] = EEPROM.read(EEPROM_WAKEY_TIME_ADDR + i);
        if (timeBuffer[i] == 0) break; // Stop at null terminator
    }
    wakeyTime = String(timeBuffer);
    if (wakeyTime.length() == 0) {
        wakeyTime = "07:00";
    }

    int loadedMinutes;
    EEPROM.get(EEPROM_WAKEY_MINUTES_ADDR, loadedMinutes);
    // Валідація хвилин (0-60)
    if (loadedMinutes < 0 || loadedMinutes > 60) {
        wakeyMinutesBefore = 0;
        Serial.printf("EEPROM: Невалідні хвилини (%d), встановлено 0\n", loadedMinutes);
    } else {
        wakeyMinutesBefore = loadedMinutes;
    }

    int loadedWakeyOpen;
    EEPROM.get(EEPROM_WAKEY_OPEN_ADDR, loadedWakeyOpen);
    // Валідація відсотка відкриття (0-100)
    if (loadedWakeyOpen < 0 || loadedWakeyOpen > 100) {
        wakeyOpenPercent = 100;
        Serial.printf("EEPROM: Невалідний wakey відсоток (%d), встановлено 100\n", loadedWakeyOpen);
    } else {
        wakeyOpenPercent = loadedWakeyOpen;
    }

    // Завантаження temperature налаштувань
    EEPROM.get(EEPROM_TEMP_ENABLED_ADDR, tempEnabled);

    float loadedThreshold;
    EEPROM.get(EEPROM_TEMP_THRESHOLD_ADDR, loadedThreshold);
    // Валідація температури (15-40)
    if (loadedThreshold < 15 || loadedThreshold > 40) {
        tempThreshold = 25;
        Serial.printf("EEPROM: Невалідний поріг температури (%.1f), встановлено 25\n", loadedThreshold);
    } else {
        tempThreshold = loadedThreshold;
    }

    int loadedTempClosure;
    EEPROM.get(EEPROM_TEMP_CLOSURE_ADDR, loadedTempClosure);
    // Валідація відсотка закриття (0-100)
    if (loadedTempClosure < 0 || loadedTempClosure > 100) {
        tempClosurePercent = 0;
        Serial.printf("EEPROM: Невалідний відсоток закриття (%d), встановлено 0\n", loadedTempClosure);
    } else {
        tempClosurePercent = loadedTempClosure;
    }

    // Завантаження weather налаштувань
    EEPROM.get(EEPROM_WEATHER_ENABLED_ADDR, weatherEnabled);

    char condBuffer[100] = {0};
    for (int i = 0; i < 100; i++) {
        condBuffer[i] = EEPROM.read(EEPROM_WEATHER_CONDITIONS_ADDR + i);
        if (condBuffer[i] == 0) break; // Stop at null terminator
    }
    weatherConditions = String(condBuffer);

    int loadedWeatherOpen;
    EEPROM.get(EEPROM_WEATHER_OPEN_ADDR, loadedWeatherOpen);
    // Валідація відсотка відкриття (0-100)
    if (loadedWeatherOpen < 0 || loadedWeatherOpen > 100) {
        weatherOpenPercent = 0;
        Serial.printf("EEPROM: Невалідний відсоток відкриття (%d), встановлено 0\n", loadedWeatherOpen);
    } else {
        weatherOpenPercent = loadedWeatherOpen;
    }

    Serial.println("EEPROM: Всі налаштування завантажено успішно");
}

void publishStoredSettings() {
    // Публікація збережених налаштувань після підключення
    client.publish("smart_window/feedback/position", String(currentPosition).c_str(), true);

    client.publish("smart_window/feedback/wakey/enabled", wakeyEnabled ? "on" : "off", true);
    client.publish("smart_window/feedback/wakey/mode", wakeyMode.c_str(), true);
    client.publish("smart_window/feedback/wakey/time", wakeyTime.c_str(), true);
    client.publish("smart_window/feedback/wakey/minutes", String(wakeyMinutesBefore).c_str(), true);
    client.publish("smart_window/feedback/wakey/open", String(wakeyOpenPercent).c_str(), true);

    client.publish("smart_window/feedback/temp/enabled", tempEnabled ? "on" : "off", true);
    client.publish("smart_window/feedback/temp/threshold", String(tempThreshold).c_str(), true);
    client.publish("smart_window/feedback/temp/closure", String(tempClosurePercent).c_str(), true);

    client.publish("smart_window/feedback/weather/enabled", weatherEnabled ? "on" : "off", true);
    client.publish("smart_window/feedback/weather/conditions", weatherConditions.c_str(), true);
    client.publish("smart_window/feedback/weather/open", String(weatherOpenPercent).c_str(), true);

    Serial.println("MQTT: Опубліковано збережені налаштування");
}

void showStatus(String msg) {
    display.clearDisplay();
    display.setTextSize(1);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(0, 10);
    display.println("STATUS:");
    display.println(msg);
    display.display();
    Serial.println(msg);
}

void updateDisplay() {
    unsigned long now = millis();
    if (now - lastDisplayUpdate < DISPLAY_UPDATE_INTERVAL) {
        return; // Не оновлювати надто часто
    }
    lastDisplayUpdate = now;

    display.clearDisplay();
    display.setTextSize(1);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(0, 0);

    display.print("Pos: ");
    display.print(currentPosition);
    display.println("%");

    // Статус auto modes
    display.print("Auto: ");
    if (tempEnabled) display.print("T ");
    if (weatherEnabled) display.print("W ");
    if (wakeyEnabled) display.print("WK");
    display.println();

    display.display();
}

void moveToPosition(int newPosition) {
    if (newPosition < 0) newPosition = 0;
    if (newPosition > 100) newPosition = 100;

    targetPosition = newPosition;
    int diff = targetPosition - currentPosition;

    if (diff != 0) {
        int totalSteps = (diff * 2048) / 100;
        int direction = (totalSteps > 0) ? 1 : -1;
        int absSteps = abs(totalSteps);

        Serial.printf("Рух: %d%% -> %d%% (%d кроків)\n", currentPosition, targetPosition, totalSteps);

        // Рухаємося по 10 кроків за раз, щоб не блокувати систему
        for (int i = 0; i < absSteps; i += 10) {
            int stepsToMove = (absSteps - i >= 10) ? 10 : (absSteps - i);
            myStepper.step(stepsToMove * direction);

            // КРИТИЧНО ВАЖЛИВО: дозволяємо ESP8266 обробити Wi-Fi та MQTT
            yield();
            client.loop();
        }

        currentPosition = targetPosition;
        savePositionToEEPROM(); // Зберегти нову позицію
        client.publish("smart_window/feedback/position", String(currentPosition).c_str(), true);
        updateDisplay();
    }
}

void setup_wifi() {
    showStatus("WiFi Connecting...");
    Serial.println("\n=== Підключення до WiFi ===");
    Serial.print("SSID: ");
    Serial.println(ssid);
    Serial.print("Password length: ");
    Serial.println(strlen(password));

    // Встановлюємо режим станції
    WiFi.mode(WIFI_STA);
    WiFi.disconnect();
    delay(100);

    WiFi.begin(ssid, password);
    int counter = 0;
    while (WiFi.status() != WL_CONNECTED && counter < 40) {
        delay(500);
        Serial.print(".");
        if (counter % 10 == 0 && counter > 0) {
            Serial.print(" [status:");
            Serial.print(WiFi.status());
            Serial.print("] ");
        }
        counter++;
    }
    Serial.println();

    if (WiFi.status() == WL_CONNECTED) {
        showStatus("WiFi OK!");
        Serial.println("✓ WiFi підключено успішно!");
        Serial.print("IP адреса: ");
        Serial.println(WiFi.localIP());
        Serial.print("MAC адреса: ");
        Serial.println(WiFi.macAddress());
        Serial.print("Сила сигналу (RSSI): ");
        Serial.print(WiFi.RSSI());
        Serial.println(" dBm");
        delay(1000);
    } else {
        showStatus("WiFi Error!");
        Serial.println("✗ Помилка підключення WiFi!");
        Serial.print("Фінальний статус: ");
        Serial.println(WiFi.status());
        Serial.println("Можливі причини:");
        Serial.println("- Неправильний пароль");
        Serial.println("- Неправильний SSID");
        Serial.println("- Слабкий сигнал WiFi");
        Serial.println("- Роутер не відповідає");
    }
}

void callback(char* topic, byte* payload, unsigned int length) {
    String message = "";
    for (int i = 0; i < length; i++) message += (char)payload[i];
    String t = String(topic);

    Serial.printf("Топік: %s, Повідомлення: %s\n", t.c_str(), message.c_str());

    // Manual
    if (t == "smart_window/manual/position") {
        int pos = message.toInt();
        moveToPosition(pos);
    }

    // Save command
    else if (t == "smart_window/auto/save") {
        saveAutoSettingsToEEPROM();
        client.publish("smart_window/feedback/saved", "ok");
        Serial.println("Налаштування збережено в EEPROM");
    }

    else if (t == "smart_window/request/state") {
        publishStoredSettings();
        Serial.println("MQTT: Отримано запит стану, відправлено збережені налаштування");
    }

    // Wakey
    else if (t == "smart_window/auto/wakey/state") {
        wakeyEnabled = (message == "on");
        Serial.printf("Wakey enabled: %s\n", wakeyEnabled ? "true" : "false");
    }
    else if (t == "smart_window/auto/wakey/mode") {
        wakeyMode = message;
        Serial.printf("Wakey mode: %s\n", wakeyMode.c_str());
    }
    else if (t == "smart_window/auto/wakey/time") {
        wakeyTime = message;
        Serial.printf("Wakey time: %s\n", wakeyTime.c_str());
    }
    else if (t == "smart_window/auto/wakey/minutes_before") {
        wakeyMinutesBefore = message.toInt();
        Serial.printf("Wakey minutes before: %d\n", wakeyMinutesBefore);
    }
    else if (t == "smart_window/auto/wakey/open_percent") {
        wakeyOpenPercent = message.toInt();
        Serial.printf("Wakey open percent: %d%%\n", wakeyOpenPercent);
    }

        // Temperature
    else if (t == "smart_window/auto/temp/state") {
        tempEnabled = (message == "on");
        Serial.printf("Temp enabled: %s\n", tempEnabled ? "true" : "false");
    }
    else if (t == "smart_window/auto/temp/threshold") {
        tempThreshold = message.toFloat();
        Serial.printf("Temp threshold: %.1f\n", tempThreshold);
    }
    else if (t == "smart_window/auto/temp/closure") {
        tempClosurePercent = message.toInt();
        Serial.printf("Temp closure: %d%%\n", tempClosurePercent);
    }

        // Weather
    else if (t == "smart_window/auto/weather/state") {
        weatherEnabled = (message == "on");
        Serial.printf("Weather enabled: %s\n", weatherEnabled ? "true" : "false");
    }
    else if (t == "smart_window/auto/weather/conditions") {
        weatherConditions = message;
        Serial.printf("Weather conditions: %s\n", weatherConditions.c_str());
    }
    else if (t == "smart_window/auto/weather/open_percent") {
        weatherOpenPercent = message.toInt();
        Serial.printf("Weather open percent: %d%%\n", weatherOpenPercent);
    }

    // === EXECUTE COMMANDS (від Flutter) ===

    // Execute Wakey: "HH:MM,position,mode"
    else if (t == "smart_window/execute/wakey") {
        Serial.println("EXECUTE: Wakey команда отримана");
        int firstComma = message.indexOf(',');
        int secondComma = message.indexOf(',', firstComma + 1);

        if (firstComma > 0 && secondComma > firstComma) {
            String targetTime = message.substring(0, firstComma);
            int position = message.substring(firstComma + 1, secondComma).toInt();
            String mode = message.substring(secondComma + 1);

            Serial.printf("Wakey: час=%s, позиція=%d%%, режим=%s\n", targetTime.c_str(), position, mode.c_str());

            // Тут ESP8266 може запустити таймер до targetTime або виконати одразу
            // Для простоти - виконуємо одразу
            moveToPosition(position);
            client.publish("smart_window/feedback/status", ("Wakey executed: " + String(position) + "%").c_str());
        }
    }

    // Execute Temperature: "current_temp,threshold,closure_percent"
    else if (t == "smart_window/execute/temperature") {
        Serial.println("EXECUTE: Temperature команда отримана");
        int firstComma = message.indexOf(',');
        int secondComma = message.indexOf(',', firstComma + 1);

        if (firstComma > 0 && secondComma > firstComma) {
            float currentTemp = message.substring(0, firstComma).toFloat();
            float threshold = message.substring(firstComma + 1, secondComma).toFloat();
            int closurePercent = message.substring(secondComma + 1).toInt();

            Serial.printf("Temperature: поточна=%.1f°C, поріг=%.1f°C, закриття=%d%%\n", currentTemp, threshold, closurePercent);

            // Перевірити умову і виконати
            if (currentTemp >= threshold) {
                Serial.printf("Температура вища за поріг! Закриваємо на %d%%\n", closurePercent);
                moveToPosition(closurePercent);
                client.publish("smart_window/feedback/status", ("Temp control: closed to " + String(closurePercent) + "%").c_str());
            } else {
                Serial.println("Температура нижча за поріг, рух не потрібен");
            }
        }
    }

    // Execute Weather: "current_condition,selected_conditions,open_percent"
    else if (t == "smart_window/execute/weather") {
        Serial.println("EXECUTE: Weather команда отримана");
        int firstComma = message.indexOf(',');
        int secondComma = message.indexOf(',', firstComma + 1);

        if (firstComma > 0 && secondComma > firstComma) {
            String currentCondition = message.substring(0, firstComma);
            String selectedConditions = message.substring(firstComma + 1, secondComma);
            int openPercent = message.substring(secondComma + 1).toInt();

            currentCondition.toLowerCase();
            selectedConditions.toLowerCase();

            Serial.printf("Weather: поточна=%s, вибрані=%s, відкриття=%d%%\n", currentCondition.c_str(), selectedConditions.c_str(), openPercent);

            // Перевірити чи є збіг
            bool matches = false;
            if (selectedConditions.indexOf("rain") >= 0 && currentCondition.indexOf("rain") >= 0) matches = true;
            if (selectedConditions.indexOf("thunderstorm") >= 0 && currentCondition.indexOf("thunderstorm") >= 0) matches = true;
            if (selectedConditions.indexOf("clouds") >= 0 && (currentCondition.indexOf("clouds") >= 0 || currentCondition.indexOf("cloud") >= 0)) matches = true;

            if (matches) {
                Serial.printf("Погода співпадає! Відкриваємо на %d%%\n", openPercent);
                moveToPosition(openPercent);
                client.publish("smart_window/feedback/status", ("Weather control: opened to " + String(openPercent) + "%").c_str());
            } else {
                Serial.println("Погода не співпадає, рух не потрібен");
            }
        }
    }

    updateDisplay();
}

void reconnect() {
    while (!client.connected()) {
        showStatus("MQTT Connecting...");
        Serial.println("Спроба підключення до MQTT...");

        if (client.connect("ESP8266_SmartWindow")) {
            showStatus("MQTT OK!");
            Serial.println("MQTT підключено!");

            // Підписка на всі топіки
            client.subscribe("smart_window/manual/position");
            Serial.println("Підписано: smart_window/manual/position");

            client.subscribe("smart_window/auto/save");
            Serial.println("Підписано: smart_window/auto/save");

            client.subscribe("smart_window/request/state");
            Serial.println("Підписано: smart_window/request/state");

            client.subscribe("smart_window/auto/wakey/state");
            client.subscribe("smart_window/auto/wakey/mode");
            client.subscribe("smart_window/auto/wakey/time");
            client.subscribe("smart_window/auto/wakey/minutes_before");
            client.subscribe("smart_window/auto/wakey/open_percent");
            Serial.println("Підписано: wakey топіки");

            client.subscribe("smart_window/auto/temp/state");
            client.subscribe("smart_window/auto/temp/threshold");
            client.subscribe("smart_window/auto/temp/closure");
            Serial.println("Підписано: temp топіки");

            client.subscribe("smart_window/auto/weather/state");
            client.subscribe("smart_window/auto/weather/conditions");
            client.subscribe("smart_window/auto/weather/open_percent");
            Serial.println("Підписано: weather топіки");

            client.subscribe("smart_window/execute/wakey");
            client.subscribe("smart_window/execute/temperature");
            client.subscribe("smart_window/execute/weather");
            Serial.println("Підписано: execute топіки");

            delay(1000);
            publishStoredSettings(); // Опублікувати збережені налаштування

            updateDisplay();
        } else {
            showStatus("MQTT Retry in 5s");
            Serial.print("Помилка MQTT, rc=");
            Serial.print(client.state());
            Serial.println(". Повтор через 5 сек...");
            delay(5000);
        }
    }
}

void setup() {
    Serial.begin(115200);
    Serial.println("\n\n=== ESP8266 Smart Window ===");

    // Ініціалізація EEPROM
    EEPROM.begin(EEPROM_SIZE);
    loadSettingsFromEEPROM(); // Завантажити збережені налаштування

    // Ініціалізація дисплея
    if(!display.begin(SSD1306_SWITCHCAPVCC)) {
        Serial.println("OLED помилка!");
        for(;;);
    }

    display.clearDisplay();
    display.display();

    showStatus("System Start...");
    delay(1000);

    setup_wifi();

    client.setServer(mqtt_server, 1883);
    client.setCallback(callback);
    client.setBufferSize(512);

    myStepper.setSpeed(10);

    updateDisplay();
    Serial.println("Система готова!");
}

void loop() {
    if (!client.connected()) {
        reconnect();
    }
    client.loop();


    // Оновлювати дисплей
    updateDisplay();
}
