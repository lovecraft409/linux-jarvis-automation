import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:web_socket_channel/web_socket_channel.dart';

class AnimatedGlowEmblem extends StatefulWidget {
  final String assetPath;
  final double size;
  final Color glowColor;
  final Duration duration;

  const AnimatedGlowEmblem({
    super.key,
    required this.assetPath,
    this.size = 260,
    this.glowColor = Colors.white,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<AnimatedGlowEmblem> createState() => _AnimatedGlowEmblemState();
}

class _AnimatedGlowEmblemState extends State<AnimatedGlowEmblem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glow; // blur/opacity pulse
  late final Animation<double> _scale; // subtle breathing

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);

    _glow = Tween<double>(
      begin: 0.35,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _scale = Tween<double>(
      begin: 0.98,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final glowStrength = _glow.value;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Transform.scale(
            scale: _scale.value,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Soft blurred glow layer (pulses)
                ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: 8 + (glowStrength * 18),
                    sigmaY: 8 + (glowStrength * 18),
                  ),
                  child: Opacity(
                    opacity: (glowStrength * 0.8).clamp(0.0, 1.0),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        widget.glowColor,
                        BlendMode.srcATop,
                      ),
                      child: Image.asset(
                        widget.assetPath,
                        width: widget.size,
                        height: widget.size,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                // Extra tight glow layer for a hot core
                ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: 2 + (glowStrength * 6),
                    sigmaY: 2 + (glowStrength * 6),
                  ),
                  child: Opacity(
                    opacity: glowStrength.clamp(0.0, 1.0),
                    child: Image.asset(
                      widget.assetPath,
                      width: widget.size,
                      height: widget.size,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                // Crisp original image on top, untouched
                Image.asset(
                  widget.assetPath,
                  width: widget.size,
                  height: widget.size,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

//============================================================
// VOICE-REACTIVE GLOW EMBLEM
//============================================================

class ReactiveGlowEmblem extends StatefulWidget {
  final String assetPath;
  final double size;
  final Color glowColor;
  final ValueListenable<double> intensity;
  final double idleFloor;

  const ReactiveGlowEmblem({
    super.key,
    required this.assetPath,
    required this.intensity,
    this.size = 260,
    this.glowColor = Colors.white,
    this.idleFloor = 0.20,
  });

  @override
  State<ReactiveGlowEmblem> createState() => _ReactiveGlowEmblemState();
}

class _ReactiveGlowEmblemState extends State<ReactiveGlowEmblem> {
  double _smoothed = 0.0;

  @override
  void initState() {
    super.initState();
    widget.intensity.addListener(_onIntensity);
  }

  void _onIntensity() {
    final target = widget.intensity.value.clamp(0.0, 1.0);

    setState(() {
      // Faster response to your voice.
      _smoothed += (target - _smoothed) * 0.55;
    });
  }

  @override
  void dispose() {
    widget.intensity.removeListener(_onIntensity);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voice = _smoothed.clamp(0.0, 1.0);

    // ==========================================================
    // VOICE ENERGY
    // ==========================================================

    // Makes quiet speech react strongly.
    final energy = math.pow(voice, 0.30).toDouble().clamp(0.0, 1.0);

    // Makes loud speech produce an additional "power surge".
    final surge = math.pow(voice, 0.55).toDouble().clamp(0.0, 1.0);

    // ==========================================================
    // IMAGE SIZE
    // ==========================================================

    // IDLE:
    //   0.88 = smaller than normal
    //
    // SPEAKING:
    //   up to ~1.15 = noticeably larger
    //
    // This makes the actual emblem breathe with your voice.
    final scale = 0.50 + (energy * 0.35) + (surge * 0.50);
    // ==========================================================
    // OUTER GLOW
    // ==========================================================

    // Very weak when silent.
    // Explodes outward when speaking.
    final outerBlur = 5.0 + (energy * 120.0) + (surge * 80.0);

    final outerOpacity = (0.04 + energy * 0.65 + surge * 0.31).clamp(0.0, 1.0);

    // ==========================================================
    // SECONDARY GLOW
    // ==========================================================

    final secondaryBlur = 3.0 + (energy * 50.0) + (surge * 22.0);

    final secondaryOpacity = (0.03 + energy * 0.55 + surge * 0.35).clamp(
      0.0,
      1.0,
    );

    // ==========================================================
    // HOT CORE
    // ==========================================================

    final coreBlur = 1.0 + (energy * 20.0) + (surge * 10.0);

    final coreOpacity = (0.08 + energy * 0.55 + surge * 0.37).clamp(0.0, 1.0);

    // ==========================================================
    // VOICE FLARE
    // ==========================================================

    final flareBlur = 1.0 + (surge * 8.0);

    final flareOpacity = (surge * 0.75).clamp(0.0, 1.0);

    return SizedBox(
      width: widget.size,
      height: widget.size,

      child: Transform.scale(
        scale: scale,

        child: Stack(
          alignment: Alignment.center,
          children: [
            // ==================================================
            // MASSIVE OUTER AURA
            // ==================================================
            ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: outerBlur,
                sigmaY: outerBlur,
              ),

              child: Opacity(
                opacity: outerOpacity,

                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    widget.glowColor,
                    BlendMode.srcATop,
                  ),

                  child: Image.asset(
                    widget.assetPath,
                    width: widget.size,
                    height: widget.size,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // ==================================================
            // SECONDARY ENERGY GLOW
            // ==================================================
            ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: secondaryBlur,
                sigmaY: secondaryBlur,
              ),

              child: Opacity(
                opacity: secondaryOpacity,

                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    widget.glowColor,
                    BlendMode.srcATop,
                  ),

                  child: Image.asset(
                    widget.assetPath,
                    width: widget.size,
                    height: widget.size,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // ==================================================
            // HOT CORE
            // ==================================================
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: coreBlur, sigmaY: coreBlur),

              child: Opacity(
                opacity: coreOpacity,

                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    widget.glowColor,
                    BlendMode.srcATop,
                  ),

                  child: Image.asset(
                    widget.assetPath,
                    width: widget.size,
                    height: widget.size,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // ==================================================
            // LOUD VOICE FLARE
            // ==================================================
            ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: flareBlur,
                sigmaY: flareBlur,
              ),

              child: Opacity(
                opacity: flareOpacity,

                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    widget.glowColor,
                    BlendMode.srcATop,
                  ),

                  child: Image.asset(
                    widget.assetPath,
                    width: widget.size,
                    height: widget.size,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // ==================================================
            // CRISP ORIGINAL IMAGE
            // ==================================================
            Image.asset(
              widget.assetPath,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}

//============================================================
// WEBSOCKET-DRIVEN VOICE-REACTIVE EMBLEM
//============================================================

class WebSocketReactiveGlowEmblem extends StatefulWidget {
  final String assetPath;
  final String wsUrl;
  final double size;
  final Color glowColor;
  final double idleFloor;
  final Duration reconnectDelay;

  const WebSocketReactiveGlowEmblem({
    super.key,
    required this.assetPath,
    required this.wsUrl,
    this.size = 260,
    this.glowColor = Colors.white,
    this.idleFloor = 0.20,
    this.reconnectDelay = const Duration(seconds: 2),
  });

  @override
  State<WebSocketReactiveGlowEmblem> createState() =>
      _WebSocketReactiveGlowEmblemState();
}

class _WebSocketReactiveGlowEmblemState
    extends State<WebSocketReactiveGlowEmblem> {
  final ValueNotifier<double> _intensity = ValueNotifier<double>(0.0);

  WebSocketChannel? _channel;

  bool _disposed = false;
  bool _connecting = false;

  @override
  void initState() {
    super.initState();

    _connect();
  }

  Future<void> _connect() async {
    if (_disposed || _connecting) {
      return;
    }

    _connecting = true;

    debugPrint('Connecting to ${widget.wsUrl}...');

    try {
      final channel = WebSocketChannel.connect(Uri.parse(widget.wsUrl));

      _channel = channel;

      await channel.ready;

      if (_disposed) {
        await channel.sink.close();
        return;
      }

      debugPrint('VOICE WEBSOCKET CONNECTED');

      _connecting = false;

      channel.stream.listen(
        (data) {
          debugPrint('VOICE DATA: $data');

          _onData(data);
        },

        onError: (error) {
          debugPrint('VOICE WEBSOCKET ERROR: $error');

          _connecting = false;

          _scheduleReconnect();
        },

        onDone: () {
          debugPrint('VOICE WEBSOCKET CLOSED');

          _connecting = false;

          _scheduleReconnect();
        },

        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('VOICE CONNECTION FAILED: $e');

      _connecting = false;

      _scheduleReconnect();
    }
  }

  void _onData(dynamic data) {
    try {
      final decoded = jsonDecode(data.toString());

      final value = (decoded['intensity'] as num).toDouble();

      final intensity = value.clamp(0.0, 1.0);

      debugPrint('GLOW INTENSITY: $intensity');

      _intensity.value = intensity;
    } catch (e) {
      debugPrint('VOICE DATA PARSE ERROR: $e');
    }
  }

  void _scheduleReconnect() {
    if (_disposed) {
      return;
    }

    _channel = null;

    Future.delayed(widget.reconnectDelay, () {
      if (!_disposed) {
        _connect();
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;

    try {
      _channel?.sink.close();
    } catch (_) {}

    _intensity.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ReactiveGlowEmblem(
      assetPath: widget.assetPath,
      intensity: _intensity,
      size: widget.size,
      glowColor: widget.glowColor,
      idleFloor: widget.idleFloor,
    );
  }
}

class MatrixRain extends StatefulWidget {
  final Color color;
  final double fontSize;
  final Duration frameDuration;
  final double backgroundOpacity;
  final String? easterEggText; // hidden message in one random column

  const MatrixRain({
    super.key,
    this.color = const Color(0xFF00FF41),
    this.fontSize = 16,
    this.frameDuration = const Duration(milliseconds: 60),
    this.backgroundOpacity = 1.0,
    this.easterEggText,
  });

  @override
  State<MatrixRain> createState() => _MatrixRainState();
}

class _MatrixRainState extends State<MatrixRain>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final List<_MatrixColumn> _columns = [];
  final math.Random _rand = math.Random();
  Size _lastSize = Size.zero;

  static const String _chars =
      r'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^&*+-<>/\|=?ｱｻｶｻﾐﾋﾏｼﾂｵﾘｱﾎﾏﾅﾓﾒﾕﾗｾﾈｽﾀﾅﾆﾇﾌﾍﾎﾏﾐﾑﾒﾗﾘﾙﾚﾛﾜｦﾝᜀᜊᜃᜇᜈᜉᜎᜋᜄᜑᜎᜋᜈᜌᜏᜅᜉᜇᜎᜀᜁᜂᜃᜄᜑᜎᜋ';

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    if (_columns.isEmpty) return;
    setState(() {
      for (final col in _columns) {
        col.advance(_rand, widget.fontSize, isFixed: col.isFixed);
      }
    });
  }

  void _setupColumns(Size size) {
    if (_lastSize == size) return;
    _lastSize = size;
    _columns.clear();
    final columnCount = (size.width / widget.fontSize).floor();
    final eggColumn = (widget.easterEggText != null && columnCount > 0)
        ? _rand.nextInt(columnCount)
        : -1;
    for (int i = 0; i < columnCount; i++) {
      _columns.add(
        _MatrixColumn.random(
          _rand,
          size,
          widget.fontSize,
          fixedText: i == eggColumn ? widget.easterEggText : null,
        ),
      );
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _setupColumns(size);
        return ClipRect(
          child: Container(
            color: Colors.black.withOpacity(widget.backgroundOpacity),
            child: CustomPaint(
              size: size,
              painter: _MatrixPainter(
                columns: _columns,
                color: widget.color,
                fontSize: widget.fontSize,
                chars: _chars,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MatrixColumn {
  double y;
  final double speed;
  final int length;
  final bool isFixed; // true if this column spells the easter egg text
  late List<String> glyphs;

  _MatrixColumn({
    required this.y,
    required this.speed,
    required this.length,
    required this.glyphs,
    this.isFixed = false,
  });

  factory _MatrixColumn.random(
    math.Random rand,
    Size size,
    double fontSize, {
    String? fixedText,
  }) {
    if (fixedText != null && fixedText.isNotEmpty) {
      final glyphs = fixedText.split('');
      return _MatrixColumn(
        y: -rand.nextDouble() * size.height,
        speed: 2 + rand.nextDouble() * 3, // a bit slower so it's readable
        length: glyphs.length,
        glyphs: glyphs,
        isFixed: true,
      );
    }
    final length = 8 + rand.nextInt(14);
    return _MatrixColumn(
      y: -rand.nextDouble() * size.height,
      speed: 2 + rand.nextDouble() * 6,
      length: length,
      glyphs: List.generate(
        length,
        (_) =>
            _MatrixRainState._chars[rand.nextInt(
              _MatrixRainState._chars.length,
            )],
      ),
    );
  }

  void advance(math.Random rand, double fontSize, {bool isFixed = false}) {
    y += speed;

    if (!isFixed && rand.nextDouble() < 0.15) {
      final idx = rand.nextInt(glyphs.length);
      glyphs[idx] =
          _MatrixRainState._chars[rand.nextInt(_MatrixRainState._chars.length)];
    }
  }
}

class _MatrixPainter extends CustomPainter {
  final List<_MatrixColumn> columns;
  final Color color;
  final double fontSize;
  final String chars;

  _MatrixPainter({
    required this.columns,
    required this.color,
    required this.fontSize,
    required this.chars,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int c = 0; c < columns.length; c++) {
      final col = columns[c];
      final x = c * fontSize;

      for (int i = 0; i < col.length; i++) {
        final glyphY = col.y - (i * fontSize);
        if (glyphY < -fontSize || glyphY > size.height) continue;

        // head glyph is bright white-green, tail fades out
        final fade = 1.0 - (i / col.length);
        final isHead = i == 0;
        final opacity = isHead ? 1.0 : (fade * 0.85).clamp(0.0, 1.0);
        final glyphColor = isHead
            ? Colors.white.withOpacity(0.95)
            : color.withOpacity(opacity);

        final tp = TextPainter(
          text: TextSpan(
            text: col.glyphs[i],
            style: TextStyle(
              color: glyphColor,
              fontSize: fontSize,
              fontWeight: isHead ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        tp.paint(canvas, Offset(x, glyphY));
      }

      // reset column once it's fully scrolled past
      if (col.y - (col.length * fontSize) > size.height) {
        col.y = -fontSize * (5 + (col.length));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MatrixPainter oldDelegate) => true;
}

//============================================================
// EXAMPLE: emblem glowing on top of the matrix rain, reacting to voice
//============================================================
class EmblemWithMatrixRain extends StatelessWidget {
  final String assetPath;
  final double size;
  final double? rainWidth;
  final double? rainHeight;
  final String? easterEggText;
  final String? wsUrl;
  final Color glowColor;

  const EmblemWithMatrixRain({
    super.key,
    required this.assetPath,
    this.size = 260,
    this.rainWidth,
    this.rainHeight,
    this.easterEggText,
    this.wsUrl,
    this.glowColor = Colors.white, // <-- ADD THIS
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: rainWidth ?? size * 1.6,
      height: rainHeight ?? size * 1.6,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: MatrixRain(easterEggText: easterEggText)),
          wsUrl != null
              ? WebSocketReactiveGlowEmblem(
                  assetPath: assetPath,
                  wsUrl: wsUrl!,
                  size: size,
                  glowColor: glowColor, // <-- ADD THIS
                )
              : AnimatedGlowEmblem(
                  assetPath: assetPath,
                  size: size,
                  glowColor: glowColor, // <-- ADD THIS
                ),
        ],
      ),
    );
  }
}
