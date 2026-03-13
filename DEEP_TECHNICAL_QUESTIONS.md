# 🔥 أسئلة تقنية عميقة ومتقدمة

## 🎯 **أسئلة متقدمة عن State Management في BLoC**

### 1. **ما الفرق بين BlocListener و BlocConsumer و BlocBuilder؟ ومتى تستخدم كل منها؟**

**BlocBuilder:**
```dart
BlocBuilder<AuthCubit, AuthState>(
  builder: (context, state) {
    if (state is AuthLoading) return LoadingWidget();
    if (state is AuthSuccess) return HomeScreen();
    return LoginScreen();
  },
)
```
- **الوظيفة**: يبني واجهة بناءً على الحالة
- **متى تستخدم**: عندما تريد تحديث UI بناءً على تغيرات الحالة
- **التكرار**: يعيد البناء مع كل تغيير في الحالة

**BlocListener:**
```dart
BlocListener<AuthCubit, AuthState>(
  listener: (context, state) {
    if (state is AuthError) {
      ScaffoldMessenger.showSnackBar(...);
    }
  },
  child: SomeWidget(),
)
```
- **الوظيفة**: يستمع لتغيرات الحالة وينفذ side effects
- **متى تستخدم**: للتنقل، إظهار dialogs، إظهار snackbars
- **التكرار**: لا يعيد بناء UI

**BlocConsumer:**
```dart
BlocConsumer<AuthCubit, AuthState>(
  listener: (context, state) {
    if (state is AuthSuccess) {
      Navigator.push(...);
    }
  },
  builder: (context, state) {
    return state is AuthLoading ? LoadingWidget() : LoginForm();
  },
)
```
- **الوظيفة**: يجمع بين Listener و Builder
- **متى تستخدم**: عندما تحتاج لـ side effects وتحديث UI
- **الميزة**: يمنع rebuilds غير ضرورية

**السؤال العميق**: لماذا في مشروعك استخدمت BlocListener في HomeScreen للاستماع لتغيرات AuthState بدلاً من BlocConsumer؟

---

### 2. **ما هو BlocObserver وكيف تستخدمه؟**

```dart
class AppBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    print('${bloc.runtimeType} created');
    super.onCreate(bloc);
  }
  
  @override
  void onEvent(Bloc bloc, Object? event) {
    print('${bloc.runtimeType} event: $event');
    super.onEvent(bloc, event);
  }
  
  @override
  void onTransition(Bloc bloc, Transition transition) {
    print('${bloc.runtimeType} transition: $transition');
    super.onTransition(bloc, transition);
  }
  
  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    print('${bloc.runtimeType} error: $error');
    super.onError(bloc, error, stackTrace);
  }
}
```

**الاستخدام**: في main.dart
```dart
void main() {
  Bloc.observer = AppBlocObserver();
  runApp(MyApp());
}
```

**السؤال**: كيف يمكن استخدام BlocObserver لـ debugging و logging في مشروعك؟

---

### 3. **ما الفرق بين Cubit و Bloc؟ ومتى تختار كل منهما؟**

**Cubit:**
```dart
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);
  
  void increment() => emit(state + 1);
  void decrement() => emit(state - 1);
}
```
- **البساطة**: functions مباشرة
- **الحالة**: نوع واحد فقط
- **الاستخدام**: للحالات البسيطة

**Bloc:**
```dart
class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<IncrementEvent>(_onIncrement);
    on<DecrementEvent>(_onDecrement);
  }
  
  void _onIncrement(IncrementEvent event, Emitter<int> emit) {
    emit(state + 1);
  }
}
```
- **التعقيد**: events و handlers
- **المرونة**: يمكن معالجة أحداث متعددة
- **الاستخدام**: للحالات المعقدة

**السؤال العميق**: لماذا استخدمت Cubit في معظم ميزات مشروعك بدلاً من Bloc؟ وما هي المزايا والعيوب؟

---

### 4. **كيف تتعامل مع State immutability في BLoC؟**

**المشكلة**: في Dart، الكائنات mutable by default
**الحل**: استخدام packages مثل equatable أو freezed

