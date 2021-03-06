// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

enum AppChoice { COUNTER, CREATE }

const AppChoice DEFAULT_APP = AppChoice.CREATE;

const String CREATE_VERSION = 'DEV';
String CREATE_ID = CREATE_VERSION.replaceAll(' ', '_');
