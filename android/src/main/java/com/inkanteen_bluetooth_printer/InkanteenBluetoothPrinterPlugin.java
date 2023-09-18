package com.inkanteen_bluetooth_printer;

import static android.os.Build.VERSION.SDK_INT;

import android.Manifest;
import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.JSONMethodCodec;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;

/**
 * InkanteenBluetoothPrinterPlugin
 */
public class InkanteenBluetoothPrinterPlugin implements FlutterPlugin, ActivityAware, PluginRegistry.RequestPermissionsResultListener, MethodCallHandler {
    private MethodChannel channel;
    private BluetoothAdapter bluetoothAdapter;

    private Activity activity;
    private final Handler mainHandler = new Handler(Looper.getMainLooper());

    private final Map<String, BluetoothPrinterDevice> connectedDevices = new HashMap<>();

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "com.inkanteen/bluetooth_printer");
        IntentFilter intentFilter = new IntentFilter(BluetoothDevice.ACTION_FOUND);
        flutterPluginBinding.getApplicationContext().registerReceiver(discoveryReceiver, intentFilter);
    }

    private final BroadcastReceiver discoveryReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            String action = intent.getAction();
            if (BluetoothDevice.ACTION_FOUND.equals(action)) {
                BluetoothDevice device = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);
                final Map<String, Object> map = mapDevice(device);
                channel.invokeMethod("onDiscovering", map);
            }
        }
    };

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        switch (call.method) {
            case "getDevices": {
                getDevices(result);
                return;
            }
            
            case "getConnectedDevices":{
                final List<Map<String, Object>> list = new ArrayList<Map<String, Object>>();
                synchronized (connectedDevices) {
                    for (BluetoothPrinterDevice device :
                            connectedDevices.values()) {
                        list.add(mapDevice(device.bluetoothDevice));
                    }
                }
                result.success(list);
            }

            case "disconnect": {
                final String address = call.argument("address");
                AsyncTask.execute(new Runnable() {
                    @Override
                    public void run() {
                        synchronized (connectedDevices){
                            if (connectedDevices.containsKey(address)){
                                try {
                                    BluetoothPrinterDevice device = connectedDevices.remove(address);
                                    assert  device != null;
                                    device.disconnect();
                                    mainHandler.post(new Runnable() {
                                        @Override
                                        public void run() {
                                            result.success(true);
                                        }
                                    });
                                }catch (IOException e){
                                    mainHandler.post(new Runnable() {
                                        @Override
                                        public void run() {
                                            result.error("failed_disconnect", e.getMessage(), null);
                                        }
                                    });
                                }
                            }

                            mainHandler.post(new Runnable() {
                                @Override
                                public void run() {
                                    result.success(false);
                                }
                            });
                        }
                    }
                });
            }

            case "write": {
                final String address = call.argument("address");
                final byte[] data = call.argument("data");
                AsyncTask.execute(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            BluetoothPrinterDevice device;
                            synchronized (connectedDevices) {
                                if (connectedDevices.containsKey(address)) {
                                    device = connectedDevices.get(address);
                                } else {
                                    final BluetoothDevice bluetoothDevice = bluetoothAdapter.getRemoteDevice(address);
                                    device = new BluetoothPrinterDevice(bluetoothDevice);
                                    device.setDisconnectListener(() -> {
                                        synchronized (connectedDevices){
                                            connectedDevices.remove(address);
                                        }
                                    });

                                    connectedDevices.put(address, device);
                                }
                            }

                            assert device != null;
                            if (!device.isConnected()){
                                device.connect();
                            }

                            device.write(data);
                            result.success(true);
                        } catch (IOException e) {
                            mainHandler.post(new Runnable() {
                                @Override
                                public void run() {
                                    result.error("write_error", e.getMessage(), null);
                                }
                            });
                        }
                    }
                });
                return;
            }
        }

        result.notImplemented();
    }

    private void getDevices(@NonNull Result result) {
        ensurePermission(permitted -> {
            if (permitted) {
                if (discovery()) {
                    result.success(getBondedDevices());
                }

                return;
            }

            result.error("get_devices_failed", "Failed to get devices, ensure bluetooth is on and permitted", null);
        });
    }

    static interface PermissionResultCallback {
        public void onResult(boolean permitted);
    }

    PermissionResultCallback permissionResultCallback;

    private void ensurePermission(PermissionResultCallback callback) {
        if (SDK_INT >= Build.VERSION_CODES.M) {
            if (SDK_INT >= 31) {
                final boolean bluetooth = activity.checkSelfPermission(Manifest.permission.BLUETOOTH) == PackageManager.PERMISSION_GRANTED;
                final boolean bluetoothScan = activity.checkSelfPermission(Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED;
                final boolean bluetoothConnect = activity.checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED;

                if (bluetooth && bluetoothScan && bluetoothConnect) {
                    callback.onResult(true);
                    return;
                }

                permissionResultCallback = callback;
                activity.requestPermissions(new String[]{Manifest.permission.BLUETOOTH, Manifest.permission.BLUETOOTH_ADMIN, Manifest.permission.BLUETOOTH_SCAN, Manifest.permission.BLUETOOTH_CONNECT}, 919191);
            } else {
                boolean bluetooth = activity.checkSelfPermission(Manifest.permission.BLUETOOTH) == PackageManager.PERMISSION_GRANTED;
                boolean fineLocation = activity.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED;
                boolean coarseLocation = activity.checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED;

                if (bluetooth && (fineLocation || coarseLocation)) {
                    callback.onResult(true);
                    return;
                }

                permissionResultCallback = callback;
                activity.requestPermissions(new String[]{Manifest.permission.BLUETOOTH, Manifest.permission.BLUETOOTH_ADMIN, Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION}, 919191);
            }

            return;
        }

        callback.onResult(true);
    }

    @Override
    public boolean onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        if (permissionResultCallback != null && requestCode == 919191) {
            boolean isPermitted = true;
            for (final int result : grantResults) {
                if (result != PackageManager.PERMISSION_GRANTED) {
                    isPermitted = false;
                    break;
                }
            }

            permissionResultCallback.onResult(isPermitted);
            return true;
        }

        return false;
    }

    private boolean discovery() {
        if (SDK_INT >= android.os.Build.VERSION_CODES.M) {
            BluetoothManager bluetoothManager = activity.getSystemService(BluetoothManager.class);
            bluetoothAdapter = bluetoothManager.getAdapter();
        } else {
            bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        }

        return true;
    }

    private Map<String, Object> mapDevice(BluetoothDevice device) {
        Map<String, Object> result = new HashMap<>();
        result.put("address", device.getAddress());
        result.put("name", device.getName());
        result.put("type", device.getType());
        return result;
    }

    private List<Map<String, Object>> getBondedDevices() {
        Set<BluetoothDevice> devices = bluetoothAdapter.getBondedDevices();
        List<Map<String, Object>> result = new ArrayList<>();
        for (BluetoothDevice device : devices) {
            result.add(mapDevice(device));
        }

        return result;
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        binding.addRequestPermissionsResultListener(this);
        activity = binding.getActivity();
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {

    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {

    }

    @Override
    public void onDetachedFromActivity() {
        channel.setMethodCallHandler(null);
        activity = null;
    }
}
