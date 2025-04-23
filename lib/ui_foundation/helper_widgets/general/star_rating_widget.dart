import 'package:flutter/material.dart';

class StarRatingWidget extends StatefulWidget {
  final int initialRating;
  final ValueChanged<int> onRatingChanged;
  final double starSize;
  final Color filledColor;
  final Color unfilledColor;

  const StarRatingWidget({
    super.key,
    this.initialRating = 0,
    required this.onRatingChanged,
    this.starSize = 32.0,
    this.filledColor = Colors.amber,
    this.unfilledColor = Colors.grey,
  });

  @override
  _StarRatingWidgetState createState() => _StarRatingWidgetState();
}

class _StarRatingWidgetState extends State<StarRatingWidget> {
  late int _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  void _updateRating(int newRating) {
    setState(() {
      _rating = newRating;
    });
    widget.onRatingChanged(newRating);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        int starIndex = index + 1;
        return InkWell(
          onTap: () {
            _updateRating(starIndex);
          },
          child: Icon(
            starIndex <= _rating ? Icons.star : Icons.star_border,
            color: starIndex <= _rating ? widget.filledColor : widget.unfilledColor,
            size: widget.starSize,
          ),
        );
      }),
    );
  }
}
