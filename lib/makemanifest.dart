// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'config.dart';

String MANIFEST = '''<?xml version="1.0" encoding="utf-8"?>
<!-- Copyright 2016 The Chromium Authors. All rights reserved.
     Use of this source code is governed by a BSD-style license that can be
     found in the LICENSE file.
 -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="org.domokit.create.$CREATE_ID"
    android:versionCode="1"
    android:versionName="0.0.1">

    <uses-sdk android:minSdkVersion="16" android:targetSdkVersion="21" />
    <uses-permission android:name="android.permission.INTERNET"/>

    <application android:name="org.domokit.sky.shell.SkyApplication"
            android:label="Create! $CREATE_VERSION">
        <activity android:name="org.domokit.sky.shell.SkyActivity"
                  android:launchMode="singleTask"
                  android:theme="@android:style/Theme.Black.NoTitleBar"
                  android:configChanges="orientation|keyboardHidden|keyboard|screenSize|locale|layoutDirection"
                  android:hardwareAccelerated="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>''';

main() {
  print(MANIFEST);
}
