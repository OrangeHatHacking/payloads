#!/bin/bash

# HID gadget setup for Raspberry Pi Zero
# Must run before inject.sh
# Used by inject.service

modprobe libcomposite || true

GADGET_DIR=/sys/kernel/config/usb_gadget/pi_zero_badusb

# Cleanup old gadget
if [ -d "$GADGET_DIR" ]; then
  echo "Cleaning up existing gadget..."
  echo "" > "$GADGET_DIR/UDC" 2>/dev/null || true
  rm -rf "$GADGET_DIR"
fi

mkdir -p "$GADGET_DIR"
cd "$GADGET_DIR"

# Use real USB vendor/product IDs for better Windows compatibility
# Example: Logitech USB Keyboard
echo 0x046d > idVendor      # Logitech Inc.             
echo 0xc31c > idProduct     # Logitech USB Keyboard     
echo 0x0110 > bcdDevice     # v1.10
echo 0x0200 > bcdUSB        # USB 2.0

echo 0xEF > bDeviceClass
echo 0x02 > bDeviceSubClass
echo 0x01 > bDeviceProtocol

mkdir -p strings/0x409
echo "00000000001" > strings/0x409/serialnumber
echo "Logitech" > strings/0x409/manufacturer            
echo "Logitech USB Keyboard" > strings/0x409/product    

mkdir -p configs/c.1
echo 120 > configs/c.1/MaxPower

mkdir -p configs/c.1/strings/0x409                      
echo "USB HID Keyboard" > configs/c.1/strings/0x409/configuration  

mkdir -p functions/hid.usb0
echo 1 > functions/hid.usb0/protocol        # Keyboard
echo 1 > functions/hid.usb0/subclass        # Boot Interface
echo 8 > functions/hid.usb0/report_length

### NOTE: Descriptor is correct and standard — don't change
echo -ne '\x05\x01\x09\x06\xa1\x01\x05\x07\x19\xe0\x29\xe7\x15\x00\x25\x01\x75\x01\x95\x08\x81\x02\x95\x01\x75\x08\x81\x01\x95\x05\x75\x01\x05\x08\x19\x01\x29\x05\x91\x02\x95\x01\x75\x03\x91\x01\x95\x06\x75\x08\x15\x00\x25\x65\x05\x07\x19\x00\x29\x65\x81\x00\xc0' > functions/hid.usb0/report_desc

if [ ! -L configs/c.1/hid.usb0 ]; then
  ln -s functions/hid.usb0 configs/c.1/
fi

udevadm settle -t 5 || :

# Wait for USB controller
UDC_DEV=""
for i in {1..10}; do
  UDC_DEV=$(ls /sys/class/udc/ | head -n 1)
  if [ -n "$UDC_DEV" ]; then
    echo "Found UDC device: $UDC_DEV"
    break
  fi
  echo "Waiting for UDC device..."
  sleep 1
done

if [ -z "$UDC_DEV" ]; then
  echo "No UDC device found! Exiting."
  exit 1
fi

sleep 2

# Cleanly bind only after all setup is complete
echo "" > UDC || true
echo "$UDC_DEV" > UDC
echo "Gadget bound to $UDC_DEV"

