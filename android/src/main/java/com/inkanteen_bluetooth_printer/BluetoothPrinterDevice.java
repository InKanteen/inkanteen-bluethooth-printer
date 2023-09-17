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
    private Thread mThread;

    public BluetoothPrinterDevice(BluetoothDevice device) {
        this.bluetoothDevice = device;
    }

    private OutputStream outputStream;
    private InputStream inputStream;

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
        inputStream = bluetoothSocket.getInputStream();
        return bluetoothSocket.isConnected();
    }

    public void disconnect() throws IOException {
        mThread.interrupt();
        if (bluetoothSocket != null) {
            bluetoothSocket.close();
        }

        outputStream = null;
        bluetoothSocket = null;
    }

    public static interface WriteResultCallback {
        public void onFinished();
    }

    public boolean write(byte[] bytes, WriteResultCallback callback) throws IOException {
        if (outputStream == null) {
            connect();
        }

        outputStream.write(bytes);
        mThread = new Thread(() -> {
            int length = 0;
            byte[] buffer = new byte[1];
            try {
                while ((length = inputStream.read(buffer)) != -1) {
                    buffer = Arrays.copyOf(buffer, length);
                    Log.d("BUFFER", Arrays.toString(buffer));
                    callback.onFinished();
                    break;
                }
            } catch (Exception ignored) {

            }
        });
        mThread.start();

        byte[] getStatusCommand = {0x10, 0x04, 0x01};
        outputStream.write(getStatusCommand);
        outputStream.flush();
        return true;
    }
}
