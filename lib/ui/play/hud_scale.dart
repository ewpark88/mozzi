import 'package:flutter/widgets.dart';

/// 반응형 HUD 배율 (ADR-011). 화면의 짧은 변(가로 모드에서는 높이) 기준.
///
/// 기준 390 논리 px(일반 폰 가로 모드 높이)에서 1.0, 작은 폰은 줄이고 태블릿은 키우되
/// 너무 커지지 않게 제한한다.
double hudScaleOf(Size size) =>
    (size.shortestSide / _referenceShortSide).clamp(_minScale, _maxScale);

const double _referenceShortSide = 390;
const double _minScale = 0.8;
const double _maxScale = 1.6;