**مثال مع equatable:**
```dart
class AuthState extends Equatable {
  final User? user;
  final bool isLoading;
  final String? error;
  
  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });
  
  @override
  List<Object?> get props => [user, isLoading, error];
}
```

**السؤال**: لماذا الـ immutability مهمة في state management؟ وكيف تضمنها في مشروعك؟

---

### 5. **ما هو BlocProvider و MultiBlocProvider؟ وما الفرق بينهما؟**

**BlocProvider:**
```dart
BlocProvider(
  create: (context) => AuthCubit(),
  child: MyApp(),
)
```

**MultiBlocProvider:**
```dart
MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => AuthCubit()),
    BlocProvider(create: (_) => ProfileCubit()),
    BlocProvider(create: (_) => HomeCubit()),
  ],
  child: MyApp(),
)
```

**السؤال**: لماذا استخدمت MultiBlocProvider في main.dart؟ وما هي مزايا هذه الطريقة؟

---

### 6. **كيف تتعامل مع Dependency Injection في BLoC؟**

**الطريقة 1: Constructor Injection**
```dart
class MedicationCubit extends Cubit<MedicationState> {
  final MedicationService _service;
  
  MedicationCubit(this._service) : super(MedicationInitial());
}
```

**الطريقة 2: Repository Pattern**
```dart
class MedicationRepository {
  final MedicationService _service;
  
  Future<List<Medication>> getMedications() {
    return _service.getMedications();
  }
}
```

**السؤال**: كيف تقوم بـ dependency injection في مشروعك؟ ولماذا اخترت هذه الطريقة؟

---

### 7. **ما هو BlocConcurrency وكيف تتحكم في تدفق الأحداث؟**

**المشكلة**: أحداث متعددة تأتي في وقت واحد
**الحل**: استخدام concurrency transformers

```dart
class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<IncrementEvent>(
      _onIncrement,
      transformer: sequential(), // أو concurrent(), restartable()
    );
  }
}
```

**الخيارات**:
- `sequential()`: تعالج الأحداث بالتسلسل
- `concurrent()`: تعالج الأحداث بالتوازي
- `restartable()`: تلغي العملية الحالية وتبدأ جديدة

**السؤال**: متى تحتاج إلى استخدام concurrency transformers في مشروع حقيقي؟

---

### 8. **كيف تتعامل مع Streams في BLoC؟**

**المثال**: تحديث بيانات في الوقت الحقيقي
```dart
class RealTimeDataCubit extends Cubit<List<Data>> {
  final Stream<List<Data>> _dataStream;
  StreamSubscription? _subscription;
  
  RealTimeDataCubit(this._dataStream) : super([]) {
    _subscription = _dataStream.listen((data) {
      emit(data);
    });
  }
  
  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
```

**السؤال**: كيف تتعامل مع إغلاق الـ Streams لمنع memory leaks؟

---

### 9. **ما هو BlocTest وكيف تكتب tests لـ BLoC؟**

```dart
blocTest<CounterCubit, int>(
  'emits [1] when increment is called',
  build: () => CounterCubit(),
  act: (cubit) => cubit.increment(),
  expect: () => [1],
);

blocTest<CounterCubit, int>(
  'emits [1, 2] when increment is called twice',
  build: () => CounterCubit(),
  act: (cubit) {
    cubit.increment();
    cubit.increment();
  },
  expect: () => [1, 2],
);
```

**السؤال**: كيف تكتب tests لـ Cubit معقد مثل MedicationCubit؟

---

### 10. **كيف تتعامل مع Global State vs Local State؟**

**Global State** (مشترك بين multiple screens):
```dart
// في أعلى شجرة الـ Widgets
BlocProvider(create: (_) => AuthCubit())
```

**Local State** (خاص بشاشة واحدة):
```dart
// داخل شاشة معينة
BlocProvider(
  create: (_) => SomeLocalCubit(),
  child: SomeScreen(),
)
```

**السؤال**: كيف تقرر ما إذا كانت الحالة global أم local في مشروعك؟

---

## 🎯 **أسئلة متقدمة عن Flutter Architecture**

### 11. **ما هو Clean Architecture وكيف تطبقه في Flutter؟**

**الطبقات**:
1. **Domain Layer** (الكيانات، use cases)
2. **Data Layer** (repositories، data sources)
3. **Presentation Layer** (UI، BLoC)

