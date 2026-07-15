#!/bin/bash

# SETTINGS vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

APIKEY=$(cat "$HOME/.owm-key")
CITY_NAME="Shenzhen"
COUNTRY_CODE="CN"
LANG="en"
UNITS="metric"

HOT_TEMP=23
COLD_TEMP=10

# ICON COLORS（Waybar 通过 CSS 控制颜色，这里仅保留图标）
COLOR_ERR="#f43753"

# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

if [ -z "$CITY_NAME" ]; then
    IP=$(curl -s ifconfig.me)
    IPCURL=$(curl -s https://ipinfo.io/$IP)
    CITY_NAME=$(echo "$IPCURL" | jq -r ".city")
    COUNTRY_CODE=$(echo "$IPCURL" | jq -r ".country")
fi

# ------------------- 请求天气数据 -------------------
if [ "$UNITS" = "kelvin" ]; then
    UNIT_URL=""
else
    UNIT_URL="&units=$UNITS"
fi

URL="https://api.openweathermap.org/data/2.5/weather?appid=$APIKEY$UNIT_URL&lang=$LANG&q=$(echo "$CITY_NAME" | sed 's/ /%20/g'),${COUNTRY_CODE}"

RESPONSE=$(curl -s "$URL")
CODE="$?"
if [ $CODE -ne 0 ]; then
    echo "{\"text\":\"API Error\",\"class\":\"weather-error\",\"tooltip\":\"curl error $CODE\"}"
    exit 1
fi

RESPONSECODE=$(echo "$RESPONSE" | jq .cod)
if [ "$RESPONSECODE" != "200" ]; then
    MSG=$(echo "$RESPONSE" | jq -r .message)
    echo "{\"text\":\"API Error\",\"class\":\"weather-error\",\"tooltip\":\"$MSG\"}"
    exit 1
fi

# ------------------- 解析数据 -------------------
WID=$(echo "$RESPONSE" | jq .weather[0].id)
DESC=$(echo "$RESPONSE" | jq -r .weather[0].description)
TEMP=$(echo "$RESPONSE" | jq .main.temp | cut -d "." -f 1)
HUMIDITY=$(echo "$RESPONSE" | jq .main.humidity)
WIND=$(echo "$RESPONSE" | jq .wind.speed)
SUNRISE=$(echo "$RESPONSE" | jq .sys.sunrise)
SUNSET=$(echo "$RESPONSE" | jq .sys.sunset)
DATE=$(date +%s)

# ------------------- 选择图标 -------------------
if [ $WID -le 232 ]; then
    ICON="" # Thunderstorm
elif [ $WID -le 321 ]; then
    ICON="" # Drizzle
elif [ $WID -le 531 ]; then
    ICON="" # Rain
elif [ $WID -le 622 ]; then
    ICON="" # Snow
elif [ $WID -le 771 ]; then
    ICON="" # Fog
elif [ $WID -eq 781 ]; then
    ICON="" # Tornado
elif [ $WID -eq 800 ]; then
    if [ $DATE -ge $SUNRISE ] && [ $DATE -le $SUNSET ]; then
        ICON="" # Sunny
    else
        ICON="" # Night
    fi
elif [ $WID -le 804 ]; then
    ICON="" # Overcast
else
    ICON="" # Unknown
fi

# ------------------- 温度图标 -------------------
if [ "$UNITS" = "metric" ]; then
    TEMP_ICON="󰔄"
elif [ "$UNITS" = "imperial" ]; then
    TEMP_ICON="󰔅"
else
    TEMP_ICON="󰔆"
fi

# 温度色彩分级
if [ "$TEMP" -le $COLD_TEMP ]; then
    CLASS="weather-cold"
elif [ "$TEMP" -ge $HOT_TEMP ]; then
    CLASS="weather-hot"
else
    CLASS="weather-normal"
fi

# ------------------- 生成输出 -------------------
# TEXT="$ICON ${DESC^} | $TEMP$TEMP_ICON"
# TOOLTIP="🌡️ 温度: ${TEMP}°C\n💧 湿度: ${HUMIDITY}%\n🌬️ 风速: ${WIND} m/s"
TEXT="$TEMP$TEMP_ICON"
TOOLTIP="  天气: ${ICON} ${DESC^}\n🌡️ 温度: ${TEMP}°C\n💧 湿度: ${HUMIDITY}%\n🌬️ 风速: ${WIND} m/s"

# Waybar JSON 输出
echo "{\"text\":\"$TEXT\", \"class\":\"$CLASS\", \"tooltip\":\"$TOOLTIP\"}"
