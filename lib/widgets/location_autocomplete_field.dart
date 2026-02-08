import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// A text field that shows location suggestions from OpenStreetMap Nominatim
/// as the user types. Designed for neighborhood / postal code fields.
class LocationAutocompleteField extends StatefulWidget {
  const LocationAutocompleteField({
    super.key,
    required this.controller,
    this.labelText = 'Neighborhood or postal code',
    this.helperText,
    this.prefixIcon = const Icon(Icons.location_on_outlined),
    this.validator,
  });

  final TextEditingController controller;
  final String labelText;
  final String? helperText;
  final Widget? prefixIcon;
  final String? Function(String?)? validator;

  @override
  State<LocationAutocompleteField> createState() =>
      _LocationAutocompleteFieldState();
}

class _LocationAutocompleteFieldState extends State<LocationAutocompleteField> {
  List<_NominatimResult> _suggestions = [];
  bool _loading = false;
  Timer? _debounce;
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final _focusNode = FocusNode();
  bool _suppressSuggestions = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      // Delay removal so tap on suggestion has time to register
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_focusNode.hasFocus) {
          _removeOverlay();
        }
      });
    }
  }

  void _onChanged(String value) {
    _suppressSuggestions = false;
    _debounce?.cancel();
    if (value.trim().length < 2) {
      _removeOverlay();
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchNominatim(value.trim());
    });
  }

  Future<void> _searchNominatim(String query) async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'format': 'json',
        'limit': '5',
        'addressdetails': '1',
      });
      final response = await http.get(uri, headers: {
        'User-Agent': 'MicroHelp/1.0',
      });
      if (!mounted) return;
      if (response.statusCode == 200) {
        final results = jsonDecode(response.body) as List;
        final suggestions = results
            .map((r) => _NominatimResult(
                  displayName: r['display_name'] as String,
                  shortName: _buildShortName(r),
                ))
            .toList();
        setState(() => _suggestions = suggestions);
        if (suggestions.isNotEmpty && !_suppressSuggestions) {
          _showOverlay();
        } else {
          _removeOverlay();
        }
      }
    } catch (_) {
      // Silently ignore — user can still type manually
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _buildShortName(Map<String, dynamic> result) {
    final address = result['address'] as Map<String, dynamic>?;
    if (address == null) {
      final display = result['display_name'] as String;
      final parts = display.split(',');
      return parts.length > 2
          ? '${parts[0].trim()}, ${parts[1].trim()}'
          : display;
    }
    final parts = <String>[];
    // Prefer suburb/neighborhood, then city/town, then state
    final neighborhood = address['neighbourhood'] ??
        address['suburb'] ??
        address['quarter'];
    final city = address['city'] ??
        address['town'] ??
        address['village'] ??
        address['municipality'];
    final state = address['state'];
    final postcode = address['postcode'];

    if (neighborhood != null) parts.add(neighborhood as String);
    if (city != null) parts.add(city as String);
    if (state != null && parts.length < 2) parts.add(state as String);
    if (postcode != null && parts.isEmpty) parts.add(postcode as String);

    return parts.isNotEmpty ? parts.join(', ') : (result['display_name'] as String).split(',').first;
  }

  void _showOverlay() {
    _removeOverlay();
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: _getFieldWidth(),
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, _getFieldHeight() + 4),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return InkWell(
                    onTap: () {
                      widget.controller.text = suggestion.shortName;
                      widget.controller.selection = TextSelection.collapsed(
                        offset: suggestion.shortName.length,
                      );
                      _suppressSuggestions = true;
                      _removeOverlay();
                      setState(() => _suggestions = []);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            suggestion.shortName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          if (suggestion.displayName != suggestion.shortName)
                            Text(
                              suggestion.displayName,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  double _getFieldWidth() {
    final renderBox = context.findRenderObject() as RenderBox?;
    return renderBox?.size.width ?? 300;
  }

  double _getFieldHeight() {
    final renderBox = context.findRenderObject() as RenderBox?;
    return renderBox?.size.height ?? 56;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        onChanged: _onChanged,
        decoration: InputDecoration(
          labelText: widget.labelText,
          border: const OutlineInputBorder(),
          prefixIcon: widget.prefixIcon,
          helperText: widget.helperText,
          suffixIcon: _loading
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : null,
        ),
        validator: widget.validator,
      ),
    );
  }
}

class _NominatimResult {
  final String displayName;
  final String shortName;

  _NominatimResult({required this.displayName, required this.shortName});
}
