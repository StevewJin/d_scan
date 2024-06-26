[English](./README.md) | [中文](./README_ZH.md)

# d_scan

使用Flutter开发的Android和IOS扫描SDK。

## 开始使用

### For IOS

#### 1. IOS 集成 DScan

##### 1.1 下载DScan

在你的 iOS 项目根目录下执行

```shell
git clone https://github.com/StevewJin/d_scan.git
```

##### 1.2 修改 iOS 项目的 `Podfile`

在你的 iOS 项目的 Podfile 中添加以下代码，以集成 Flutter module：

```ruby
flutter_application_path = './d_scan'
load File.join(flutter_application_path, '.ios', 'Flutter', 'podhelper.rb')

target 'Runner' do
  install_all_flutter_pods(flutter_application_path)
end
```
确保路径 `flutter_application_path` 是正确的。

##### 1.3 安装 CocoaPods 依赖

在终端中导航到你的 iOS 项目根目录并运行：

```shell
pod install
```

#### 2. 在 iOS 项目中使用 DScan

##### 2.1 修改 `AppDelegate.swift`

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

##### 2.2 显示 Flutter ViewController 并接收结果

确保你的 `ViewController` 正确显示 Flutter ViewController 并处理扫描结果：

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

#### 3. 总结

通过上述步骤，你可以将 DScan 集成到原生 iOS 项目中，并通过 MethodChannel 在 iOS 端接收和处理扫描结果。这种方法使得 Flutter 和原生 iOS 代码能够高效地通信，实现无缝的集成体验。

### For Android

#### 1. Android 集成 DScan

##### 1.1 下载DScan

在你的 Android 项目根目录下执行

```shell
git clone https://github.com/StevewJin/d_scan.git
```

##### 1.2 修改 `settings.gradle`

打开你的 Android 项目中的 `settings.gradle` 文件，添加以下代码以包含 Flutter module：

```groovy
include ':app'
setBinding(new Binding([gradle: this]))
evaluate(new File(
    settingsDir.parentFile,
    'd_scan/.android/include_flutter.groovy'
))
```

##### 1.3 修改 `build.gradle`

打开你的 Android 项目的 `app/build.gradle` 文件，添加以下内容:

```groovy
dependencies {
    // Other dependencies...
    implementation project(':d_scan')
}
```

#### 2. 在 Android 项目中使用 DScan

##### 2.1 在 Android 项目中初始化 Flutter Engine

在 `MainActivity` 中初始化 Flutter engine 并创建 `MethodChannel`：

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

##### 2.2 显示 Flutter Activity 并接收结果

创建一个新的 `Activity` 以显示 Flutter UI 并接收扫描结果：

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

##### 2.3 在 Android 项目中启动 ScannerActivity

在你的 Android 项目中的主活动或其他适当位置启动 `ScannerActivity`：

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

#### 3. 总结

通过上述步骤，你可以将 DScan 集成到原生 Android 项目中，并通过 MethodChannel 在 Android 端接收和处理扫描结果。这种方法使得 Flutter 和原生 Android 代码能够高效地通信，实现无缝的集成体验。
