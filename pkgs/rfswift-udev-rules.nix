# Consolidated udev rules for RF Swift devices whose own package ships none, so
# `rfswift nix udev` can make them work without root. Devices whose package
# already ships a rule keep using that (authoritative) rule; this file only adds
# what is otherwise missing.
#
# VID:PIDs here are the well-documented ones. For a shared vendor id (FTDI 0403,
# Microchip 04d8, ST 0483, PJRC/VOTI 16c0, Realtek 0bda, Atmel 03eb) a specific
# product id is used; for a vendor's own id (Nuand 2cf0, Ettus 2500, SignalHound
# 2817, SEGGER 1366, HydraSDR 38af) a vendor-wide rule is used.
#
# NOT yet included because their VID:PID needs confirming from the vendor: Harogic
# SAxxxx, Chameleon Ultra, XTRX, LiteX-M2SDR, uSDR. Add them here once known.
{ runCommand }:

runCommand "rfswift-udev-rules" { } ''
  install -Dm444 /dev/stdin $out/lib/udev/rules.d/70-rfswift-devices.rules <<'RULES'
# RF Swift consolidated device rules - installed by RF Swift (nix engine)
# Grant the local user access (uaccess) and a permissive mode as a fallback.

## --- SDR ---------------------------------------------------------------
# HackRF One / Jawbreaker / rad1o
SUBSYSTEM=="usb", ATTR{idVendor}=="1d50", ATTR{idProduct}=="6089", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="usb", ATTR{idVendor}=="1d50", ATTR{idProduct}=="cc15", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="usb", ATTR{idVendor}=="1d50", ATTR{idProduct}=="604b", MODE="0666", TAG+="uaccess"
# Airspy R2 / Mini
SUBSYSTEM=="usb", ATTR{idVendor}=="1d50", ATTR{idProduct}=="60a1", MODE="0666", TAG+="uaccess"
# Airspy HF+ / HF+ Discovery
SUBSYSTEM=="usb", ATTR{idVendor}=="03eb", ATTR{idProduct}=="800c", MODE="0666", TAG+="uaccess"
# RTL-SDR (RTL2832U)
SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="2838", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="2832", MODE="0666", TAG+="uaccess"
# LimeSDR-USB and LimeSDR-Mini (FTDI)
SUBSYSTEM=="usb", ATTR{idVendor}=="1d50", ATTR{idProduct}=="6108", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="usb", ATTR{idVendor}=="0403", ATTR{idProduct}=="601f", MODE="0666", TAG+="uaccess"
# Nuand bladeRF 1 (x40/x115) and bladeRF 2.0 micro - Nuand's own vendor id
SUBSYSTEM=="usb", ATTR{idVendor}=="2cf0", MODE="0666", TAG+="uaccess"
# Ettus/NI USRP - Ettus vendor id + legacy USRP1
SUBSYSTEM=="usb", ATTR{idVendor}=="2500", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="usb", ATTR{idVendor}=="fffe", ATTR{idProduct}=="0002", MODE="0666", TAG+="uaccess"
# LibreSDR enumerates as a USRP B210, so the 2500 rule above already covers it.
# ADALM-PlutoSDR (Analog Devices)
SUBSYSTEM=="usb", ATTR{idVendor}=="0456", ATTR{idProduct}=="b673", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="usb", ATTR{idVendor}=="0456", ATTR{idProduct}=="b674", MODE="0666", TAG+="uaccess"
# osmo-fl2k (Fresco Logic FL2000 VGA dongle used as a transmitter)
SUBSYSTEM=="usb", ATTR{idVendor}=="1d5c", ATTR{idProduct}=="5000", MODE="0666", TAG+="uaccess"
# FUNcube Dongle Pro / Pro+ (controlled by qthid)
SUBSYSTEM=="usb", ATTR{idVendor}=="04d8", ATTR{idProduct}=="fb56", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="usb", ATTR{idVendor}=="04d8", ATTR{idProduct}=="fb31", MODE="0666", TAG+="uaccess"
# SignalHound BB60A/C/D, SM200, SA44 - SignalHound's own vendor id
SUBSYSTEM=="usb", ATTR{idVendor}=="2817", MODE="0666", TAG+="uaccess"
# HydraSDR RFOne - own vendor id 38af (legacy 1d50:60a1 is shared with Airspy,
# covered above) and the NXP DFU firmware-update mode
SUBSYSTEM=="usb", ATTR{idVendor}=="38af", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="usb", ATTR{idVendor}=="1fc9", ATTR{idProduct}=="000c", MODE="0666", TAG+="uaccess"