**السؤال**: كيف طبقت Clean Architecture في مشروع Sanadi؟ وأين تقع الـ BLoC في هذه الطبقات؟

---

### 12. **ما هو Repository Pattern ولماذا هو مهم؟**

```dart
abstract class MedicationRepository {
  Future<List<Medication>> getMedications();
  Future<void> addMedication(Medication medication);
}

class MedicationRepositoryImpl implements MedicationRepository {
  final MedicationService _service;
  
  @override
  Future<List<Medication>> getMedications() {
    return _service.getMedications();
  }
}
```

**المزايا**:
- فصل الـ business logic عن implementation details
- سهولة الاختبار
- سهولة تغيير مصدر البيانات

**السؤال**: لماذا لم تستخدم Repository Pattern في مشروعك؟ وما البديل الذي استخدمته؟

---

### 13. **ما هو Dependency Injection وكيف تطبقه في Flutter؟**

**الطرق**:
1. **Constructor Injection** (الأفضل)
2. **Provider Pattern** (مع GetIt أو Provider)
3. **Service Locator** (مع GetIt)

**السؤال**: كيف تدير الـ dependencies في مشروعك؟ ولماذا اخترت هذه الطريقة؟

---

### 14. **ما هو Event Sourcing Pattern؟**

**الفكرة**: تخزين جميع الأحداث بدلاً من الحالة النهائية
**التطبيق في BLoC**: كل تغيير في الحالة يكون نتيجة event

**السؤال**: كيف يمكن تطبيق Event Sourcing مع BLoC؟ وما هي مزاياها؟

---

### 15. **كيف تتعامل مع CQRS (Command Query Responsibility Segregation)؟**

**الفصل بين**:
- **Commands**: تغيير البيانات (mutations)
- **Queries**: قراءة البيانات (queries)

**السؤال**: كيف يمكن تطبيق CQRS في BLoC pattern؟

---

## 🎯 **أسئلة متقدمة عن Performance**

### 16. **كيف تمنع rebuilds غير ضرورية في BLoC؟**

**التقنيات**:
1. **const constructors**
2. **Equatable للـ states**
3. **BlocListener بدلاً من BlocBuilder للـ side effects**
4. **استخدام `buildWhen` في BlocBuilder**

```dart
BlocBuilder<AuthCubit, AuthState>(
  buildWhen: (previous, current) {
    // يعيد البناء فقط عندما يتغير isLoading
    return previous.isLoading != current.isLoading;
  },
  builder: (context, state) {
    return state.isLoading ? LoadingWidget() : ContentWidget();
  },
)
```

**السؤال**: كيف تضمن أن مشروعك لا يعاني من rebuilds غير ضرورية؟

---

### 17. **ما هو Memory Leak وكيف تمنعه في Flutter؟**

**الأسباب الشائعة**:
1. عدم إغلاق الـ Streams
2. عدم إلغاء الـ AnimationControllers
3. عدم إلغاء الـ FocusNodes
4. دورات مرجعية (reference cycles)

**الوقاية**:
```dart
@override
void dispose() {
  _streamSubscription?.cancel();
  _animationController?.dispose();
  _focusNode?.dispose();
  super.dispose();
}
```

**السؤال**: كيف تتعامل مع إدارة الذاكرة في مشروع كبير مثل Sanadi؟

---

### 18. **كيف تحسن أداء القوائم الطويلة (Long Lists)؟**

**الحلول**:
1. **ListView.builder** بدلاً من ListView
2. **const constructors** للـ items
3. **KeepAlive** للـ items المعقدة
4. **Lazy loading** للبيانات
5. **Image caching**

**السؤال**: كيف تطبق هذه التقنيات في مشروعك؟

---

## 🎯 **أسئلة متقدمة عن Testing**

### 19. **ما هي أنواع Testing المختلفة وكيف تطبقها؟**

1. **Unit Tests**: اختبار الدوال والكلاسات المنعزلة
2. **Widget Tests**: اختبار الـ Widgets
3. **Integration Tests**: اختبار التدفق الكامل
4. **Golden Tests**: اختبار الـ UI ضد صور مرجعية

