#!/bin/bash

# Variables
USERNAME="username"
REMOTE_IP="remote_ip"
FILE_TO_COPY="/path/to/file"
DESTINATION="/home/$USERNAME/Desktop/"

# Check for active SSH connection
if ssh -q "$USERNAME@$REMOTE_IP" exit; then
    echo "SSH connection is active. Proceeding to copy the file."
    # Copy the file using scp
    scp "$FILE_TO_COPY" "$USERNAME@$REMOTE_IP:$DESTINATION"
else
    echo "No active SSH connection. File copy aborted."
fi






#!/bin/bash

# Check if an axis argument is provided
if [ -z "$1" ]; then
  echo "Error: Please provide the axis to calibrate (X or Y)."
  exit 1
fi

axis="$1"
api_url="http://localhost:7125/printer/gcode/script" # Default Moonraker API URL

# Function to send gcode command
send_gcode() {
  local command="$1"
  curl -s -k -X POST -H "Content-Type: application/json" -d "{\"script\": \"$command\"}" "$api_url" > /dev/null
}

# Run Shaper_Calibrate based on the selected axis
case "$axis" in
  X|x)
    echo "Starting Shaper Calibration for X axis..."
    send_gcode "SHAPER_CALIBRATE AXIS=X"
    echo "Waiting for calibration data for X axis..."
    sleep 10 # Adjust this value if needed to ensure calibration completes
    ~/klipper/scripts/calibrate_shaper.py /tmp/calibration_data_x_*.csv -o ~/klipper_config/shaper_calibrate_x.png
    echo "Shaper calibration data for X axis processed and saved to ~/klipper_config/shaper_calibrate_x.png"
    ;;
  Y|y)
    echo "Starting Shaper Calibration for Y axis..."
    send_gcode "SHAPER_CALIBRATE AXIS=Y"
    echo "Waiting for calibration data for Y axis..."
    sleep 10 # Adjust this value if needed to ensure calibration completes
    ~/klipper/scripts/calibrate_shaper.py /tmp/calibration_data_y_*.csv -o ~/klipper_config/shaper_calibrate_y.png
    echo "Shaper calibration data for Y axis processed and saved to ~/klipper_config/shaper_calibrate_y.png"
    ;;
  *)
    echo "Error: Invalid axis provided. Please use X or Y."
    exit 1
    ;;
esac

echo "Shaper Calibration process completed for axis: $axis"
exit 0
