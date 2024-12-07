#!/usr/bin/env python3

#         Python Stream Deck Library
#      Released under the MIT license
#
#

# Example script showing some Stream Deck + specific functions

import os
import threading
import io
import pulsectl
import sqlite3
import re

from PIL import Image
from StreamDeck.DeviceManager import DeviceManager
from StreamDeck.Devices.StreamDeck import DialEventType, TouchscreenEventType

# Folder location of image assets used by this example.
ASSETS_PATH = os.path.join(os.path.dirname(__file__), "Assets")

# image for idle state
img = Image.new('RGB', (120, 120), color='black')
released_icon = Image.open(os.path.join(ASSETS_PATH, 'Released.png')).resize((80, 80))
img.paste(released_icon, (20, 20), released_icon)

img_byte_arr = io.BytesIO()
img.save(img_byte_arr, format='JPEG')
img_released_bytes = img_byte_arr.getvalue()

# image for pressed state
img = Image.new('RGB', (120, 120), color='black')
pressed_icon = Image.open(os.path.join(ASSETS_PATH, 'Pressed.png')).resize((80, 80))
img.paste(pressed_icon, (20, 20), pressed_icon)

img_byte_arr = io.BytesIO()
img.save(img_byte_arr, format='JPEG')
img_pressed_bytes = img_byte_arr.getvalue()

sink = []
sink_app_name = []
sink_media_name = []
selected_sink = [0, 0, 0, 0]
volume = {0: 50, 1: 50, 2: 50, 3: 50}

pulse = pulsectl.Pulse('my-client-name')
CHANGE_VOL_AMOUNT = 5


# con = sqlite3.connect("../frontend/db")
# cur = con.cursor()


def update_db():
    local_con = sqlite3.connect(r"../frontend/db")
    local_cur = local_con.cursor()
    print("update_db")
    # Write to sink
    # Clear DB
    global sink
    global sink_app_name
    global sink_media_name

    query = f"DELETE FROM sink"
    print(query)
    local_cur.execute(query)
    for i, s in enumerate(sink):
        # Add sinks
        escaped_media_name = str(sink_media_name[i]).replace("'", "''")
        query = f"INSERT INTO sink VALUES ('{sink_app_name[i]}', '{escaped_media_name}', {s})"
        print(query)
        local_cur.execute(query)
        local_con.commit()
        print(i, s)

    # Get selected
    query = f"SELECT * FROM selected"
    print(query)
    selected = local_cur.execute(query)
    for i in selected.fetchall():
        s = i
        print(s)
        # s[0] MEDIA
        # s[1] APP
        # s[2] INDEX
        # s[3] DIAL
        selected_sink[s[3]] = s[2]

    sink = []
    sink_app_name = []
    sink_media_name = []


def update_sinks():
    for s in pulse.sink_input_list():
        sink_app_name.append(s.proplist["application.name"])
        sink_media_name.append(s.proplist["media.name"])
        sink.append(s.index)


def find_sink_index(app, media):
    id = sink_media_name.index(media)
    if sink_app_name[id] == app:
        return sink[id]


def change_volume(sink, direction):
    # pulse.volume_set(sink, CHANGE_VOL_AMOUNT * direction)
    if direction == 1:
        os.system(f"pactl set-sink-input-volume {sink} +{CHANGE_VOL_AMOUNT}%")
    if direction == -1:
        os.system(f"pactl set-sink-input-volume {sink} -{CHANGE_VOL_AMOUNT}%")


update_sinks()
# print(sink_app_name)
# print(sink_media_name)
# print(sink)

update_db()


# callback when buttons are pressed or released
def key_change_callback(deck, key, key_state):
    print("Key: " + str(key) + " state: " + str(key_state))
    if key == 0 and key_state:
        update_sinks()
        update_db()

    deck.set_key_image(key, img_pressed_bytes if key_state else img_released_bytes)


# callback when dials are pressed or released
def dial_change_callback(deck, dial, event, value):
    if event == DialEventType.PUSH:
        print(f"dial pushed: {dial} state: {value}")
        if dial == 3 and value:
            deck.reset()
            deck.close()
        else:
            # build an image for the touch lcd
            img = Image.new('RGB', (800, 100), 'black')
            icon = Image.open(os.path.join(ASSETS_PATH, 'Exit.png')).resize((80, 80))
            img.paste(icon, (690, 10), icon)

            for k in range(0, deck.DIAL_COUNT - 1):
                img.paste(pressed_icon if (dial == k and value) else released_icon, (30 + (k * 220), 10),
                          pressed_icon if (dial == k and value) else released_icon)

            img_byte_arr = io.BytesIO()
            img.save(img_byte_arr, format='JPEG')
            img_byte_arr = img_byte_arr.getvalue()

            deck.set_touchscreen_image(img_byte_arr, 0, 0, 800, 100)
    elif event == DialEventType.TURN:
        # print(f"dial {dial} turned: {value}")
        direction = 0
        if dial == 0:
            if value < 0:
                direction = -1
            if value > 0:
                direction = 1
        local_con = sqlite3.connect(r"../frontend/db")
        local_cur = local_con.cursor()

        query = f"SELECT * FROM selected WHERE dial={dial}"
        print(query)
        res = local_cur.execute(query)
        change_volume(res.fetchone()[2], direction)


# callback when lcd is touched
def touchscreen_event_callback(deck, evt_type, value):
    if evt_type == TouchscreenEventType.SHORT:
        print("Short touch @ " + str(value['x']) + "," + str(value['y']))

    elif evt_type == TouchscreenEventType.LONG:

        print("Long touch @ " + str(value['x']) + "," + str(value['y']))

    elif evt_type == TouchscreenEventType.DRAG:

        print(
            "Drag started @ " + str(value['x']) + "," + str(value['y']) + " ended @ " + str(value['x_out']) + "," + str(
                value['y_out']))


if __name__ == "__main__":
    streamdecks = DeviceManager().enumerate()

    print("Found {} Stream Deck(s).\n".format(len(streamdecks)))

    for index, deck in enumerate(streamdecks):
        # This example only works with devices that have screens.

        if deck.DECK_TYPE != 'Stream Deck +':
            print(deck.DECK_TYPE)
            print("Sorry, this example only works with Stream Deck +")
            continue

        deck.open()
        deck.reset()

        deck.set_key_callback(key_change_callback)
        deck.set_dial_callback(dial_change_callback)
        deck.set_touchscreen_callback(touchscreen_event_callback)

        print("Opened '{}' device (serial number: '{}')".format(deck.deck_type(), deck.get_serial_number()))

        # Set initial screen brightness to 30%.
        deck.set_brightness(100)

        for key in range(0, deck.KEY_COUNT):
            deck.set_key_image(key, img_released_bytes)

        # build an image for the touch lcd
        img = Image.new('RGB', (800, 100), 'black')
        icon = Image.open(os.path.join(ASSETS_PATH, 'Exit.png')).resize((80, 80))
        img.paste(icon, (690, 10), icon)

        for dial in range(0, deck.DIAL_COUNT - 1):
            img.paste(released_icon, (30 + (dial * 220), 10), released_icon)

        img_bytes = io.BytesIO()
        img.save(img_bytes, format='JPEG')
        touchscreen_image_bytes = img_bytes.getvalue()

        deck.set_touchscreen_image(touchscreen_image_bytes, 0, 0, 800, 100)

        # Wait until all application threads have terminated (for this example,
        # this is when all deck handles are closed).
        for t in threading.enumerate():
            try:
                t.join()
            except RuntimeError:
                pass