**السؤال**: كيف تكتب tests لـ BLoC مع dependencies مثل Firebase؟

---

### 20. **كيف تكتب Mock objects للاختبار؟**

**باستخدام Mockito**:
```dart
class MockMedicationService extends Mock implements MedicationService {}

void main() {
  late MockMedicationService mockService;
  late MedicationCubit cubit;
  
  setUp(() {
    mockService = MockMedicationService();
    cubit = MedicationCubit(mockService);
  });
  
  test('loads medications', () async {
    when(mockService.getMedications()).thenAnswer(
      (_) async => [Medication(...)],
    );
    
    await cubit.loadMedications();
    
    verify(mockService.getMedications()).called(1);
  });
}
```

**السؤال**: كيف تكتب tests لـ Cubit يعتمد على Firebase Auth؟

---

## 🎯 **أسئلة متقدمة عن Firebase**

### 21. **كيف تتعامل مع Offline Data في Firestore؟**

**الميزات**:
1. **Offline Persistence** (تلقائي)
2. **Manual Caching**
3. **Sync عند الاتصال**

**السؤال**: كيف تضمن أن بيانات الأدوية متاحة حتى بدون اتصال؟

---

### 22. **ما هي Firebase Security Rules وكيف تكتبها بشكل آمن؟**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
      
      match /medications/{medicationId} {
        allow read, write: if request.auth.uid == userId;
      }
    }
  }
}
```

**السؤال**: كيف تصمم قواعد الأمان لمشروع معقد مثل Sanadi؟

---

### 23. **كيف تتعامل مع Pagination في Firestore؟**

```dart
final firstPage = await _firestore
    .collection('medications')
    .orderBy('createdAt')
    .limit(10)
    .get();

final lastDoc = firstPage.docs.last;
final nextPage = await _firestore
    .collection('medications')
    .orderBy('createdAt')
    .startAfterDocument(lastDoc)
    .limit(10)
    .get();
```

**السؤال**: كيف تطبق pagination في قوائم الأطباء أو الأدوية؟

---

## 🎯 **أسئلة متقدمة عن Design Patterns**

### 24. **ما هو Singleton Pattern ومتى تستخدمه؟**

```dart
class MedicationService {
  static final MedicationService _instance = MedicationService._internal();
  
  factory MedicationService() {
    return _instance;
  }
  
  MedicationService._internal();
}
```

**السؤال**: هل تستخدم Singleton في مشروعك؟ وما هي بدائله؟

---

### 25. **ما هو Factory Pattern وكيف تطبقه؟**

```dart
abstract class NotificationService {
  factory NotificationService.platform() {
    if (Platform.isAndroid) return AndroidNotificationService();
    if (Platform.isIOS) return IOSNotificationService();
    return LocalNotificationService();
  }
}
```

**السؤال**: كيف يمكن استخدام Factory Pattern في مشروع متعدد المنصات؟

---

## 💡 **نصائح للإجابة على الأسئلة العميقة:**

1. **فكر بصوت عالٍ**: اشرح تفكيرك أثناء الإجابة
2. **استخدم أمثلة من مشروعك**: "في Sanadi، عندما..."
3. **اذكر المزايا والعيوب**: لا تكن متحيزاً
4. **كن صادقاً**: إذا كنت لا تعرف، قل ذلك ولكن أظهر استعدادك للتعلم
5. **اسأل لتوضيح**: تأكد أنك فهمت السؤال

## 🚀 **التحضير النهائي:**

1. **افهم المفاهيم العميقة**: لا تحفظ الإجابات
2. **تمرن على الشرح**: حاول شرح هذه المفاهيم لنفسك
3. **راجع الكود**: ابحث عن أمثلة واقعية في مشروعك
4. **استعد للأسئلة المفاجئة**: قد يسأل عن شيء لم تستعد له
5. **كن واثقاً**: أنت بنيت مشروعاً معقداً، أنت قادر على الإجابة

**تذكر**: الأسئلة العميقة تهدف لقياس:
1. فهمك للمفاهيم الأساسية
2. قدرتك على تطبيق هذه المفاهيم
3. خبرتك الحقيقية في حل المشاكل
4. استعدادك للتعلم والنمو

**أنت جاهز! حظاً موفقاً! 🚀**