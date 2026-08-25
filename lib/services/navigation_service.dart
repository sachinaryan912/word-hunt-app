import 'package:flutter/material.dart';

/// App-wide navigator key so services without a BuildContext (e.g. a
/// notification tap handler) can still push a route.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
