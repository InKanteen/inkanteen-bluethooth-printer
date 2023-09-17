package com.inkanteen_bluetooth_printer;

import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;
import android.util.Log;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.Arrays;
import java.util.UUID;

public class BluetoothPrinterDevice {
    private final BluetoothDevice bluetoothDevice;
    private BluetoothSocket bluetoothSocket;

    public BluetoothPrinterDevice(BluetoothDevice device) {
        this.bluetoothDevice = device;
    }

    private OutputStream outputStream;

    public boolean isConnected() {
        if (bluetoothSocket == null) {
            return false;
        }

        return bluetoothSocket.isConnected();
    }

    public boolean connect() throws IOException {
        UUID uuid = UUID.fromString("00001101-0000-1000-8000-00805f9b34fb");
        bluetoothSocket = bluetoothDevice.createRfcommSocketToServiceRecord(uuid);
        bluetoothSocket.connect();
        outputStream = bluetoothSocket.getOutputStream();
        return bluetoothSocket.isConnected();
    }

    public void disconnect() throws IOException {
        if (bluetoothSocket != null) {
            bluetoothSocket.close();
        }

        outputStream = null;
        bluetoothSocket = null;
    }


    public void write(byte[] bytes) throws IOException {
        if (outputStream == null) {
            connect();
        }

        outputStream.write(bytes);
        outputStream.flush();
    }
}
