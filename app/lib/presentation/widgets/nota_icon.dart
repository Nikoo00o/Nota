import 'package:app/core/config/app_config.dart';
import 'package:app/core/constants/assets.dart';
import 'package:app/core/get_it.dart';
import 'package:app/presentation/widgets/widget_base.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NotaIcon extends WidgetBase {
  final double imageSize;
  final double fontSize;

  const NotaIcon({
    super.key,
    this.imageSize = 55,
    this.fontSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SvgPicture.asset(
          Assets.nota_letter_logo,
          height: imageSize,
          colorFilter: ColorFilter.mode(colorPrimary(context), BlendMode.srcIn),
        ),
        const SizedBox(height: 5),
        Text(
          sl<AppConfig>().appTitle,
          style: TextStyle(color: colorPrimary(context), fontSize: fontSize),
        ),
      ],
    );
  }
}
