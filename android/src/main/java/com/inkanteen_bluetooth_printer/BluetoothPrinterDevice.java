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
    public final BluetoothDevice bluetoothDevice;
    private BluetoothSocket bluetoothSocket;

    public BluetoothPrinterDevice(BluetoothDevice device) {
        this.bluetoothDevice = device;
    }

    private OutputStream outputStream;
    private InputStream inputStream;
    private Thread mThread;
    private IBluetoothPrinterDisconnectListener mDisconnectListener;
    public void setDisconnectListener(IBluetoothPrinterDisconnectListener listener){
        mDisconnectListener = listener;
    }

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
        mThread = new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    int length = 0;
                    byte[] buffer = new byte[1];

                    // if device is disconnected, length will be -1
                    // or will throws an IOException
                    while ((length = inputStream.read(buffer)) != -1) {
                        Log.d("BLUETOOTH READ BUFFER", Arrays.toString(buffer));
                        Log.d("BLUETOOTH BUFFER LENGTH", String.valueOf(length));
                    }
                }catch (IOException ignored){

                }

                // mark the connection is ended, so we should disconnect to remove the resources
                try {
                    Log.d("BLUETOOTH DISCONNECTED", bluetoothDevice.getAddress());
                    disconnect();
                }catch (IOException ignored){
                }
            }
        });
        mThread.start();
        return bluetoothSocket.isConnected();
    }

    public void disconnect() throws IOException {
        if (bluetoothSocket != null) {
            bluetoothSocket.close();
        }

        outputStream = null;
        bluetoothSocket = null;

        if (mDisconnectListener != null){
            mDisconnectListener.onDisconnected();
        }
    }


    public void write(byte[] bytes) throws IOException {
        if (outputStream == null) {
            connect();
        }

        outputStream.write(bytes);
        outputStream.flush();
    }

    public static interface IBluetoothPrinterDisconnectListener {
        void onDisconnected();
    }
}
