// Copyright 2015 The Chromium Authors. All rights reserved.

library counter;

import 'elements.dart';
import 'elementsruntime.dart';
import 'styles.dart';
import 'views.dart';

class CounterData extends BaseZone {
  // State
  final Ref<int> counter = new State<int>(68);

  final Ref<int> increaseBy = new State<int>(1);

  // Business logic
  Operation get increaseValue => makeOperation(() {
    counter.value = counter.value + increaseBy.value;
  });

  ReadRef<String> get describeState => new ReactiveFunction<int, String>(
      counter, this, (int counterValue) => 'The counter value is $counterValue');
}

class CounterApp extends BaseZone implements AppState {
  final CounterData datastore;
  final ReadRef<String> appTitle = new Constant<String>('Create!');
  ReadRef<String> appVersion = new Constant<String>('');
  final Ref<View> mainView = new State<View>();
  final ReadRef<Operation> addOperation = new Constant<Operation>(null);

  CounterApp(this.datastore) {
    mainView.value = new ColumnView(
      new ImmutableList<View>([
        new LabelView(
          datastore.describeState,
          new Constant<Style>(BODY_STYLE)
        ),
        new ButtonView(
          new Constant<String>('Increase the counter value'),
          new Constant<Style>(BUTTON_STYLE),
          new Constant<Operation>(datastore.increaseValue)
        )
      ]
    ));
  }

  @override DrawerView makeDrawer() {
    return new DrawerView(
      new ImmutableList<View>([
        new HeaderView(
          new Constant<String>('Counter Demo')
        ),
        new ItemView(
          new Constant<String>('Increase by one'),
          new Constant<IconId>(EXPOSURE_PLUS_1_ICON),
          new Constant<bool>(datastore.increaseBy.value == 1),
          new Constant<Operation>(increaseByOne)
        ),
        new ItemView(
          new Constant<String>('Increase by two'),
          new Constant<IconId>(EXPOSURE_PLUS_2_ICON),
          new Constant<bool>(datastore.increaseBy.value == 2),
          new Constant<Operation>(increaseByTwo)
        ),
        new DividerView(),
        new ItemView(
          new Constant<String>('Help & Feedback'),
          new Constant<IconId>(HELP_ICON),
          new Constant<bool>(false),
          null
        ),
      ])
    );
  }

  // UI Logic
  Operation get increaseByOne => makeOperation(() {
    datastore.increaseBy.value = 1;
  });

  Operation get increaseByTwo => makeOperation(() {
    datastore.increaseBy.value = 2;
  });
}
