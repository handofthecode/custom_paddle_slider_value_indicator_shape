# custom_paddle_slider_value_indicator_shape

DL;DR, You can now easily change the size of the slider value indicator that pops up when you use the flutter material slider. This is helpful because it is sometimes difficult to see the value popup under your finger.

It is simply a copy of the PaddleSliderValueIndicatorShape with an added size multiplier for the textScaleFactor and sizeWithOverflow.


## Use it like this with your own values.
    ThemeData(
        sliderTheme: SliderThemeData(
            valueIndicatorShape:
                CustomPaddleSliderValueIndicatorShape(
                    sizeMultiplier: 2,
                    textScaleMultiplier: 2,
                ),
        ),
    ),

