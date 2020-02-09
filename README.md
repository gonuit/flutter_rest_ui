# Restui
[![pub package](https://img.shields.io/pub/v/restui.svg)](https://pub.dev/packages/restui) 
![github last commit](https://img.shields.io/github/last-commit/gonuit/flutter_restui.svg)
![github last commit](https://img.shields.io/github/issues/gonuit/flutter_restui.svg)
![github last commit](https://img.shields.io/github/license/gonuit/flutter_restui.svg)

#### A simple yet powerful wrapper around `http` library which provide:
  
| Feature                             |  Status  |
| :---------------------------------- | :------: |
| HTTP Requests                       |    ✅    |
| HTTP interval requests              |    ✅    |
| HTTP Requests from widget tree      |    ✅    |
| HTTP Middlewares [ApiLink]          |  ✅ 🧪   |
| App state management                |  ✅ 🧪   |
| State management from widget tree   |  ✅ 🧪   |
| Client for graphQL                  |    ⚙️     |
| ApiLink for request caching         |    ❌    |

✅ - done  
🧪 - experimental  
⚙️  - work in progress  
❌ - not implemented  
  
---

## IMPORTANT
This library is under development, breaking API changes might still happen. If you would like to make use of this library please make sure to provide which version you want to use e.g:
```yaml
dependencies:
  restui: 0.1.0
```
  
---
  
- [Restui](#restui)
      - [A simple yet powerful wrapper around `http` library which provide:](#a-simple-yet-powerful-wrapper-around-http-library-which-provide)
  - [IMPORTANT](#important)
  - [1. Getting Started](#1-getting-started)
      - [1.1. First create your Api object class by extending `BaseApi` class](#11-first-create-your-api-object-class-by-extending-baseapi-class)
      - [1.2. Provide your Api instance down the widget tree](#12-provide-your-api-instance-down-the-widget-tree)
      - [1.3.1. To make an api call in standard (ugly 😏) way](#131-to-make-an-api-call-in-standard-ugly-%f0%9f%98%8f-way)
      - [1.3.2. Or simply make use of `Query` widget to make the call from widget tree](#132-or-simply-make-use-of-query-widget-to-make-the-call-from-widget-tree)
  - [2. Query widget](#2-query-widget)
  - [3. ApiLink](#3-apilink)
    - [3.1. About ApiLink](#31-about-apilink)
    - [3.2. Built-in ApiLinks](#32-built-in-apilinks)
      - [3.2.1. HeadersMapperLink](#321-headersmapperlink)
    - [3.3. Create own ApiLink](#33-create-own-apilink)
      - [3.3.1. Create link](#331-create-link)
      - [3.3.2. Get data from the link](#332-get-data-from-the-link)
  - [4. State management (experimental)](#4-state-management-experimental)
  - [5. Example app](#5-example-app)
    - [5.1 Api example](#51-api-example)
    - [5.2 Api + state management](#52-api--state-management)
  - [5. TODO:](#5-todo)

## 1. Getting Started

#### 1.1. First create your Api object class by extending `BaseApi` class
```dart
class Api extends ApiBase {

  Api({
    /// BaseApi requires yoy to provide [Uri] object that points to your api 
    @required Uri uri,

    /// Enable link support by passing [ApiLink]
    /// object to super constructor (optional)
    ApiLink link,

    /// Default headers for your application (optional)
    Map<String, String> defaultHeaders,

    /// Api stores responsible for app state management.
    List<ApiStore> stores,

    /// Call super constructor with provided data
  }) : super(
          uri: uri,
          defaultHeaders: defaultHeaders,
          link: link,
          stores: stores,
        );

  /// Implement methods that will call your api
  Future<ExamplePhotoModel> getRandomPhoto() async {

    /// It's important to call your api with [call] method as it triggers
    /// [ApiRequest] build and links invocations
    final response = await api.call(
      endpoint: "/id/${Random().nextInt(50)}/info",
      method: HttpMethod.GET,
    );
    return ExamplePhotoModel.fromJson(json.decode(response.body));
  }
}

```

#### 1.2. Provide your Api instance down the widget tree
```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    /// To provide your api use [RestuiProvider] widget
    /// in place of [Api] put yours API class type 
    return RestuiProvider<Api>(
        apiBuilder: (_) => Api(

          /// Pass base uri adress thats points to your api
          uri: Uri.parse("https://picsum.photos"),

          /// Add links if needed
          /// For more invormation look at [HeadersMapperLink] and [DebugLink]
          /// links descriptions
          link: HeadersMapperLink(["uid", "client", "access-token"])
              .chain(DebugLink(printResponseBody: true)),
          
          /// List of stores provided to [ApiStorage].
          /// Can be accessed by [storage] property on [ApiBase] class.
          /// This is the only place when you can add stores to storage.
          stores: <ApiStore>[
            PhotoStore(),
          ],
        ),
        child: MaterialApp(
          title: 'flutter_starter_app',
          onGenerateRoute: _generateRoute,
        ),
      );
  }
}
```

#### 1.3.1. To make an api call in standard (ugly 😏) way
```dart
class _ApiExampleScreenState extends State<ApiExampleScreen> {
  ExamplePhotoModel _randomPhoto;

  @override
  void initState() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _requestRandomPhoto();
    })
    super.initState();
  }

  Future<ExamplePhotoModel> _requestRandomPhoto() async {
    
    /// Retrieve api instance from context
    final api = Query.of<Api>(context);

    /// Make API request
    final photo = await api.getRandomPhoto();
    setState({
      _randomPhoto = photo;
    })
  }

  @override
  Widget build(BuildContext context) {
    bool hasPhoto = _randomPhoto != null;
    return Center(
      /// Implementation ...
    );
  }
}
```
#### 1.3.2. Or simply make use of `Query` widget to make the call from widget tree
For more information look **[HERE](#2-query-widget)**
```dart
class _ApiExampleScreenState extends State<ApiExampleScreen> {
  @override
  Widget build(BuildContext context) {
    return Query<ExamplePhotoModel, Api, void>(
      /// Make your api call and return data here
      callBuilder: (BuildContext context, Api api, void variable) => api.photos.getRandom(),
      /// [loading] indicates whether [callBuilder] method is ongoing.
      /// value returned from [callBuilder] will be passed as a [value] argument.
      builder: (BuildContext context, bool loading, ExamplePhotoModel value) {
        return Center(
          /// Implementation ...
        );
      },
    );
  }
}
```

## 2. Query widget
Query widget is the hearth of Restui library. It allows you to handle API
calls and app state management from one widget.
  
For example of state management and api calls look at example app.
```dart
class _ApiExampleScreenState extends State<ApiExampleScreen> {
 
  @override
  Widget build(BuildContext context) {
    bool hasPhotot = _randomPhoto != null;

    /// `Query<R, A extends BaseApi, V>`
    /// [R] is type of value that will be returned from [callBuilder] and passed to [builder]
    /// as a [value] argument
    /// [A] is your api class implementation
    /// [V] is a variable type
    return Query<ExamplePhotoModel, Api, MyVariable>(
    
      /// Specifying [interval] will cause the query to be
      /// called periodically every [interval] of time.
      interval: const Duration(seconds: 10),

      /// Whether [callBuilder] will be called right before first
      /// [builder] invocation defaults to `true`.
      /// If `false` then [callBuilder] can be called by invocation of  [call] method from
      /// [QueryState] which can be retrieved by [GlobalKey] assigned to [key] argument
      instantCall: false,

      /// Variable of type [V]
      /// Will be passed to the [callBuilder] method
      variable _myVariable,

      /// Data returned from [initialDataBuilder] will be passed
      /// as [value] argument to [builder] method when [callBuilder]
      /// does not return the value yet.
      initialDataBuilder: (BuildContext context, Api api) => _initialData,
      
      /// This argument is REQUIRED
      /// [callBuilder] is the place when you can and should make api request.
      ///
      /// It is responsible for getting data and passing it into [builder] function
      /// as [value] argument.
      ///
      /// TIP:
      /// If data is inside your [ApiStorage] you can return it instead of making api call.
      callBuilder: (BuildContext context, Api api, MyVariable variable) async =>
          api.photos.getRandom(),

      /// [onComplete] is called only when [callBuilder] function returned succesfuly
      /// without throwing an [Exception]. Throwing an [Exception] from [callBuilder]
      /// will cause [onError] function invocation instead.
      ///
      /// [onComplete] callback is called after [callBuilder] with
      /// the data returned from it. Called just before [builder] invocation.
      onComplete: (BuildContext context, ExamplePhotoModel photo) {
         /// Implementation ...
      },

      /// If [callBuilder] function will throw an [Exception] it will be
      /// catched and passed to [onError] function if it's provided.
      onError: (Exception exception) {
        print(exception);
      }

      /// This works like an [Updater] widget, [AnimationBuilder], [StreamBuilder] etc.
      ///
      /// [updaterBuilder] is called right before first widget build. It must return [Listenable]
      /// object. Returning null will take no effect.
      ///
      /// [Query] widget will call [builder] every time when [Listenable] returned from
      /// [updaterBuilder] will notify his listeners.
      ///
      /// TIP:
      /// You can use [NotifierApiStore] class to create your own [ApiStore]  with [ChangeNotifier].
      /// After that you are able to retrieve this store and update widget by calling [builder]
      /// method every time it will notify listeners.
      updaterBuilder: (BuildContext context, Api api) =>
          api.storage.getFirstStoreOfType<PhotoStore>(),

      /// This method is called before every [builder] invocation triggered by [Listenable]
      /// returned from [updaterBuilder] or [callBuilder] method invocation.
      /// Returning [false] from this method will prevent calling [builder].
      /// Returning null will take no effect.
      shouldUpdate: (BuildContext context, Api api, ExamplePhotoModel value) => true, 

      /// This argument is REQUIRED
      /// [value] will be [null] or [initialData] (if argument provided) untill
      /// first value are returned from [callBuilder].
      /// [loading] indicates whether [callBuilder] method is ongoing.
      builder: (BuildContext context, bool loading, ExamplePhotoModel value) {
        return Center(
          /// Implementation ...
        );
      },
    );
  }
}
```

## 3. ApiLink

### 3.1. About ApiLink
`ApiLink` object is kind of a middleware that enables you to add some custom
behaviour before and after every API request.
  
Links can be then Retrieved from your API class [MORE](#22-get-data-from-the-link).

### 3.2. Built-in ApiLinks

#### 3.2.1. HeadersMapperLink
This [ApiLink] takes headers specified by [headersToMap] argument
from response headers and then put to the next request headers.
  
It can be used for authorization. For example,we have an `authorization`
header that changes after each request and with the next query we
must send it back in headers. This [ApiLink] will take it from the
response, save and set as a next request header.
  
Example use simple as:
```dart
final api = Api(
  uri: Uri.parse("https://picsum.photos"),
  link: HeadersMapperLink(["authorization"]),
);
```


### 3.3. Create own ApiLink
If you want to create your own ApiLink with custom behaviour all you need to do is to create your link class that extend `ApiLink` class and then pass it to your api super constructor (constructor of `ApiBase` class) (e.g. [[1](#1-first-create-your-api-object-class-by-extending-baseapi-class)] [[2](#2-provide-your-api-instance-down-the-widget-tree)]).

#### 3.3.1. Create link
```dart
class OngoingRequestsCounterLink extends ApiLink {
  int ongoingRequests;

  OngoingRequestsCounterLink() : _requests = 0;

  /// All you need to do is to override [next] method and add your
  /// custom behaviour
  @override
  Future<ApiResponse> next(ApiRequest request) async {
    
    /// Code here will be called `BEFORE` request
    ongoingRequests++;

    /// Calling [super.next] is required. It calls next [ApiLink]s in the 
    /// chain and returns with [ApiResponse]. 
    ApiResponse response = await super.next(request);

    /// Code here will be called `AFTER` request
    ongoingRequests--;

    /// [next] method should return [ApiResponse] as it passes it down the
    /// [ApiLink] chain
    return response;
  }
}
```

#### 3.3.2. Get data from the link 
Sometimes there is a need to retrieve data saved inside a link or pass some data into it. This is possible thanks to the:
```dart
/// Retrieve `Api` instance from the tree
Api api = Query.of<Api>(context);

/// Get first link of provided type
OngoingRequestsCounterLink link = Api.getFirstLinkOfType<OngoingRequestsCounterLink>();

/// Do sth with your link data
print(link.ongoingRequests);
```
`Api` should be replaced with your API class name that extends `ApiBase`.

## 4. State management (experimental)
Often inside our app state we are keeping modified results of our api requests.
Updating an app state based on api result is often a pain. This library simplifies this process.

## 5. Example app
Inside `example` directory you can find an example app and play with this library.

### 5.1 Api example
<img src="./example/screen.png" width="400">

### 5.2 Api + state management
![screen](./example/state_management.gif)
  
## 5. TODO:
  - Tests
  - GraphQLApiBase class responsible for graphQL requests
  - Improve readme
  - Add `CacheLink` which will be responsible for request caching