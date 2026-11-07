import 'package:flutter/material.dart';

/// Szűrő- és rendezősor felirata: egy sorban marad, a hosszú szöveg három pontot kap.
Text filterLabel(String value) =>
    Text(value, maxLines: 1, overflow: TextOverflow.ellipsis);
