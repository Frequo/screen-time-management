# code.py
# QT Py ESP32-S3 PSRAM + FSR phone-present detector over Bluetooth LE UART
#
# Wiring assumed:
#   QT Py 3V  -> one FSR lead
#   other FSR lead -> A2
#   22k resistor from A2 to GND

import time
import board
import analogio

from adafruit_ble import BLERadio
from adafruit_ble.advertising.standard import ProvideServicesAdvertisement
from adafruit_ble.services.nordic import UARTService


# ---------- user-tunable settings ----------

FSR_PIN = board.A2

BLE_NAME = "FSR Phone"

# Keep the phone OFF the FSR when the board first boots.
CALIBRATION_SECONDS = 3.0

# CircuitPython analog readings are 0..65535.
# If it misses the phone, LOWER these.
# If it false-triggers, RAISE these.
ON_DELTA = 4000
OFF_DELTA = 2000

SAMPLES = 8
SAMPLE_DELAY = 0.002

LOOP_DELAY = 0.05
USB_PRINT_EVERY = 0.5
BLE_STATUS_EVERY = 10.0


# ---------- hardware setup ----------

fsr = analogio.AnalogIn(FSR_PIN)

ble = BLERadio()
ble.name = BLE_NAME

uart = UARTService()
advertisement = ProvideServicesAdvertisement(uart)


# ---------- globals ----------

on_threshold = 0
off_threshold = 0
phone_present = None
was_connected = False
last_usb_print = 0.0
last_ble_status = 0.0


def read_fsr(samples=SAMPLES):
    """Return an averaged analog reading from 0..65535."""
    total = 0
    for _ in range(samples):
        total += fsr.value
        time.sleep(SAMPLE_DELAY)
    return total // samples


def send_ble_line(line):
    """Print to USB serial and, if connected, send to phone over BLE UART."""
    print(line)
    if ble.connected:
        try:
            uart.write((line + "\n").encode("utf-8"))
        except OSError:
            # Connection may have dropped mid-write.
            pass


def state_value():
    return 1 if phone_present else 0


def send_state(prefix="STATE"):
    value = read_fsr()
    send_ble_line(
        "{},phone_present={},value={},on_threshold={},off_threshold={}".format(
            prefix,
            state_value(),
            value,
            on_threshold,
            off_threshold,
        )
    )


def calibrate_no_phone():
    """Measure the no-phone baseline and create two hysteresis thresholds."""
    global on_threshold, off_threshold

    print("CALIBRATION_START: keep phone OFF the FSR")

    start = time.monotonic()
    total = 0
    count = 0
    low = 65535
    high = 0

    while time.monotonic() - start < CALIBRATION_SECONDS:
        value = read_fsr(samples=4)
        total += value
        count += 1
        if value < low:
            low = value
        if value > high:
            high = value

    baseline = total // max(1, count)

    on_threshold = baseline + ON_DELTA
    off_threshold = baseline + OFF_DELTA

    # Keep thresholds in range and ensure OFF is below ON.
    if on_threshold > 65535:
        on_threshold = 65535
    if off_threshold >= on_threshold:
        off_threshold = max(0, on_threshold - 1)

    send_ble_line(
        "CALIBRATED,baseline={},noise_low={},noise_high={},on_threshold={},off_threshold={}".format(
            baseline,
            low,
            high,
            on_threshold,
            off_threshold,
        )
    )


def process_ble_commands():
    """Optional commands from the phone over BLE UART: status, cal."""
    if not ble.connected:
        return

    if not uart.in_waiting:
        return

    raw = uart.read(uart.in_waiting)
    if not raw:
        return

    try:
        text = raw.decode("utf-8")
    except UnicodeError:
        send_ble_line("ERR,bad_text")
        return

    # Allow multiple newline-separated commands.
    text = text.replace("\r", "\n")
    for command in text.split("\n"):
        command = command.strip().lower()
        if not command:
            continue

        if command in ("status", "s", "?"):
            send_state("STATE")

        elif command in ("cal", "calibrate"):
            send_ble_line("CALIBRATE_REQUEST,remove_phone_from_fsr_now")
            time.sleep(1.0)
            calibrate_no_phone()
            send_state("STATE")

        else:
            send_ble_line("ERR,unknown_command,try=status_or_cal")


def start_advertising_if_needed():
    if not ble.connected and not ble.advertising:
        print("ADVERTISING,name={}".format(BLE_NAME))
        ble.start_advertising(advertisement)


# ---------- main program ----------

calibrate_no_phone()

first_value = read_fsr()
phone_present = first_value >= on_threshold

print("INITIAL,value={},phone_present={}".format(first_value, state_value()))
start_advertising_if_needed()

while True:
    now = time.monotonic()

    # Connection/disconnection handling.
    connected = ble.connected

    if connected and not was_connected:
        if ble.advertising:
            ble.stop_advertising()
        send_ble_line("CONNECTED")
        send_state("STATE")

    elif not connected and was_connected:
        print("DISCONNECTED")
        start_advertising_if_needed()

    elif not connected:
        start_advertising_if_needed()

    was_connected = connected

    process_ble_commands()

    # Read sensor and update state with hysteresis.
    value = read_fsr()

    if not phone_present and value >= on_threshold:
        phone_present = True
        send_ble_line("PHONE_ON,value={}".format(value))

    elif phone_present and value <= off_threshold:
        phone_present = False
        send_ble_line("PHONE_OFF,value={}".format(value))

    # USB debug output.
    if now - last_usb_print >= USB_PRINT_EVERY:
        print(
            "value={} phone_present={} on_threshold={} off_threshold={}".format(
                value,
                state_value(),
                on_threshold,
                off_threshold,
            )
        )
        last_usb_print = now

    # BLE heartbeat/status, so the phone can recover state after missing a transition.
    if ble.connected and now - last_ble_status >= BLE_STATUS_EVERY:
        send_state("STATE")
        last_ble_status = now

    time.sleep(LOOP_DELAY)