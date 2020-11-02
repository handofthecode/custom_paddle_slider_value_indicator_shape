library custom_paddle_slider_value_indicator_shape;

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class _CustomPaddleSliderValueIndicatorPathPainter {
  const _CustomPaddleSliderValueIndicatorPathPainter();

  // These constants define the shape of the default value indicator.
  // The value indicator changes shape based on the size of
  // the label: The top lobe spreads horizontally, and the
  // top arc on the neck moves down to keep it merging smoothly
  // with the top lobe as it expands.

  // Radius of the top lobe of the value indicator.
  static const double _topLobeRadius = 16.0;
  static const double _minLabelWidth = 16.0;
  // Radius of the bottom lobe of the value indicator.
  static const double _bottomLobeRadius = 10.0;
  static const double _labelPadding = 8.0;
  static const double _distanceBetweenTopBottomCenters = 40.0;
  static const double _middleNeckWidth = 3.0;
  static const double _bottomNeckRadius = 4.5;
  // The base of the triangle between the top lobe center and the centers of
  // the two top neck arcs.
  static const double _neckTriangleBase = _topNeckRadius + _middleNeckWidth / 2;
  static const double _rightBottomNeckCenterX =
      _middleNeckWidth / 2 + _bottomNeckRadius;
  static const double _rightBottomNeckAngleStart = math.pi;
  static const Offset _topLobeCenter =
      Offset(0.0, -_distanceBetweenTopBottomCenters);
  static const double _topNeckRadius = 13.0;
  // The length of the hypotenuse of the triangle formed by the center
  // of the left top lobe arc and the center of the top left neck arc.
  // Used to calculate the position of the center of the arc.
  static const double _neckTriangleHypotenuse = _topLobeRadius + _topNeckRadius;
  // Some convenience values to help readability.
  static const double _twoSeventyDegrees = 3.0 * math.pi / 2.0;
  static const double _ninetyDegrees = math.pi / 2.0;
  static const double _thirtyDegrees = math.pi / 6.0;
  static const double _preferredHeight =
      _distanceBetweenTopBottomCenters + _topLobeRadius + _bottomLobeRadius;
  // Set to true if you want a rectangle to be drawn around the label bubble.
  // This helps with building tests that check that the label draws in the right
  // place (because it prints the rect in the failed test output). It should not
  // be checked in while set to "true".
  static const bool _debuggingLabelLocation = false;

  Size getPreferredSize(
    bool isEnabled,
    bool isDiscrete,
    TextPainter labelPainter,
    double textScaleFactor,
  ) {
    assert(labelPainter != null);
    assert(textScaleFactor != null && textScaleFactor >= 0);
    final double width =
        math.max(_minLabelWidth * textScaleFactor, labelPainter.width) +
            _labelPadding * 2 * textScaleFactor;
    return Size(width, _preferredHeight * textScaleFactor);
  }

  // Adds an arc to the path that has the attributes passed in. This is
  // a convenience to make adding arcs have less boilerplate.
  static void _addArc(Path path, Offset center, double radius,
      double startAngle, double endAngle) {
    assert(center.isFinite);
    final Rect arcRect = Rect.fromCircle(center: center, radius: radius);
    path.arcTo(arcRect, startAngle, endAngle - startAngle, false);
  }

  double getHorizontalShift({
    RenderBox parentBox,
    Offset center,
    TextPainter labelPainter,
    double scale,
    double textScaleFactor,
    Size sizeWithOverflow,
  }) {
    assert(!sizeWithOverflow.isEmpty);
    final double inverseTextScale =
        textScaleFactor != 0 ? 1.0 / textScaleFactor : 0.0;
    final double labelHalfWidth = labelPainter.width / 2.0;
    final double halfWidthNeeded = math.max(
      0.0,
      inverseTextScale * labelHalfWidth - (_topLobeRadius - _labelPadding),
    );
    final double shift = _getIdealOffset(parentBox, halfWidthNeeded,
        textScaleFactor * scale, center, sizeWithOverflow.width);
    return shift * textScaleFactor;
  }

  // Determines the "best" offset to keep the bubble within the slider. The
  // calling code will bound that with the available movement in the paddle shape.
  double _getIdealOffset(
    RenderBox parentBox,
    double halfWidthNeeded,
    double scale,
    Offset center,
    double widthWithOverflow,
  ) {
    const double edgeMargin = 8.0;
    final Rect topLobeRect = Rect.fromLTWH(
      -_topLobeRadius - halfWidthNeeded,
      -_topLobeRadius - _distanceBetweenTopBottomCenters,
      2.0 * (_topLobeRadius + halfWidthNeeded),
      2.0 * _topLobeRadius,
    );
    // We can just multiply by scale instead of a transform, since we're scaling
    // around (0, 0).
    final Offset topLeft = (topLobeRect.topLeft * scale) + center;
    final Offset bottomRight = (topLobeRect.bottomRight * scale) + center;
    double shift = 0.0;

    if (topLeft.dx < edgeMargin) {
      shift = edgeMargin - topLeft.dx;
    }

    final double endGlobal = widthWithOverflow;
    if (bottomRight.dx > endGlobal - edgeMargin) {
      shift = endGlobal - edgeMargin - bottomRight.dx;
    }

    shift = scale == 0.0 ? 0.0 : shift / scale;
    if (shift < 0.0) {
      // Shifting to the left.
      shift = math.max(shift, -halfWidthNeeded);
    } else {
      // Shifting to the right.
      shift = math.min(shift, halfWidthNeeded);
    }
    return shift;
  }

  void paint(
    RenderBox parentBox,
    Canvas canvas,
    Offset center,
    Paint paint,
    double scale,
    TextPainter labelPainter,
    double textScaleFactor,
    Size sizeWithOverflow,
    Color strokePaintColor,
  ) {
    if (scale == 0.0) {
      // Zero scale essentially means "do not draw anything", so it's safe to just return. Otherwise,
      // our math below will attempt to divide by zero and send needless NaNs to the engine.
      return;
    }
    assert(!sizeWithOverflow.isEmpty);

    // The entire value indicator should scale with the size of the label,
    // to keep it large enough to encompass the label text.
    final double overallScale = scale * textScaleFactor;
    final double inverseTextScale =
        textScaleFactor != 0 ? 1.0 / textScaleFactor : 0.0;
    final double labelHalfWidth = labelPainter.width / 2.0;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(overallScale, overallScale);

    final double bottomNeckTriangleHypotenuse =
        _bottomNeckRadius + _bottomLobeRadius / overallScale;
    final double rightBottomNeckCenterY = -math.sqrt(
        math.pow(bottomNeckTriangleHypotenuse, 2) -
            math.pow(_rightBottomNeckCenterX, 2));
    final double rightBottomNeckAngleEnd =
        math.pi + math.atan(rightBottomNeckCenterY / _rightBottomNeckCenterX);
    final Path path = Path()
      ..moveTo(_middleNeckWidth / 2, rightBottomNeckCenterY);
    _addArc(
      path,
      Offset(_rightBottomNeckCenterX, rightBottomNeckCenterY),
      _bottomNeckRadius,
      _rightBottomNeckAngleStart,
      rightBottomNeckAngleEnd,
    );
    _addArc(
      path,
      Offset.zero,
      _bottomLobeRadius / overallScale,
      rightBottomNeckAngleEnd - math.pi,
      2 * math.pi - rightBottomNeckAngleEnd,
    );
    _addArc(
      path,
      Offset(-_rightBottomNeckCenterX, rightBottomNeckCenterY),
      _bottomNeckRadius,
      math.pi - rightBottomNeckAngleEnd,
      0,
    );

    // This is the needed extra width for the label.  It is only positive when
    // the label exceeds the minimum size contained by the round top lobe.
    final double halfWidthNeeded = math.max(
      0.0,
      inverseTextScale * labelHalfWidth - (_topLobeRadius - _labelPadding),
    );

    final double shift = _getIdealOffset(parentBox, halfWidthNeeded,
        overallScale, center, sizeWithOverflow.width);
    final double leftWidthNeeded = halfWidthNeeded - shift;
    final double rightWidthNeeded = halfWidthNeeded + shift;

    // The parameter that describes how far along the transition from round to
    // stretched we are.
    final double leftAmount =
        math.max(0.0, math.min(1.0, leftWidthNeeded / _neckTriangleBase));
    final double rightAmount =
        math.max(0.0, math.min(1.0, rightWidthNeeded / _neckTriangleBase));
    // The angle between the top neck arc's center and the top lobe's center
    // and vertical. The base amount is chosen so that the neck is smooth,
    // even when the lobe is shifted due to its size.
    final double leftTheta = (1.0 - leftAmount) * _thirtyDegrees;
    final double rightTheta = (1.0 - rightAmount) * _thirtyDegrees;
    // The center of the top left neck arc.
    final Offset leftTopNeckCenter = Offset(
      -_neckTriangleBase,
      _topLobeCenter.dy + math.cos(leftTheta) * _neckTriangleHypotenuse,
    );
    final Offset neckRightCenter = Offset(
      _neckTriangleBase,
      _topLobeCenter.dy + math.cos(rightTheta) * _neckTriangleHypotenuse,
    );
    final double leftNeckArcAngle = _ninetyDegrees - leftTheta;
    final double rightNeckArcAngle = math.pi + _ninetyDegrees - rightTheta;
    // The distance between the end of the bottom neck arc and the beginning of
    // the top neck arc. We use this to shrink/expand it based on the scale
    // factor of the value indicator.
    final double neckStretchBaseline = math.max(
        0.0,
        rightBottomNeckCenterY -
            math.max(leftTopNeckCenter.dy, neckRightCenter.dy));
    final double t = math.pow(inverseTextScale, 3.0) as double;
    final double stretch = (neckStretchBaseline * t)
        .clamp(0.0, 10.0 * neckStretchBaseline) as double;
    final Offset neckStretch = Offset(0.0, neckStretchBaseline - stretch);

    assert(!_debuggingLabelLocation ||
        () {
          final Offset leftCenter =
              _topLobeCenter - Offset(leftWidthNeeded, 0.0) + neckStretch;
          final Offset rightCenter =
              _topLobeCenter + Offset(rightWidthNeeded, 0.0) + neckStretch;
          final Rect valueRect = Rect.fromLTRB(
            leftCenter.dx - _topLobeRadius,
            leftCenter.dy - _topLobeRadius,
            rightCenter.dx + _topLobeRadius,
            rightCenter.dy + _topLobeRadius,
          );
          final Paint outlinePaint = Paint()
            ..color = const Color(0xffff0000)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0;
          canvas.drawRect(valueRect, outlinePaint);
          return true;
        }());

    _addArc(
      path,
      leftTopNeckCenter + neckStretch,
      _topNeckRadius,
      0.0,
      -leftNeckArcAngle,
    );
    _addArc(
      path,
      _topLobeCenter - Offset(leftWidthNeeded, 0.0) + neckStretch,
      _topLobeRadius,
      _ninetyDegrees + leftTheta,
      _twoSeventyDegrees,
    );
    _addArc(
      path,
      _topLobeCenter + Offset(rightWidthNeeded, 0.0) + neckStretch,
      _topLobeRadius,
      _twoSeventyDegrees,
      _twoSeventyDegrees + math.pi - rightTheta,
    );
    _addArc(
      path,
      neckRightCenter + neckStretch,
      _topNeckRadius,
      rightNeckArcAngle,
      math.pi,
    );

    if (strokePaintColor != null) {
      final Paint strokePaint = Paint()
        ..color = strokePaintColor
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, strokePaint);
    }

    canvas.drawPath(path, paint);

    // Draw the label.
    canvas.save();
    canvas.translate(shift, -_distanceBetweenTopBottomCenters + neckStretch.dy);
    canvas.scale(inverseTextScale, inverseTextScale);
    labelPainter.paint(canvas,
        Offset.zero - Offset(labelHalfWidth, labelPainter.height / 2.0));
    canvas.restore();
    canvas.restore();
  }
}