## --- RFID / NFC --------------------------------------------------------
# Proxmark3 (Iceman/RRG) and legacy PM3
SUBSYSTEM=="usb", ATTR{idVendor}=="9ac4", ATTR{idProduct}=="4b8f", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="usb", ATTR{idVendor}=="2d2d", ATTR{idProduct}=="504d", MODE="0666", TAG+="uaccess"
# libnfc-supported PN53x readers (ACR122, SCM SCL3711, Sony RC-S330, NXP PN533...)
SUBSYSTEM=="usb", ATTR{idVendor}=="072f", ATTR{idProduct}=="2200", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="usb", ATTR{idVendor}=="04cc", ATTR{idProduct}=="2533", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="usb", ATTR{idVendor}=="04cc", ATTR{idProduct}=="0531", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="usb", ATTR{idVendor}=="054c", ATTR{idProduct}=="0193", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="usb", ATTR{idVendor}=="04e6", ATTR{idProduct}=="5591", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="usb", ATTR{idVendor}=="1fc9", ATTR{idProduct}=="0102", MODE="0666", TAG+="uaccess"
# RFIDler
SUBSYSTEM=="usb", ATTR{idVendor}=="1d50", ATTR{idProduct}=="6098", MODE="0666", TAG+="uaccess"
# mphidflash / Microchip HID bootloader (PIC targets)
SUBSYSTEM=="usb", ATTR{idVendor}=="04d8", ATTR{idProduct}=="003c", MODE="0666", TAG+="uaccess"

## --- Multitools / debuggers / programmers ------------------------------
# SEGGER J-Link (all models) - SEGGER's own vendor id
SUBSYSTEM=="usb", ATTR{idVendor}=="1366", MODE="0666", TAG+="uaccess"
# Flipper Zero (CDC serial + DFU) and HydraBus/HydraNFC (STM32 VCP)
SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="5740", MODE="0666", TAG+="uaccess"
# STM32 DFU bootloader (Flipper recovery, HydraBus, many boards)
SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="df11", MODE="0666", TAG+="uaccess"
# PJRC Teensy (HalfKay bootloader + serial)
SUBSYSTEM=="usb", ATTR{idVendor}=="16c0", ATTR{idProduct}=="0478", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="usb", ATTR{idVendor}=="16c0", ATTR{idProduct}=="0483", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="usb", ATTR{idVendor}=="16c0", ATTR{idProduct}=="0486", MODE="0666", TAG+="uaccess"
# ESP32/ESP8266 USB-serial bridges + native USB (esptool)
SUBSYSTEM=="usb", ATTR{idVendor}=="10c4", ATTR{idProduct}=="ea60", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="usb", ATTR{idVendor}=="1a86", ATTR{idProduct}=="7523", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="usb", ATTR{idVendor}=="1a86", ATTR{idProduct}=="55d4", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="usb", ATTR{idVendor}=="303a", MODE="0666", TAG+="uaccess"
# FTDI JTAG/serial adapters (urjtag, generic FT2232/FT232) - specific PIDs
SUBSYSTEM=="usb", ATTR{idVendor}=="0403", ATTR{idProduct}=="6001", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="usb", ATTR{idVendor}=="0403", ATTR{idProduct}=="6010", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="usb", ATTR{idVendor}=="0403", ATTR{idProduct}=="6011", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="usb", ATTR{idVendor}=="0403", ATTR{idProduct}=="6014", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="usb", ATTR{idVendor}=="0403", ATTR{idProduct}=="6015", MODE="0666", TAG+="uaccess"
# AVR programmers: usbasp, USBtinyISP, AVRISP mkII (avrdude)
SUBSYSTEM=="usb", ATTR{idVendor}=="16c0", ATTR{idProduct}=="05dc", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="usb", ATTR{idVendor}=="1781", ATTR{idProduct}=="0c9f", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="usb", ATTR{idVendor}=="03eb", ATTR{idProduct}=="2104", MODE="0666", TAG+="uaccess"
RULES
''
