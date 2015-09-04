// Copyright 2015 The Chromium Authors. All rights reserved.

import 'elements.dart';
import 'styles.dart';
import 'views.dart';
import 'skywidgets.dart';

class CounterStore extends BaseZone {
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

class CounterAppState extends BaseZone implements AppState {
  final CounterStore datastore = new CounterStore();
  final ReadRef<String> appTitle = new Constant<String>('Create!');
  final Ref<View> mainView = new State<View>();

  CounterAppState() {
    mainView.value = makeMainView();
  }

  View makeMainView() {
    return new ColumnView(new ImmutableList<View>([
          new LabelView(
            datastore.describeState,
            new Constant<Style>(BODY1_STYLE)
          ),
          new ButtonView(
            new Constant<String>('Increase the counter value'),
            new Constant<Style>(BUTTON_STYLE),
            new Constant<Operation>(datastore.increaseValue)
          )
        ]
      ), null);
  }

  @override ReadList<ItemView> makeDrawerItems(Context context) {
    return new ImmutableList<ItemView>([
      new ItemView(
        new Constant<String>('Increase by one'),
        new Constant<IconId>(ICON_EXPOSURE_PLUS_1),
        new Constant<Operation>(increaseByOne)
      ),
      new ItemView(
        new Constant<String>('Increase by two'),
        new Constant<IconId>(ICON_EXPOSURE_PLUS_2),
        new Constant<Operation>(increaseByTwo)
      )
    ]);
  }

  // UI Logic
  Operation get increaseByOne => makeOperation(() {
    datastore.increaseBy.value = 1;
  });

  Operation get increaseByTwo => makeOperation(() {
    datastore.increaseBy.value = 2;
  });
}

void main() {
  new SkyApp(new CounterAppState()).run();
}

//enum Dimensions { Modules, Schema, Paramaters, Library, Services, Views, Styles, Data, Launch }
//enum Modules { Core, Meta, Demo }