class CustomPaddleSliderValueIndicatorShape extends SliderComponentShape {
  /// Create a slider value indicator in the shape of an upside-down pear.
  double textScaleMultiplier;
  double sizeMultiplier;
  CustomPaddleSliderValueIndicatorShape({
    this.sizeMultiplier = 1,
    this.textScaleMultiplier = 1,
  }) : assert(sizeMultiplier > 0 &&
            sizeMultiplier < 5 &&
            textScaleMultiplier > 0 &&
            textScaleMultiplier < 5);

  static const _CustomPaddleSliderValueIndicatorPathPainter _pathPainter =
      _CustomPaddleSliderValueIndicatorPathPainter();

  @override
  Size getPreferredSize(
    bool isEnabled,
    bool isDiscrete, {
    @required TextPainter labelPainter,
    @required double textScaleFactor,
  }) {
    assert(labelPainter != null);
    assert(textScaleFactor != null && textScaleFactor >= 0);
    return _pathPainter.getPreferredSize(
        isEnabled, isDiscrete, labelPainter, textScaleFactor);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    @required Animation<double> activationAnimation,
    @required Animation<double> enableAnimation,
    bool isDiscrete,
    @required TextPainter labelPainter,
    @required RenderBox parentBox,
    @required SliderThemeData sliderTheme,
    TextDirection textDirection,
    double value,
    double textScaleFactor,
    Size sizeWithOverflow,
  }) {
    assert(context != null);
    assert(center != null);
    assert(activationAnimation != null);
    assert(enableAnimation != null);
    assert(labelPainter != null);
    assert(parentBox != null);
    assert(sliderTheme != null);
    assert(!sizeWithOverflow.isEmpty);
    final ColorTween enableColor = ColorTween(
      begin: sliderTheme.disabledThumbColor,
      end: sliderTheme.valueIndicatorColor,
    );
    _pathPainter.paint(
      parentBox,
      context.canvas,
      center,
      Paint()..color = enableColor.evaluate(enableAnimation),
      activationAnimation.value,
      labelPainter,
      textScaleFactor * textScaleMultiplier,
      sizeWithOverflow * sizeMultiplier,
      null,
    );
  }
}
