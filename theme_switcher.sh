#!/bin/bash

# Log settings
# Get the directory where the script is located
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/theme_switcher.log"
MAX_LOG_SIZE=$((1024 * 1024)) # 1MB
MAX_LOG_FILES=3

# Function to create log directory if it doesn't exist
ensure_log_dir() {
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR"
    fi
}

# Function for log rotation
rotate_logs() {
    ensure_log_dir
    if [ ! -f "$LOG_FILE" ]; then
        touch "$LOG_FILE" # Create log file if it doesn't exist
        return
    fi

    # On macOS, use stat -f%z.
    local current_size=$(stat -f%z "$LOG_FILE" 2>/dev/null || echo 0)

    if [ "$current_size" -ge "$MAX_LOG_SIZE" ]; then
        # Remove the oldest log file before rotating
        if [ -f "$LOG_FILE.$MAX_LOG_FILES" ]; then
            rm "$LOG_FILE.$MAX_LOG_FILES"
        fi
        
        # Shift older logs up
        for i in $(seq $(($MAX_LOG_FILES - 1)) -1 1); do
            if [ -f "$LOG_FILE.$i" ]; then
                mv "$LOG_FILE.$i" "$LOG_FILE.$(($i + 1))"
            fi
        done

        # Rotate the current log file
        if [ -f "$LOG_FILE" ]; then
            mv "$LOG_FILE" "$LOG_FILE.1"
        fi
        touch "$LOG_FILE"
    fi
}

# Function to log messages
log_message() {
    # Description: Logs a message to the log file and, by default, echoes it to the terminal.
    # Usage: log_message "Your message here" [no_echo]
    # Arguments:
    #   $1 (required): The message string to log.
    #   $2 (optional): If set to "no_echo", the message will not be echoed to the terminal.
    #                  Otherwise, the message will be echoed to the terminal.
    # Example 1: Log and echo to terminal
    #   log_message "This is a test message."
    # Example 2: Log only (do not echo to terminal)
    #   log_message "This message is for the log file only." "no_echo"

    local message="$1"
    local no_echo_to_terminal="$2"

    ensure_log_dir
    rotate_logs
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$LOG_FILE"

    if [ "$no_echo_to_terminal" != "no_echo" ]; then
        echo "$message"
    fi
}

# 檢查是否連接 Paperlike253c 顯示器
check_paperlike() {
    if system_profiler SPDisplaysDataType | grep -i "paperlike253c" > /dev/null; then
        return 0  # 找到 Paperlike 顯示器
    else
        return 1  # 未找到 Paperlike 顯示器
    fi
}

# 檢測目前主題
get_current_theme() {
    # 使用指定的 osascript 命令檢測深色模式狀態
    is_dark_mode=$(osascript -e 'tell application "System Events" to tell appearance preferences to return dark mode')
    
    if [ "$is_dark_mode" = "true" ]; then
        echo "Dark"
    else
        echo "Light"
    fi
}

# 切換到淺色主題
switch_to_light_theme() {
    osascript -e 'tell app "System Events" to tell appearance preferences to set dark mode to false'
    disable_true_tone

    log_message "已切換到淺色主題"
}

# 切換到深色主題
switch_to_dark_theme() {
    osascript -e 'tell app "System Events" to tell appearance preferences to set dark mode to true'
    enable_true_tone

    log_message "已切換到深色主題"
}

enable_true_tone() {
    shortcuts run 開啟原彩
    log_message "已開啟 True Tone"
}

disable_true_tone() {
    shortcuts run 關閉原彩
    log_message "已關閉 True Tone"
}


# 主程式
main() {
    log_message "Script started." "no_echo"

    # 檢查是否連接 Paperlike 顯示器
    if check_paperlike; then
        keepWhite=1
        log_message "檢測到 Paperlike 顯示器，保持淺色主題"
    else
        keepWhite=0
        log_message "未檢測到 Paperlike 顯示器"
    fi

    # 獲取當前主題
    current_theme=$(get_current_theme)
    log_message "當前主題: $current_theme"

    # 根據條件切換主題
    if [ $keepWhite -eq 1 ] && [ "$current_theme" = "Dark" ]; then
        log_message "Paperlike 顯示器連接中，將深色主題切換為淺色主題..."
        switch_to_light_theme
    elif [ $keepWhite -eq 0 ] && [ "$current_theme" = "Light" ]; then
        log_message "未連接 Paperlike 顯示器，將淺色主題切換為深色主題..."
        switch_to_dark_theme
    else
        log_message "主題已經符合當前顯示器設定，無需切換"
    fi
    log_message "Script finished." "no_echo"
}

# 執行主程式
main
