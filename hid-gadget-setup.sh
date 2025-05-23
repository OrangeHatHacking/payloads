#!/bin/bash

# setup for HID Gadget
# must be done before inject.sh is run
# consult inject.service for proper order


modprobe libcomposite || true

GADGET_DIR=/sys/kernel/config/usb_gadget/pi_zero_badusb

# Cleanup old gadget if exists
if [ -d "$GADGET_DIR" ]; then
  echo "Cleaning up existing gadget..."
  echo "" > "$GADGET_DIR/UDC" 2>/dev/null || true
  rm -rf "$GADGET_DIR"
fi

mkdir -p "$GADGET_DIR"
cd "$GADGET_DIR"

echo 0x1d6b > idVendor  # Linux Foundation
echo 0x0104 > idProduct # Multifunction Composite Gadget
echo 0x0100 > bcdDevice
echo 0x0200 > bcdUSB

mkdir -p strings/0x409
echo "fedcba9876543210" > strings/0x409/serialnumber
echo "DELL" > strings/0x409/manufacturer
echo "KeyboardPeripheral" > strings/0x409/product

mkdir -p configs/c.1
echo 120 > configs/c.1/MaxPower

mkdir -p functions/hid.usb0
echo 1 > functions/hid.usb0/protocol
echo 1 > functions/hid.usb0/subclass
echo 8 > functions/hid.usb0/report_length
echo -ne '\x05\x01\x09\x06\xa1\x01\x05\x07\x19\xe0\x29\xe7\x15\x00\x25\x01\x75\x01\x95\x08\x81\x02\x95\x01\x75\x08\x81\x01\x95\x05\x75\x01\x05\x08\x19\x01\x29\x05\x91\x02\x95\x01\x75\x03\x91\x01\x95\x06\x75\x08\x15\x00\x25\x65\x05\x07\x19\x00\x29\x65\x81\x00\xc0' > functions/hid.usb0/report_desc

# Link function to configuration if not linked yet
if [ ! -L configs/c.1/hid.usb0 ]; then
  ln -s functions/hid.usb0 configs/c.1/
fi

udevadm settle -t 5 || :

# Wait for UDC device to appear before binding
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

# Bind gadget
echo "" > UDC || true   # Unbind first
echo "$UDC_DEV" > UDC
echo "Gadget bound to $UDC_DEV"

sleep 1