library responsive_builder;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef WidgetBuilder = Widget Function(BuildContext);

enum DeviceScreenType { Watch, SmallMobile, Mobile, Tablet, Desktop }

/// Contains sizing information to make responsive choices for the current screen
class SizingInformation {
  final DeviceScreenType deviceScreenType;
  final Size screenSize;
  final Size localWidgetSize;

  bool get isWatch => deviceScreenType == DeviceScreenType.Watch;

  bool get isSmallMobile => deviceScreenType == DeviceScreenType.SmallMobile;

  bool get isMobile => deviceScreenType == DeviceScreenType.Mobile;

  bool get isTablet => deviceScreenType == DeviceScreenType.Tablet;

  bool get isDesktop => deviceScreenType == DeviceScreenType.Desktop;

  SizingInformation({
    this.deviceScreenType,
    this.screenSize,
    this.localWidgetSize,
  });

  @override
  String toString() {
    return 'DeviceType:$deviceScreenType ScreenSize:$screenSize LocalWidgetSize:$localWidgetSize';
  }
}

/// Manually define screen resolution breakpoints
///
/// Overrides the defaults
class ScreenBreakpoints {
  final double watch;
  final double tablet;
  final double desktop;

  ScreenBreakpoints({@required this.desktop, @required this.tablet, @required this.watch});

  @override
  String toString() {
    return "Desktop: $desktop, Tablet: $tablet, Watch: $watch";
  }
}

/// A widget with a builder that provides you with the sizingInformation
///
/// This widget is used by the ScreenTypeLayout to provide different widget builders
class ResponsiveBuilder extends StatelessWidget {
  final bool resizeMargins;
  final Widget Function(
    BuildContext context,
    SizingInformation sizingInformation,
  ) builder;

  final ScreenBreakpoints breakpoints;

  const ResponsiveBuilder({Key key, this.builder, this.breakpoints, this.resizeMargins})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, boxConstraints) {
      var mediaQuery = MediaQuery.of(context);
      var sizingInformation = SizingInformation(
          deviceScreenType: _getDeviceType(mediaQuery, breakpoints),
          screenSize: mediaQuery.size,
          localWidgetSize: Size(boxConstraints.maxWidth, boxConstraints.maxHeight));
      SizingConfig().init(
          wight: sizingInformation.screenSize.width, height: sizingInformation.screenSize.height);
      if (resizeMargins) {
        SizingConfig().resizeMargins(deviceScreenType: sizingInformation.deviceScreenType);
      }
      return builder(context, sizingInformation);
    });
  }
}

//Class that get the sizes of the screen and help to make a query
// with mobile default size
class SizingConfig {
  static double screenWidth = 360;
  static double screenHeight = 720;
  static double blockSizeHorizontal = 3.6;
  static double blockSizeVertical = 7.2;
  static double edgeMarginLayout = 16;
  static double marginBetweenComponents = 8;
  static DeviceScreenType screenType = DeviceScreenType.Mobile;

  void init({@required double wight, @required double height}) {
    screenHeight = height;
    screenWidth = wight;
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;
  }

  void resizeMargins({@required DeviceScreenType deviceScreenType}) {
    if (deviceScreenType == DeviceScreenType.SmallMobile) {
      edgeMarginLayout = 8;
      marginBetweenComponents = 4;
      screenType = deviceScreenType;
      return;
    }

    if (deviceScreenType == DeviceScreenType.Tablet) {
      edgeMarginLayout = 24;
      marginBetweenComponents = 16;
      screenType = deviceScreenType;
      return;
    }

    if (deviceScreenType == DeviceScreenType.Desktop) {
      edgeMarginLayout = 32;
      marginBetweenComponents = 24;
      screenType = deviceScreenType;
      return;
    }
    if (deviceScreenType == DeviceScreenType.Watch) {
      edgeMarginLayout = 4;
      marginBetweenComponents = 4;
      screenType = deviceScreenType;
      return;
    }
    edgeMarginLayout = 16;
    marginBetweenComponents = 8;
    screenType = deviceScreenType;
    return;
  }
}

