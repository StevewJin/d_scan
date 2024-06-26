[English](./README.md) | [中文](./README_ZH.md)

# d_scan

A Scanning SDK for Android and IOS using Flutter development.

## Getting Started

### For IOS

#### 1. Integrate DScan in iOS

##### 1.1 Clone the repository

In the root directory of your iOS project, execute:

```shell
git clone https://github.com/StevewJin/d_scan.git
```

##### 1.2 Modify the `Podfile`

In your iOS project's `Podfile`, add the fol-lowing code to integrate the Flutter module:

```ruby
flutter_application_path = './d_scan'
load File.join(flutter_application_path, '.ios', 'Flutter', 'podhelper.rb')

target 'Runner' do
  install_all_flutter_pods(flutter_application_path)
end
```
Make sure the path `flutter_application_path` is correct.

##### 1.3 Install CocoaPods dependencies

Navigate to the root directory of your iOS project in the terminal and run:

```shell
pod install
```

#### 2. Use DScan in your iOS project

##### 2.1 Modify `AppDelegate.swift`

```swift
import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  lazy var flutterEngine = FlutterEngine(name: "my flutter engine")

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    flutterEngine.run()
    GeneratedPluginRegistrant.register(with: self.flutterEngine)

    // Setup MethodChannel to receive scan results
    let controller = window?.rootViewController as! FlutterViewController
    let scanChannel = FlutterMethodChannel(name: "fun.jinwei.dscan/scan",
                                           binaryMessenger: controller.binaryMessenger)
    scanChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "sendScanResult" {
        if let args = call.arguments as? [String: Any],
           let scanResults = args["result"] as? [String] {
          self.handleScanResult(scanResults)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func handleScanResult(_ scanResults: [String]) {
    print("Received scan results: \(scanResults)")
    NotificationCenter.default.post(name: NSNotification.Name("ScanResultNotification"), object: nil, userInfo: ["scanResults": scanResults])
  }
}
```

##### 2.2 Display Flutter ViewController and receive results

Ensure your `ViewController` correctly displays the Flutter ViewController and handles scan results:

```swift
import UIKit
import Flutter

class ViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()

    let button = UIButton(type: .system)
    button.setTitle("Show Flutter Scanner", for: .normal)
    button.addTarget(self, action: #selector(showFlutterScanner), for: .touchUpInside)
    button.frame = CGRect(x: 50, y: 50, width: 200, height: 50)
    view.addSubview(button)

    // Observe notifications for scan results
    NotificationCenter.default.addObserver(self, selector: #selector(handleScanResultNotification(_:)), name: NSNotification.Name("ScanResultNotification"), object: nil)
  }

  @objc func showFlutterScanner() {
    let flutterEngine = (UIApplication.shared.delegate as! AppDelegate).flutterEngine
    let flutterViewController = FlutterViewController(engine: flutterEngine, nibName: nil, bundle: nil)
    flutterViewController.modalPresentationStyle = .fullScreen
    present(flutterViewController, animated: true, completion: nil)
  }

  @objc func handleScanResultNotification(_ notification: Notification) {
    if let scanResults = notification.userInfo?["scanResults"] as? [String] {
      print("Received scan results in ViewController: \(scanResults)")
      // Handle the scan results here
    }
  }
}
```

#### 3. Summary

By following these steps, you can integrate DScan into your native iOS project and receive and handle scan results via MethodChannel. This approach enables efficient communication between Flutter and native iOS code for a seamless integration experience.

### For Android

#### 1. Integrate DScan in Android

##### 1.1 Clone the repository

In the root directory of your Android project, execute:

```shell
git clone https://github.com/StevewJin/d_scan.git
```

##### 1.2 Modify `settings.gradle`

In your Android project's `settings.gradle` file, add the following code to include the Flutter module:

```groovy
include ':app'
setBinding(new Binding([gradle: this]))
evaluate(new File(
    settingsDir.parentFile,
    'd_scan/.android/include_flutter.groovy'
))
```

##### 1.3 Modify `build.gradle`

In your Android project's `app/build.gradle` file, add the following dependency:

```groovy
dependencies {
    // Other dependencies...
    implementation project(':d_scan')
}
```

#### 2. Use DScan in your Android project

##### 2.1 Initialize Flutter Engine

In `MainActivity`, initialize the Flutter engine and create the `MethodChannel`:

```java
import android.os.Bundle;
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "fun.jinwei.dscan/scan";
    private MethodChannel.Result result;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        // Initialize Flutter engine and MethodChannel
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
            .setMethodCallHandler((call, result) -> {
                if (call.method.equals("sendScanResult")) {
                    List<String> scanResults = call.argument("result");
                    handleScanResult(scanResults);
                }
            });
    }

    private void handleScanResult(List<String> scanResults) {
        // Handle the scan results here
        for (String scanResult : scanResults) {
            Log.d("MainActivity", "Scan result: " + scanResult);
        }
    }
}
```

##### 2.2 Display Flutter Activity and receive results

Create a new `Activity` to display the Flutter UI and receive scan results:

```java
import android.content.Intent;
import android.os.Bundle;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;

public class ScannerActivity extends AppCompatActivity {
    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // Start Flutter activity
        startActivity(
            FlutterActivity
                .withCachedEngine("my_engine_id")
                .build(this)
        );
    }
}
```

##### 2.3 Launch ScannerActivity

In your Android project's main activity or another appropriate location, launch `ScannerActivity`:

```java
import android.content.Intent;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        // Start ScannerActivity
        findViewById(R.id.scan_button).setOnClickListener(view -> {
            Intent intent = new Intent(MainActivity.this, ScannerActivity.class);
            startActivity(intent);
        });
    }
}
```

#### 3. Summary

By following these steps, you can integrate DScan into your native Android project and receive and handle scan results via MethodChannel. This approach enables efficient communication between Flutter and native Android code for a seamless integration experience.
