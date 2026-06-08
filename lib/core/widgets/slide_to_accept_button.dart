import 'package:flutter/material.dart';

import '../theme/theme.dart';

class SlideToAcceptButton extends StatefulWidget {
  const SlideToAcceptButton({
    required this.onAccept, super.key,
    this.text = 'Slide untuk Terima Order',
  });

  final VoidCallback onAccept;
  final String text;

  @override
  State<SlideToAcceptButton> createState() => _SlideToAcceptButtonState();
}

class _SlideToAcceptButtonState extends State<SlideToAcceptButton> {
  double _dragValue = 0.0;
  bool _isAccepted = false;
  final double _thumbSize = 48.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxDragPosition = maxWidth - _thumbSize - 8; // 4 padding on each side

        return Container(
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFE5F1F6), // Light blue background exactly matching the design
            borderRadius: BorderRadius.circular(28),
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  widget.text,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Positioned(
                left: 4 + _dragValue,
                top: 4,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_isAccepted) return;
                    setState(() {
                      _dragValue += details.delta.dx;
                      if (_dragValue < 0) _dragValue = 0;
                      if (_dragValue > maxDragPosition) {
                        _dragValue = maxDragPosition;
                        _isAccepted = true;
                        widget.onAccept();
                      }
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (!_isAccepted) {
                      setState(() {
                        _dragValue = 0;
                      });
                    }
                  },
                  child: Container(
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: const BoxDecoration(
                      color: Color(0xFF006B4D), // Dark green color
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.keyboard_double_arrow_right,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