/// Provides a builder function for different screen types
///
/// Each builder will get built based on the current device width.
/// [breakpoints] define your own custom device resolutions
/// [watch] will be built and shown when width is less than 300
/// [mobile] will be built when width greater than 300
/// [tablet] will be built when width is greater than 600
/// [desktop] will be built if width is greater than 950
class ScreenTypeLayout extends StatelessWidget {
  final bool resizeMargins;
  final ScreenBreakpoints breakpoints;
  final WidgetBuilder watch;
  final WidgetBuilder smallMobile;
  final WidgetBuilder mobile;
  final WidgetBuilder tablet;
  final WidgetBuilder desktop;

  ScreenTypeLayout(
      {Key key,
      this.breakpoints,
      Widget watch,
      Widget smallMobile,
      Widget mobile,
      Widget tablet,
      Widget desktop,
      this.resizeMargins})
      : this.watch = _builderOrNull(watch),
        this.smallMobile = _builderOrNull(smallMobile),
        this.mobile = _builderOrNull(mobile),
        this.tablet = _builderOrNull(tablet),
        this.desktop = _builderOrNull(desktop),
        super(key: key);

  const ScreenTypeLayout.builder(
      {Key key,
      this.breakpoints,
      this.watch,
      this.smallMobile,
      this.mobile,
      this.tablet,
      this.desktop,
      this.resizeMargins})
      : super(key: key);

  static WidgetBuilder _builderOrNull(Widget widget) {
    return widget == null ? null : ((_) => widget);
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      breakpoints: breakpoints,
      resizeMargins: resizeMargins,
      builder: (context, sizingInformation) {
        // If we're at desktop size
        if (sizingInformation.deviceScreenType == DeviceScreenType.Desktop) {
          // If we have supplied the desktop layout then display that
          if (desktop != null) return desktop(context);
          // If no desktop layout is supplied we want to check if we have the size below it and display that
          if (tablet != null) return tablet(context);
        }

        if (sizingInformation.deviceScreenType == DeviceScreenType.Tablet) {
          if (tablet != null) return tablet(context);
        }
        if (sizingInformation.deviceScreenType == DeviceScreenType.Watch && watch != null) {
          return watch(context);
        }
        if (sizingInformation.deviceScreenType == DeviceScreenType.SmallMobile &&
            smallMobile != null) {
          return smallMobile(context);
        }

        // If none of the layouts above are supplied or we're on the mobile layout then we show the mobile layout
        return mobile(context);
      },
    );
  }
}

/// Provides a builder function for a landscape and portrait widget
class OrientationLayoutBuilder extends StatelessWidget {
  final WidgetBuilder landscape;
  final WidgetBuilder portrait;
  const OrientationLayoutBuilder({
    Key key,
    this.landscape,
    this.portrait,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        var orientation = MediaQuery.of(context).orientation;
        if (orientation == Orientation.landscape) {
          if (landscape != null) {
            return landscape(context);
          }
        }

        return portrait(context);
      },
    );
  }
}

DeviceScreenType _getDeviceType(MediaQueryData mediaQuery, ScreenBreakpoints breakpoint) {
  double deviceWidth = mediaQuery.size.shortestSide;

  if (kIsWeb) {
    deviceWidth = mediaQuery.size.width;
  }

  // Replaces the defaults with the user defined definitions
  if (breakpoint != null) {
    if (deviceWidth > breakpoint.desktop) {
      return DeviceScreenType.Desktop;
    }

    if (deviceWidth > breakpoint.tablet) {
      return DeviceScreenType.Tablet;
    }

    if (deviceWidth < breakpoint.watch) {
      return DeviceScreenType.Watch;
    }
  }

  // If no user defined definitions are passed through use the defaults
  if (deviceWidth > 940) {
    return DeviceScreenType.Desktop;
  }

  if (deviceWidth >= 600) {
    return DeviceScreenType.Tablet;
  }

  if (deviceWidth < 270) {
    return DeviceScreenType.Watch;
  }

  if (deviceWidth <= 320) {
    return DeviceScreenType.SmallMobile;
  }

  return DeviceScreenType.Mobile;
}
